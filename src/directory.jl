
"""
`Maker.DirectoryTarget`

The type created by `directory()`. Fields expected to be accessed publicly
include:

- `name::UTF8String`
- `dependencies::Vector{UTF8String}`
- `description::UTF8String`

"""
type DirectoryTarget <: AbstractTarget
    name::UTF8String
    dependencies::Vector{UTF8String}
    description::UTF8String
    action::Function
    timestamp::DateTime
    funhash::UInt64
    isstale::Bool
end

function isstale(t::DirectoryTarget)
    if !isdir(t.name) || t.isstale  
        return true 
    end
    ds = dependencies(t)
    length(ds) == 0 ? false : timestamp(t) < maximum([timestamp(d) for d in ds])
end

function execute(t::DirectoryTarget) 
    !isdir(t.name) && mkpath(t.name)
    t.isstale = false
    updatecache!(t)
end

timestamp(t::DirectoryTarget) = if isdir(t.name)
    Dates.unix2datetime(0)
else
    Dates.unix2datetime(time())  # this will trigger the target
end

"""
```julia
directory(name::AbstractString, dependencies=[])
```
Define and register targets for Maker.jl.

- `name` refers to the name of the task or target. 

- `dependencies` refers to the name (`AbstractString`) or names 
  (`Vector{AbstractString}`) of targets that need to be satisfied
  for this target. 

Targets are registered globally.

`directory` targets use the name of the path as the name of the target.
No action can be specified. The path `name` is created with `mkpath` if 
it doesn't exist. The path is relative to the current working directory.

`directory` targets only have a builtin action that creates the 
directory if it is missing. A timestamp is stored when the directory
is created, but the return from `timestamp("directorytask")` returns
the oldest time if the directory exists (it doesn't need to be recreated),
and it returns the current time if the directory doesn't exist (it needs
 to be created). 

See also `make`, `file`, and `task`. `directory` registers a 
`DirectoryTarget` type.
"""
directory(name::AbstractString, dependencies=UTF8String[]) = 
    target(DirectoryTarget, name, () -> nothing, dependencies)
    
