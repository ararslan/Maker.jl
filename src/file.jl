
type FileTarget <: AbstractTarget
    name::UTF8String
    dependencies::Vector{UTF8String}
    description::UTF8String
    action::Function
    timestamp::DateTime
    funhash::UInt64
    isstale::Bool
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

file(action::Function, name::AbstractString, dependencies=UTF8String[]) = 
    target(FileTarget, name, action, dependencies)
file(name::AbstractString, dependencies=UTF8String[]) = 
    target(FileTarget, name, () -> nothing, dependencies)
