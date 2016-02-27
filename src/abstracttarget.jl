
abstract AbstractTarget

const TARGETS = Dict{UTF8String, AbstractTarget}()
const CACHEFILE = ".make-cache.jld"

function gettarget(name::AbstractString, default)
    get(TARGETS, utf8(name), default)
    # if !isfile(CACHEFILE)    
    #     return default
    # end
    # jldopen(CACHEFILE, "r") do f
    #     if name in names(f)
    #         return f[utf8(name)]
    #     else
    #         return default
    #     end
    # end
end

cached(t::AbstractTarget) = Dict{Symbol, Any}(:funhash => t.funhash, :isstale => t.isstale)

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

function updatecache!(f::JLD.JldFile, t::AbstractTarget)
    if t.name in names(f)
        delete!(f, t.name)
    end
    write(f, t.name, cached(t))
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
end


# Update the timestamp for a target.
# Not meant to be used externally.
updatetimestamp!(t::AbstractTarget, maxtime) = nothing    

"""
```julia
make(name::AbstractString = "default"; 
     dryrun::Bool = false, verbose::Bool = false)
```

Update target `name` after updating its dependencies. Returns a Bool 
indicating if any actions were run.

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

"""
`isstale(t::AbstractTarget)`

Return `true` if target `t` is stale and should be updated.
"""
isstale(t::AbstractTarget) = true


"""
`register(t::AbstractTarget)`

Register target `t`. `make` only looks for registered targets.
"""
register(t::AbstractTarget) = getjld() do f
    updatecache!(f, t)
    TARGETS[t.name] = t
end


"""
```julia
resolve(s::AbstractString)
```

Return the target registered under name `s`.
"""
resolve(s::AbstractString, default) = gettarget(s, default)
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
    fh = funhash(action)
    if t === nothing || fh != t.funhash 
        register(T(name, dependencies, action, fh, false))
    end
end
target{T<:AbstractTarget}(::Type{T}, name::AbstractString, action::Function, dependencies::AbstractString) =
    target(T, name, action, [dependencies])

for (f,T) in ((:file,:FileTarget),
              (:task,:PhonyTarget))
    @eval begin
        $f(action::Function, name::AbstractString, dependencies=UTF8String[]) = target($T, name, action, dependencies)
        $f(name::AbstractString, dependencies=UTF8String[]) = target($T, name, ()->nothing, dependencies)
    end
end