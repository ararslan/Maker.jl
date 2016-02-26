
using Make
using Base.Test

## Scenarios to test
##  - basic
##  - run make(), mimic restart (kill TARGETS), run make()
##  - run make(), mimic restart (kill TARGETS), redefine "c", run make()
##  - run make(), mimic restart (kill TARGETS), redefine "e", run make()
##  - run make(), mimic fresh start (kill jld & TARGETS), redefine "c", run make()
##  - run make(), mimic fresh start (kill jld & TARGETS), redefine "e", run make()

Make.file("in1.csv")


module X
using Make
include("targets.jl")

println("1")
make("e.csv")
end # module

module X
using Make
empty!(Make.TARGETS)
include("targets.jl")

println("2")
make("e.csv")
end # module

# module X
# using Make
# empty!(Make.TARGETS)
# include("targets.jl")
# 
# Make.variable("c", ["a", "b"]) do
#     println("Calculating `c`.")
#     -a * b
# end
# 
# println("3")
# make("e")
# end # module
















