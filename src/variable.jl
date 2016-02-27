
type VariableTarget <: AbstractTarget
    name::UTF8String
    dependencies::Vector{UTF8String}
    action::Function
    funhash::UInt64
    isstale::Bool
    timestamp::DateTime
    varhash::UInt64
    m::Module
end

cached(t::VariableTarget) = Dict{Symbol, Any}(:funhash => t.funhash, :isstale => t.isstale,
    :timestamp => t.timestamp, :varhash => t.varhash)
    
function updatecache!(f::JLD.JldFile, t::VariableTarget)
    if t.name in names(f)
        if read(f[t.name])[:funhash] != t.funhash ||
           read(f[t.name])[:varhash] != t.varhash || 
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
        # @show t.varhash
        # @show newhash
        t.timestamp = Dates.unix2datetime(time())
        t.varhash = newhash
    end
    t.isstale = false
    updatecache!(t)
end

function updatetimestamp!(t::VariableTarget, maxtime)
    t.timestamp = max(maxtime, t.timestamp)
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

timestamp(t::VariableTarget) = t.timestamp

function target(::Type{VariableTarget}, name::AbstractString, action::Function, dependencies::AbstractArray)
    t = resolve(name, nothing)
    fh = funhash(action)
    # @show action.code
    # @show string(action.code)
    vh = 0
    isstale = true
    datetime = DateTime()
    if t === nothing 
        # check the cache
        getjld() do f
            if name in names(f)
                x = read(f[utf8(name)])
                # @show x
                # @show fh
                if fh == x[:funhash]
                    datetime = x[:timestamp]
                    vh = x[:varhash] 
                    isstale = false
                    # println("$datetime")
                end
            end
        end      
    elseif fh != t.funhash || dependencies != t.dependencies
    else
        isstale = false
        datetime = t.timestamp
        vh = t.varhash
        # println("Redefining $name.")
        # @show dependencies
        # @show t
        # @show fh
        # t != nothing && @show t.funhash
    end
    register(VariableTarget(name, dependencies, action, fh, isstale, datetime, vh, current_module()))
end

variable(action::Function, name::AbstractString, dependencies=UTF8String[]) = 
    target(VariableTarget, name, action, dependencies)

