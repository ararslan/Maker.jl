using Maker
using Compat
using Compat.Test

empty!(Maker.TARGETS)
Maker.rm(".maker-cache.jld2")

include("example.jl")
include("file.jl")
include("variable.jl")
include("test-targets.jl")
include("utils.jl")
include("glob.jl")
include("function-dependency.jl")

rm(".maker-cache.jld2")
