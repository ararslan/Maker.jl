
type PhonyTarget <: AbstractTarget
    name::UTF8String
    dependencies::Vector{UTF8String}
    action::Function
    funhash::UInt64
    isstale::Bool
end

task(action::Function, name::AbstractString, dependencies=UTF8String[]) = 
    target(PhonyTarget, name, action, dependencies)
task(name::AbstractString, dependencies=UTF8String[]) = 
    target(PhonyTarget, name, ()->nothing, dependencies)