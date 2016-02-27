module Make

using JLD

export make,
       file,
       task,
       variable

include("abstracttarget.jl")
include("task.jl")
include("file.jl")
include("variable.jl")


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

