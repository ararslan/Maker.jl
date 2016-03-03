
type DirectoryTarget <: AbstractTarget
    name::UTF8String
    dependencies::Vector{UTF8String}
    action::Function
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

directory(name::AbstractString, dependencies=UTF8String[]) = 
    target(DirectoryTarget, name, () -> nothing, dependencies)
