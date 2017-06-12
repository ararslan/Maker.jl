
immutable CachedTarget <: AbstractCached
    funhash::UInt64
    timestamp::DateTime
end

immutable CacheInfo
    fileversion::VersionNumber
    juliaversion::VersionNumber
    hashsize::UInt
end

# Return the data to be cached for `t`.
# Not meant to be used externally.
cached(t::AbstractTarget) = CachedTarget(t.funhash, t.timestamp)

minorversion(v) = VersionNumber(v.major, v.minor, 0, (), ())

"""
```julia
fixcache()
```

Update the `.maker-cache.jld` file with the present version information
for the cache version number and the Julia version. This may be needed
if the file format changes or the Julia version upgrades. Note that this
may not solve all issues. 
"""
fixcache() = getjld() do f
    delete!(f, "CACHEINFO")
    write(f, "CACHEINFO", CacheInfo(CACHEVERSION, minorversion(VERSION), sizeof(Int)))
end

compatible(x::CacheInfo) = x.fileversion == CACHEVERSION &&
    x.juliaversion.major == VERSION.major &&
    x.juliaversion.minor == VERSION.minor &&
    x.hashsize == sizeof(Int)

# Run `fun(f)` on the CACHEFILE with `f` as the opened file.
# Not meant to be used externally.
function getjld(fun::Function)
    if !isfile(CACHEFILE)    
        f = jldopen(CACHEFILE, "w")
        write(f, "CACHEINFO", CacheInfo(CACHEVERSION, VERSION, sizeof(Int)))
    else
        f = jldopen(CACHEFILE, "r+")
        if !compatible(read(f, "CACHEINFO"))
            error("Cache version in .maker-cache differs from the active version")
        end
    end
    try
        fun(f)
    finally
        close(f)
    end
end

function fixh5name(name)
    if contains(name, "/")   
        return string("M", hash(name))
    else 
        return name
    end
end

# Store target `t` information in the cache file.
# Not meant to be used externally.
function updatecache!(f::JLD.JldFile, t::AbstractTarget)
    h5name = fixh5name(t.name)
    if h5name in names(f)
        delete!(f, h5name)
    end
    write(f, h5name, cached(t))
end
updatecache!(t::AbstractTarget) = getjld() do f
    updatecache!(f, t)
end

remove_linenodes(x) = x
remove_linenodes(x::Vector{Any}) = map(remove_linenodes, filter(a -> !isa(a, LineNumberNode), x))
remove_linenodes(e::Expr) = Expr(e.head, remove_linenodes(e.args))

# Find the hash of an anonymous or generic function. The global
# is to have the same hash if the function code is the same. This
# is different than the standard `hash(f::Function)`.
# Not meant to be used externally.
function funhash(f::Function)
    hash(string(code_lowered(f, ())))
end
funhash(f::Function, x) = hash(funhash(f), hash(convert(Vector{String}, x)))


"""
```julia
dependencies(t::AbstractTarget)
```

Return the dependencies of a target.
"""
dependencies(t::AbstractTarget) = [resolvedependency(d) for d in t.dependencies]

function has1arg{T<:AbstractTarget}(t::T) 
    !isempty(methods(t.action, (T,)))
end

function has1arg(f::Function) 
    !isempty(methods(f, (AbstractTarget,)))
end

"""
```julia
execute(t::AbstractTarget)
```

Run the action for target `t`.
"""
function execute(t::AbstractTarget) 
    has1arg(t) ? t.action(t) : t.action()
    t.timestamp = Dates.unix2datetime(time())
    t.isstale = false
    updatecache!(t)
end


"""
```julia
isstale(t::AbstractTarget)
```

Return `true` if target `t` is stale and should be updated.
"""
function isstale(t::AbstractTarget)
    if t.isstale
        return true 
    end
    ds = dependencies(t)
    isempty(ds) ? false : timestamp(t) < maximum([timestamp(d) for d in ds])
end


"""
```julia
register(t::AbstractTarget)
```

Register target `t`. `make` only looks for registered targets.
"""
function register(t::AbstractTarget)
    t.description = NEXTDOC[1]
    tasks!(t.name, t)
    NEXTDOC[1] = ""
end


"""
```julia
resolve(s::AbstractString)
```

Return the target registered under name `s`.
"""
resolve(s::AbstractString, default) = get(tasks(), String(s), default)
function resolve(s::AbstractString = "default")
    t = resolve(s, nothing)
    t === nothing && error("no rule for target '$s'")
    t
end


"""
```julia
timestamp(t::AbstractTarget)
```

Return the DateTime timestamp for a target.
"""
timestamp(t::AbstractTarget) = t.timestamp

originaltimestamp{T<:AbstractTarget}(::Type{T}, name::AbstractString) = DateTime()

"""
    target{T<:AbstractTarget}(::Type{T}, name::AbstractString, action::Function, dependencies::AbstractArray)

Define and register a target of type `T`.
"""
function target{T<:AbstractTarget}(::Type{T}, name::AbstractString, action::Function, dependencies::AbstractArray)
    dependencies = String[dependencies...]
    t = resolve(name, nothing)
    fh = funhash(action, dependencies)
    datetime = DateTime()
    if t === nothing 
        isstale = true
        # check the cache
        getjld() do f
            h5name = fixh5name(name)
            if h5name in names(f)
                x = read(f[h5name])
                if fh == x.funhash
                    datetime = x.timestamp
                    isstale = false
                end
            else
                datetime = originaltimestamp(T, name)
            end
        end      
    else
        isstale = fh != t.funhash  
    end      
    if t === nothing || fh != t.funhash || isstale
        register(T(name, dependencies, "", action, datetime, fh, isstale))
    end
end
target{T<:AbstractTarget}(::Type{T}, name::AbstractString, action::Function, dependencies::AbstractString) =
    target(T, name, action, [dependencies])


"""
```julia
make(name::AbstractString = "default"; 
     dryrun::Bool = false, verbose::Bool = false)
make(names::AbstractVector; 
     dryrun::Bool = false, verbose::Bool = false)
```

Check, and if needed, update target `name` after updating its dependencies. For
multiple targets specified in `names`, run `make` on each item sequentially.

If keyword argument `verbose` is set, the chain of targets and dependencies is
shown.

If keyword argument `dryrun` is set, the chain of targets and actions
is shown but not run.
"""
function make(t::AbstractTarget, level::Int, dryrun::Bool, verbose::Bool)
    if verbose
        println(("-" ^ level) * " \"$(t.name)\"")
    end
    for d in dependencies(t)
        make(d, level + 1, dryrun, verbose)
    end
    if isstale(t)
        if verbose || dryrun
            println(("*" ^ level) * " Execute \"$(t.name)\"")
        end
        if !dryrun
            execute(t)
        end
    end
    nothing
end
make(s::AbstractString = "default"; dryrun = false, verbose = false) = 
    make(resolve(s), 1, dryrun, verbose)
function make(x::AbstractVector; dryrun = false, verbose = false)
    if isempty(x)
        make(dryrun = dryrun, verbose = verbose)
    else
        map(s -> make(resolve(s), 1, dryrun, verbose), x)
    end
end
