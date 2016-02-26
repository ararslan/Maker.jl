module Make

using JLD

export make,
       file,
       task,
       variable

abstract AbstractTarget

const TARGETS = Dict{UTF8String, AbstractTarget}()
const CACHEFILE = ".make-cache.jld"


for T in (:FileTarget, :PhonyTarget)
    @eval begin
        type $T <: AbstractTarget
            name::UTF8String
            dependencies::Vector{UTF8String}
            action::Function
            funhash::UInt64
            isstale::Bool
        end
    end
end

type VariableTarget <: AbstractTarget
    name::UTF8String
    dependencies::Vector{UTF8String}
    action::Function
    funhash::UInt64
    isstale::Bool
    timestamp::DateTime
    varhash::UInt64
    m::Module
end

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
cached(t::VariableTarget) = Dict{Symbol, Any}(:funhash => t.funhash, :isstale => t.isstale,
    :timestamp => t.timestamp, :varhash => t.varhash)

function updatecache!(f::JLD.JldFile, t::FileTarget)
    if t.name in names(f)
        if read(f[t.name])[:funhash] != t.funhash
            # t.isstale = true
        end
        delete!(f, t.name)
    end
    write(f, t.name, cached(t))
end

function updatecache!(f::JLD.JldFile, t::VariableTarget)
    if t.name in names(f)
        if read(f[t.name])[:funhash] != t.funhash ||
           read(f[t.name])[:varhash] != t.varhash || 
           !isdefined(t.m, symbol(t.name))
            # t.isstale = true
        end
        delete!(f, t.name)
    end
    write(f, t.name, cached(t))
end

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

settarget(name::AbstractString, t::AbstractTarget) = getjld() do f
    updatecache!(f, t)
    TARGETS[utf8(name)] = t
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
function execute(t::VariableTarget)
    x = t.action()
    eval(t.m, :($(symbol(t.name)) = $x))
    newhash = hash(x)
    if t.varhash != newhash
        # @show t.varhash
        # @show newhash
        t.timestamp = Dates.unix2datetime(time())
        t.varhash = newhash
    end
    t.isstale = false
    updatecache!(t)
end


# Update the timestamp for a target.
# Not meant to be used externally.
updatetimestamp!(t::AbstractTarget, maxtime) = nothing    
function updatetimestamp!(t::VariableTarget, maxtime)
    t.timestamp = max(maxtime, t.timestamp)
end

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
function isstale(t::FileTarget)
    if !isfile(t.name) || t.isstale  
        # println("$(t.name) is stale.")
        return true 
    end
    ds = dependencies(t)
    length(ds) == 0 ? false : timestamp(t) < maximum([timestamp(d) for d in ds])
end
function isstale(t::VariableTarget)
    if !isdefined(t.m, symbol(t.name)) || t.isstale || 
       hash(eval(t.m, symbol(t.name))) != t.varhash
        # println("$(t.name) is stale")
        return true 
    end
    ds = dependencies(t)
    length(ds) == 0 ? false : timestamp(t) < maximum([timestamp(d) for d in ds])
end
isstale(t::AbstractTarget) = true


"""
`register(t::AbstractTarget)`

Register target `t`. `make` only looks for registered targets.
"""
register(t::AbstractTarget) = settarget(t.name, t)


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
timestamp(t::FileTarget) = Dates.unix2datetime(mtime(t.name))
timestamp(t::VariableTarget) = t.timestamp
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

function target(::Type{VariableTarget}, name::AbstractString, action::Function, dependencies::AbstractArray)
    t = resolve(name, nothing)
    fh = funhash(action)
    # @show action.code
    # @show string(action.code)
    vh = 0
    isstale = true
    datetime = DateTime()
    if t === nothing 
        # check the cache
        getjld() do f
            if name in names(f)
                x = read(f[utf8(name)])
                # @show x
                # @show fh
                if fh == x[:funhash]
                    datetime = x[:timestamp]
                    vh = x[:varhash] 
                    isstale = false
                    # println("$datetime")
                end
            end
        end      
    elseif fh != t.funhash || dependencies != t.dependencies
    else
        isstale = false
        datetime = t.timestamp
        vh = t.varhash
        # println("Redefining $name.")
        # @show dependencies
        # @show t
        # @show fh
        # t != nothing && @show t.funhash
    end
    register(VariableTarget(name, dependencies, action, fh, isstale, datetime, vh, current_module()))
end

for (f,T) in ((:file,:FileTarget),
              (:task,:PhonyTarget),
              (:variable,:VariableTarget))
    @eval begin
        $f(action::Function, name::AbstractString, dependencies=UTF8String[]) = target($T, name, action, dependencies)
        $f(name::AbstractString, dependencies=UTF8String[]) = target($T, name, ()->nothing, dependencies)
    end
end

"""
```julia
file(action::Function, name::AbstractString, dependencies=[])
task(action::Function, name::AbstractString, dependencies=[])
variable(action::Function, name::AbstractString, dependencies=[])
```
Define and register targets for Make.jl.

- `action` is the function that operates when the target is
  executed. 

- `name` refers to the name of the target. 

- `dependencies` refers to names of targets that need to be satisfied
  for this target before running the `action`. These are also referred
  to as prerequisites.

Targets are registered globally.

`file` targets use the name of the file as the name of the target.
File targets use timestamps to determine when targets need to be
updated. File paths are relative to the current working directory.

`task` targets are generic targets used to define actions and 
dependencies. These are equivalent to PHONY targets in Makefiles.
`task` targets do not have timestamps or other way to resolve 
dependencies. `task` targets always update. So, if a `file` target
depends on a `task` target, it will always update.

`variable` targets define an action, and the result of the action will be
assigned to a global variable (within the Module where the  definition is
created) named by the argument `name`. A `variable` task keeps a timestamp based
on the largest timestamp of dependencies.

If the `action` or `dependencies` of a target are redefined, the
target will be marked as stale, and the action will be updated
at the next target check.  
"""
file

@doc (@doc file) task
@doc (@doc file) variable

end # module

