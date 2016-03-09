module Maker

using JLD

export directory,
       file,
       make,
       task,
       tasks,
       variable,
       @desc

const CACHEFILE = ".maker-cache.jld"
const CACHEVERSION = v"0.1"

abstract AbstractTarget

abstract AbstractCached

include("targets.jl")
include("abstracttarget.jl")
include("task.jl")
include("directory.jl")
include("file.jl")
include("variable.jl")
include("utils.jl")


"""
```julia
directory(name::AbstractString, dependencies=[])
file(action::Function, name::AbstractString, dependencies=[])
task(action::Function, name::AbstractString, dependencies=[])
variable(action::Function, name::AbstractString, dependencies=[])
```
Define and register targets for Maker.jl.

- `action` is the function that operates when the target is
  executed. 

- `name` refers to the name of the task or target. 

- `dependencies` refers to names of targets that need to be satisfied
  for this target before running the `action`. These are also referred
  to as prerequisites.

Targets are registered globally.

`file` targets use the name of the file as the name of the target.
File targets use timestamps to determine when targets need to be
updated. File paths are relative to the current working directory.

`directory` targets use the name of the path as the name of the target.
No action can be specified. The path `name` is created with `mkpath` if 
it doesn't exist. The path is relative to the current working directory.

`task` targets are generic targets used to define actions and dependencies. If a
task does not have dependencies, it always runs. If a task has dependencies,
the task will run if any of the dependencies has a timestamp newer than the
last run of the task. If a file target depends on a task target without
dependencies, it will always update.

`variable` targets define an action, and the result of the action will be
assigned to a global variable (within the Module where the  definition is
created) named by the argument `name`. A `variable` task keeps a timestamp based
on the largest timestamp of dependencies.

If the `action` or `dependencies` of a target are redefined, the
target will be marked as stale, and the action will be updated
at the next target check.  
"""
file, directory, task, variable

end # module

