
type GenericTarget <: AbstractTarget
    name::UTF8String
    dependencies::Vector{UTF8String}
    description::UTF8String
    action::Function
    timestamp::DateTime
    funhash::UInt64
    isstale::Bool
end

task(action::Function, name::AbstractString, dependencies=UTF8String[]) = 
    target(GenericTarget, name, action, dependencies)
task(name::AbstractString, dependencies=UTF8String[]) = 
    target(GenericTarget, name, ()->nothing, dependencies)
