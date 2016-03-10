using Maker

empty!(Maker.TARGETS)
Maker.rm(".maker-cache.jld")
    
include("example.jl")
include("file.jl")
include("variable.jl")
include("test-targets.jl")
include("utils.jl")
include("glob.jl")
include("function-dependency.jl")

rm(".maker-cache.jld")