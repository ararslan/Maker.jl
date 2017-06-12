
"""
`Maker.PhonyTarget`

The type created by `phony()`. Fields expected to be accessed publicly
include:

- `name::String`
- `dependencies::Vector{String}`
- `description::String`
"""
type PhonyTarget <: AbstractTarget
    name::String
    dependencies::Vector{String}
    description::String
    action::Function
    timestamp::DateTime
    funhash::UInt64
    isstale::Bool
end

timestamp(t::PhonyTarget) = DateTime()

function isstale(t::PhonyTarget)
    if t.isstale
        return true 
    end
    ds = dependencies(t)
    isempty(ds) ? true : t.timestamp < maximum([timestamp(d) for d in ds])
end


"""
```julia
phony(action::Function, name::AbstractString, dependencies=[])
phony(name::AbstractString, dependencies=[]) 
```
Define and register a `phony` target for Maker.jl.

- `action` is the function that operates when the target is
  executed. 

- `name` refers to the name of the task. 

- `dependencies` refers to the name (`AbstractString`) or names 
  (`Vector{AbstractString}`) of targets that need to be satisfied
  for this target before running the `action`. These are also referred
  to as prerequisites.

Targets are registered globally.

`phony` targets are generic targets that follow the same rules as a `task`, but
`phony` always has an "ancient" timestamp meaning it won't trigger upstream
changes. It does store a timestamp to  determine whether to execute its own 
action based on changes to dependencies.

If the `action` or `dependencies` of a target are redefined, the target will be
marked as stale, and the action will be updated at the next target check.  

See also `make`, `file`, `task`, and `variable`. `phony` registers a 
`PhonyTarget` type.
"""
phony(action::Function, name::AbstractString, dependencies=String[]) = 
    target(PhonyTarget, name, action, dependencies)
phony(name::AbstractString, dependencies=String[]) = 
    target(PhonyTarget, name, ()->nothing, dependencies)