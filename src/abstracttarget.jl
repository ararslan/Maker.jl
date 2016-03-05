
immutable CachedTarget <: AbstractCached
    funhash::UInt64
end

# Return the data to be cached for `t`.
# Not meant to be used externally.
cached(t::AbstractTarget) = CachedTarget(t.funhash)

# Run `fun(f)` on the CACHEFILE with `f` as the opened file.
# Not meant to be used externally.
function getjld(fun::Function)
    if !isfile(CACHEFILE)    
        f = jldopen(CACHEFILE, "w")
    else
        f = jldopen(CACHEFILE, "r+")
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


# Find the hash of an anonymous or generic function. The global
# is to have the same hash if the function code is the same. This
# is different than the standard `hash(f::Function)`.
# Not meant to be used externally.
function funhash(f::Function)
    if isdefined(f, :code) # handles anonymous functions
        hash(string(f.code))
    else
        hash(code_lowered(f, ())) # handles generic functions
    end
end
funhash(f::Function, x) = hash(funhash(f), hash(convert(Vector{UTF8String}, x)))


"""
`dependencies(t::AbstractTarget)`

Return the dependencies of a target.
"""
dependencies(t::AbstractTarget) = [resolve(d) for d in t.dependencies]

"""
`execute(t::AbstractTarget)`

Run the action for target `t`.
"""
function execute(t::AbstractTarget) 
    t.action()
    t.isstale = false
    updatecache!(t)
end


"""
`isstale(t::AbstractTarget)`

Return `true` if target `t` is stale and should be updated.
"""
isstale(t::AbstractTarget) = true


"""
`register(t::AbstractTarget)`

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
resolve(s::AbstractString, default) = get(tasks(), utf8(s), default)
function resolve(s::AbstractString = "default")
    t = resolve(s, nothing)
    t === nothing && error("no rule for target '$s'")
    t
end


"""
`timestamp(t::AbstractTarget)`

Return the DateTime timestamp for a target.
"""
timestamp(t::AbstractTarget) = Dates.unix2datetime(time())


"""
`target{T<:AbstractTarget}(::Type{T}, name::AbstractString, action::Function, dependencies::AbstractArray)`

Define and register a target of type `T`.
"""
function target{T<:AbstractTarget}(::Type{T}, name::AbstractString, action::Function, dependencies::AbstractArray)
    t = resolve(name, nothing)
    fh = funhash(action, dependencies)
    if t === nothing 
        isstale = true
        # check the cache
        getjld() do f
            h5name = fixh5name(name)
            if h5name in names(f)
                x = read(f[h5name])
                if fh == x.funhash
                    isstale = false
                end
            end
        end      
    else
        isstale = fh != t.funhash  
    end      
    if t === nothing || fh != t.funhash || isstale
        register(T(name, dependencies, "", action, fh, isstale))
    end
end
target{T<:AbstractTarget}(::Type{T}, name::AbstractString, action::Function, dependencies::AbstractString) =
    target(T, name, action, [dependencies])


"""
```julia
make(name::AbstractString = "default"; 
     dryrun::Bool = false, verbose::Bool = false)
```

Update target `name` after updating its dependencies. 

If keyword argument `verbose` is set, the chain of targets and dependencies
is shown.

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

