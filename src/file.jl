
type FileTarget <: AbstractTarget
    name::UTF8String
    dependencies::Vector{UTF8String}
    action::Function
    funhash::UInt64
    isstale::Bool
end

function updatecache!(f::JLD.JldFile, t::FileTarget)
    if t.name in names(f)
        if read(f[t.name])[:funhash] != t.funhash
            # t.isstale = true
        end
        delete!(f, t.name)
    end
    write(f, t.name, cached(t))
end

function isstale(t::FileTarget)
    if !isfile(t.name) || t.isstale  
        # println("$(t.name) is stale.")
        return true 
    end
    ds = dependencies(t)
    length(ds) == 0 ? false : timestamp(t) < maximum([timestamp(d) for d in ds])
end

timestamp(t::FileTarget) = Dates.unix2datetime(mtime(t.name))

file(action::Function, name::AbstractString, dependencies=UTF8String[]) = 
    target(FileTarget, name, action, dependencies)
file(name::AbstractString, dependencies=UTF8String[]) = 
    target(FileTarget, name, ()->nothing, dependencies)