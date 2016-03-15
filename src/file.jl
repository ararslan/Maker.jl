
"""
`Maker.FileTarget`

The type created by `file()`. Fields expected to be accessed publicly
include:

- `name::UTF8String`
- `dependencies::Vector{UTF8String}`
- `description::UTF8String`

"""
type FileTarget <: AbstractTarget
    name::UTF8String
    dependencies::Vector{UTF8String}
    description::UTF8String
    action::Function
    timestamp::DateTime
    funhash::UInt64
    isstale::Bool
end

"""
```julia
resolvedependency(s::AbstractString)
```

Return the target registered under name `s`. If no target is registered and a
file of name `s` exists, return a new `FileTarget` for that file.
"""
function resolvedependency(s::AbstractString)
    if haskey(tasks(), utf8(s))
        tasks()[utf8(s)]
    elseif isfile(s)
        FileTarget(s, UTF8String[], "", () -> nothing,
                   Dates.unix2datetime(mtime(s)), 0, false)
    else
        error("no rule for target '$s'")
    end
end

function isstale(t::FileTarget)
    if !isfile(t.name) || t.isstale  
        return true 
    end
    ds = dependencies(t)
    # length(ds) > 0 && @show maximum([timestamp(d) for d in ds])
    # length(ds) > 0 && @show timestamp(t)
    # length(ds) > 0 && @show timestamp(t) < maximum([timestamp(d) for d in ds])
    isempty(ds) ? false : timestamp(t) < maximum([timestamp(d) for d in ds])
end

timestamp(t::FileTarget) = max(t.timestamp, Dates.unix2datetime(mtime(t.name)))

originaltimestamp(::Type{FileTarget}, name::AbstractString) = 
    isfile(name) ? Dates.unix2datetime(mtime(name)) : DateTime()

"""
```julia
file(action::Function, name::AbstractString, dependencies=[])
file(name::AbstractString, dependencies=[])
```
Define and register a `file` target for Maker.jl.

- `action` is the function that operates when the target is
  executed. 

- `name` refers to the name of the task or target. 

- `dependencies` refers to the name (`AbstractString`) or names 
  (`Vector{AbstractString}`) of targets that need to be satisfied
  for this target. 

Targets are registered globally.

`file` targets use the name of the file as the name of the target.
File targets use timestamps to determine when targets need to be
updated. File paths are relative to the current working directory.

If the `action` or `dependencies` of a target are redefined, the
target will be marked as stale, and the action will be updated
at the next target check.  

See also `make`, `directory`,, `task`, and `variable`. `file` 
registers a `FileTarget` type.
"""
file(action::Function, name::AbstractString, dependencies=UTF8String[]) = 
    target(FileTarget, name, action, dependencies)
file(name::AbstractString, dependencies=UTF8String[]) = 
    target(FileTarget, name, () -> nothing, dependencies)
