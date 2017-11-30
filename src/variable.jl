
"""
`Maker.VariableTarget`

The type created by `variable()`. Fields expected to be accessed publicly
include:

- `name::String`
- `dependencies::Vector{String}`
- `description::String`
"""
mutable struct VariableTarget <: AbstractTarget
    name::String
    dependencies::Vector{String}
    description::String
    action::Function
    funhash::UInt64
    isstale::Bool
    timestamp::DateTime
    varhash::UInt64
    m::Module
end

struct CachedVariable <: AbstractCached
    funhash::UInt64
    timestamp::DateTime
    varhash::UInt64
end

cached(t::VariableTarget) = CachedVariable(t.funhash, t.timestamp, t.varhash)

function updatecache!(f::JLD2.JLDFile, t::VariableTarget)
    if t.name in keys(f)
        delete!(f, t.name)
    end
    write(f, t.name, cached(t))
end

function execute(t::VariableTarget)
    x = has1arg(t) ? t.action(t) : t.action()
    eval(t.m, :($(Symbol(t.name)) = $x))
    newhash = hash(x)
    if t.varhash != newhash
        t.timestamp = Dates.unix2datetime(time())
        t.varhash = newhash
    else
        ds = dependencies(t)
        if length(ds) > 0
            t.timestamp = max(t.timestamp, maximum([timestamp(d) for d in ds]))
        end
    end
    t.isstale = false
    updatecache!(t)
end

function isstale(t::VariableTarget)
    if !isdefined(t.m, Symbol(t.name)) || t.isstale ||
       hash(eval(t.m, Symbol(t.name))) != t.varhash
        return true
    end
    ds = dependencies(t)
    isempty(ds) ? true : timestamp(t) < maximum([timestamp(d) for d in ds])
end

timestamp(t::VariableTarget) = t.timestamp

"""
```julia
variable(action::Function, name::AbstractString, dependencies)
```
Define and register targets for Maker.jl.

- `action` is the function that operates when the target is
  executed.

- `name` refers to the name of the task or target.

- `dependencies` refers to the name (`AbstractString`) or names
  (`Vector{AbstractString}`) of targets that need to be satisfied
  for this target before running the `action`. These are also referred
  to as prerequisites.

Targets are registered globally.

`variable` targets define an action, and the result of the action will be
assigned to a global variable (within the Module where the  definition is
created) named by the argument `name`. A `variable` task keeps a timestamp
when the action runs. If the result of the action has the same hash as
the cached version of the hash, the cached timestamp is used. Using the
stored timestamp can reduce the number of unnecessary actions run.

If the `action` or `dependencies` of a target are redefined, the target will be
marked as stale, and the action will be updated at the next target check.

See also `make`, `file`, and `task`. `variable` registers a `VariableTarget` type.
"""
function variable(action::Function, name::AbstractString,
                  dependencies::AbstractArray = String[])
    dependencies = String[dependencies...]
    t = resolve(name, nothing)
    fh = funhash(action, dependencies)
    vh = 0
    isstale = true
    datetime = DateTime()
    if t === nothing
        # check the cache
        getjld() do f
            if name in keys(f)
                x = read(f[name])
                if fh == x.funhash
                    datetime = x.timestamp
                    vh = x.varhash
                    isstale = false
                end
            end
        end
    elseif fh != t.funhash || dependencies != t.dependencies
    else
        isstale = false
        datetime = t.timestamp
        vh = t.varhash
    end
    register(VariableTarget(name, dependencies, "", action, fh, isstale,
                            datetime, vh, current_module()))
end
variable(action::Function, name::AbstractString, dependencies::AbstractString) =
    variable(action, name, [dependencies])

