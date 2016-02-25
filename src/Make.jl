module Make

export make,
       file,
       task,
       variable

abstract AbstractTarget

const TARGETS = Dict{UTF8String,AbstractTarget}()
    
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
    timestamp::Float64
    varhash::UInt64
    m::Module
end

# VariableTarget(name::AbstractString, dependencies=UTF8String[], action=()->nothing, 
#                funhash=0, isstale=true, timestamp=Inf, varhash=0) = 
#     VariableTarget(utf8(name), dependencies, action, funhash, isstale, timestamp, varhash)

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
execute(t::AbstractTarget) = t.action()
function execute(t::VariableTarget)
    x = t.action()
    eval(t.m, :($(symbol(t.name)) = $x))
    t.varhash = hash(x)
    # t.timestamp += 1   # increment by a bit to force upstream's to recalculate
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
    maxtime = 0.0
    hasrun = false
    for d in dependencies(t)
        hasrun |= make(d, level + 1, dryrun, verbose)
        maxtime = max(maxtime, timestamp(d))
    end
    updatetimestamp!(t, maxtime)
    if isstale(t) || hasrun
        if verbose || dryrun
            println(("*" ^ level) * " Execute \"$(t.name)\"")
        end
        if !dryrun
            execute(t)
            t.isstale = false
        end
        return true
    else
        return false
    end
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
register(t::AbstractTarget) = (TARGETS[t.name] = t; nothing)


"""
```julia
resolve(s::AbstractString)
```

Return the target registered under name `s`.
"""
resolve(s::AbstractString, default) = get(TARGETS, utf8(s), default)
function resolve(s::AbstractString = "default")
    t = resolve(s, nothing)
    t === nothing && error("no rule for target '$s'")
    t
end


"""
`timestamp(t::AbstractTarget)`

Return the floating-point timestamp for a target.
"""
timestamp(t::FileTarget) = mtime(t.name)
timestamp(t::VariableTarget) = t.timestamp
timestamp(t::AbstractTarget) = time()


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
    if t === nothing || fh != t.funhash || dependencies != t.dependencies
        # println("Redefining $name.")
        # @show dependencies
        # @show t
        # @show fh
        # t != nothing && @show t.funhash
        register(VariableTarget(name, dependencies, action, fh, true, 0.0, 0, current_module()))
    end
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

