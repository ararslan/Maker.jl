
type VariableTarget <: AbstractTarget
    name::UTF8String
    dependencies::Vector{UTF8String}
    description::UTF8String
    action::Function
    funhash::UInt64
    isstale::Bool
    timestamp::DateTime
    varhash::UInt64
    m::Module
end

immutable CachedVariable <: AbstractCached
    funhash::UInt64
    timestamp::DateTime
    varhash::UInt64
end

cached(t::VariableTarget) = CachedVariable(t.funhash, t.timestamp, t.varhash)
    
function updatecache!(f::JLD.JldFile, t::VariableTarget)
    if t.name in names(f)
        if read(f[t.name]).funhash != t.funhash ||
           read(f[t.name]).varhash != t.varhash || 
           !isdefined(t.m, symbol(t.name))
            # t.isstale = true
        end
        delete!(f, t.name)
    end
    write(f, t.name, cached(t))
end

function execute(t::VariableTarget)
    x = t.action()
    eval(t.m, :($(symbol(t.name)) = $x))
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
    if !isdefined(t.m, symbol(t.name)) || t.isstale || 
       hash(eval(t.m, symbol(t.name))) != t.varhash
        return true 
    end
    ds = dependencies(t)
    length(ds) == 0 ? false : timestamp(t) < maximum([timestamp(d) for d in ds])
end

timestamp(t::VariableTarget) = t.timestamp

function variable(action::Function, name::AbstractString, dependencies::AbstractArray = UTF8String[])
    t = resolve(name, nothing)
    fh = funhash(action, dependencies)
    vh = 0
    isstale = true
    datetime = DateTime()
    if t === nothing 
        # check the cache
        getjld() do f
            if name in names(f)
                x = read(f[utf8(name)])
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
    register(VariableTarget(name, dependencies, "", action, fh, isstale, datetime, vh, current_module()))
end
variable(action::Function, name::AbstractString, dependencies::AbstractString) =
    variable(action, name, [utf8(dependencies)])
    
