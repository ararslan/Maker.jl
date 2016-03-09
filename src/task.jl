
type GenericTarget <: AbstractTarget
    name::UTF8String
    dependencies::Vector{UTF8String}
    description::UTF8String
    action::Function
    timestamp::DateTime
    funhash::UInt64
    isstale::Bool
end

function isstale(t::GenericTarget)
    if t.isstale
        return true 
    end
    ds = dependencies(t)
    isempty(ds) ? true : timestamp(t) < maximum([timestamp(d) for d in ds])
end

task(action::Function, name::AbstractString, dependencies=UTF8String[]) = 
    target(GenericTarget, name, action, dependencies)
task(name::AbstractString, dependencies=UTF8String[]) = 
    target(GenericTarget, name, ()->nothing, dependencies)
