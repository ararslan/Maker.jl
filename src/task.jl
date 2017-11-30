
"""
`Maker.GenericTarget`

The type created by `task()`. Fields expected to be accessed publicly
include:

- `name::String`
- `dependencies::Vector{String}`
- `description::String`
"""
mutable struct GenericTarget <: AbstractTarget
    name::String
    dependencies::Vector{String}
    description::String
    action::Function
    timestamp::DateTime
    funhash::UInt64
    isstale::Bool
end

function isstale(t::GenericTarget)
    if t.isstale
        return true
    end
    ds = dependencies(t)
    isempty(ds) ? true : timestamp(t) < maximum([timestamp(d) for d in ds])
end


"""
```julia
task(action::Function, name::AbstractString, dependencies=[])
task(name::AbstractString, dependencies=[])
```
Define and register a `task` target for Maker.jl.

- `action` is the function that operates when the target is
  executed.

- `name` refers to the name of the task.

- `dependencies` refers to the name (`AbstractString`) or names
  (`Vector{AbstractString}`) of targets that need to be satisfied
  for this target before running the `action`. These are also referred
  to as prerequisites.

Targets are registered globally.

`task` targets are generic targets used to define actions and dependencies. If a
task does not have dependencies, it always runs. If a task has dependencies,
the task will run if any of the dependencies has a timestamp newer than the
last run of the task. If a file target depends on a task target without
dependencies, it will always update.

If the `action` or `dependencies` of a target are redefined, the
target will be marked as stale, and the action will be updated
at the next target check.

See also `make`, `file`, and `variable`. `task` registers a `GenericTarget` type.
"""
task(action::Function, name::AbstractString, dependencies=String[]) =
    target(GenericTarget, name, action, dependencies)
task(name::AbstractString, dependencies=String[]) =
    target(GenericTarget, name, ()->nothing, dependencies)
