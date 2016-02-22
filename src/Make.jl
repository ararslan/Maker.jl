module Make

export make,
       file,
       task,
       variable

abstract AbstractTarget

const TARGETS = ObjectIdDict()
    
function moduletargets()
    m = current_module()
    if !haskey(TARGETS, m)
        TARGETS[m] = Dict{UTF8String,AbstractTarget}()
    end
    TARGETS[m]
end
    
for T in (:FileTarget, :PhonyTarget)
    @eval begin
        type $T <: AbstractTarget
            name::UTF8String
            dependencies::Array{UTF8String,1}
            action::Function
            funhash::UInt64
            isstale::Bool
        end
    end
end

type VariableTarget <: AbstractTarget
    name::UTF8String
    dependencies::Array{UTF8String,1}
    action::Function
    funhash::UInt64
    isstale::Bool
    timestamp::Float64
    varhash::UInt64
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
        hash(f.code)
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
    eval(current_module(), :($(symbol(t.name)) = $x))
    t.varhash = hash(x)
end


# Update the timestamp for a target.
# Not meant to be used externally.
updatetimestamp!(t::AbstractTarget, maxtime) = nothing    
function updatetimestamp!(t::VariableTarget, maxtime)
    t.timestamp = max(maxtime, t.timestamp)
end

"""
`make(name::AbstractString = "default")`

Update target `name` after updating its dependencies. 
"""
function make(t::AbstractTarget)
    maxtime = 0.0
    for d in dependencies(t)
        make(d)
        maxtime = max(maxtime, timestamp(d))
    end
    isstale(t) && execute(t)
    t.isstale = false
    updatetimestamp!(t, maxtime)
    nothing
end
make(s::AbstractString = "default") = make(resolve(s))

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
    if !isdefined(current_module(), symbol(t.name)) || t.isstale ||
       hash(eval(current_module(), symbol(t.name))) != t.varhash
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
register(t::AbstractTarget) = (moduletargets()[t.name] = t; nothing)


"""
`resolve(s::AbstractString)`

Return the target registered under name `s`.
"""
resolve(s::AbstractString, default) = get(moduletargets(), utf8(s), default)
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
    if t === nothing
        t = T(name, dependencies, action, fh, false)
        register(t)
    elseif fh != t.funhash 
        t = T(name, dependencies, action, fh, false)
        register(t)
    end
end
target{T<:AbstractTarget}(::Type{T}, name::AbstractString, action::Function, dependencies::AbstractString) =
    target(T, name, action, [dependencies])

function target(::Type{VariableTarget}, name::AbstractString, action::Function, dependencies::AbstractArray)
    t = resolve(name, nothing)
    fh = funhash(action)
    if t === nothing
        t = VariableTarget(name, dependencies, action, fh, true, 0.0, 0)
        register(t)
    elseif fh != t.funhash || dependencies != t.dependencies
        t = VariableTarget(name, dependencies, action, fh, true, 0.0, 0)
        register(t)
    end
end

for (f,T) in ((:file,:FileTarget),
              (:task,:PhonyTarget),
              (:variable,:VariableTarget))
    @eval begin
        $f(action::Function, name::AbstractString, dependencies=[]) = target($T, name, action, dependencies)
        $f(name::AbstractString, dependencies=[]) = target($T, name, ()->nothing, dependencies)
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

Targets are registered by Module. 

`file` targets use the name of the file as the name of the target.
File targets use timestamps to determine when targets need to be
updated. File paths are relative to the current working directory.

`task` targets are generic targets used to define actions and 
dependencies. These are equivalent to PHONY targets in Makefiles.
`task` targets do not have timestamps or other way to resolve 
dependencies. `task` targets always update. So, if a `file` target
depends on a `task` target, it will always update.

`variable` targets define an action, and the result of the action
will be assigned to a global variable (within the Module) named
by the argument `name`. A `variable` task keeps a timestamp based on
the largest timestamp of dependencies.

If the `action` or `dependencies` of a target are redefined, the
target will be marked as stale, and the action will be updated
at the next target check.  
"""
file

@doc (@doc file) task
@doc (@doc file) variable

end # module

