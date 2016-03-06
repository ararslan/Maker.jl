
using Maker
using Base.Test

## Scenarios to test
##  - basic
##  - run make(), mimic restart (kill TARGETS), run make()
##  - run make(), mimic restart (kill TARGETS), redefine "c", run make()
##  - run make(), mimic restart (kill TARGETS), redefine "e", run make()
##  - run make(), mimic fresh start (kill jld & TARGETS), redefine "c", run make()
##  - run make(), mimic fresh start (kill jld & TARGETS), redefine "e", run make()

Maker.rm("c.csv")
Maker.rm("e.csv")
Maker.rm(".maker-cache.jld")

println("=== Base ===")
module X
using Maker
using Base.Test
COUNT = 0
empty!(Maker.TARGETS)
include("targets.jl")
make("e.csv")
@test COUNT == 7
end # module

println("=== Steps ===")
Maker.rm("c.csv")
Maker.rm("e.csv")
module X
using Maker
using Base.Test
COUNT = 0
empty!(Maker.TARGETS)
include("targets.jl")
make("a")
@test COUNT == 1
make("b")
@test COUNT == 2
make("c.csv")
@test COUNT == 3
make("c")
@test COUNT == 4
make("d")
@test COUNT == 5
make("e")
@test COUNT == 6
make("e.csv")
@test COUNT == 7
end # module

println("=== Redo ===")
module X
using Maker
using Base.Test
COUNT = 0
empty!(Maker.TARGETS)
include("targets.jl")
make("e.csv", verbose = true)
@test COUNT == 6
end # module

println("=== Remove e.csv ===")
Maker.rm("e.csv")
module X
using Maker
using Base.Test
COUNT = 0
empty!(Maker.TARGETS)
include("targets.jl")
make("e.csv")
@test COUNT == 6
end # module

println("=== Redefine c.csv dependencies ===")
module X
using Maker
using Base.Test
COUNT = 0
empty!(Maker.TARGETS)
include("targets.jl")
# change the dependencies of one of the tasks
Maker.file("c.csv", ["a", "b", "a"]) do
    global COUNT += 1
    writecsv("c.csv", a * b)
end
make("e.csv")
@test COUNT == 7
end # module

println("=== Redefine c.csv ===")
module X
using Maker
using Base.Test
COUNT = 0
empty!(Maker.TARGETS)
include("targets.jl")
# change one of the tasks
Maker.file("c.csv", ["a", "b"]) do
    global COUNT += 1
    a = 1
    writecsv("c.csv", a * b)
end
make("e.csv")
@test COUNT == 7
end # module

println("=== Change var ===")
module X
using Maker
using Base.Test
COUNT = 0
empty!(Maker.TARGETS)
include("targets.jl")
make("e.csv")
@test COUNT == 7
c = 27
make("e.csv")
@test COUNT == 9
@test c != 27
end # module

println("=== Redefine var ===")
module X
using Maker
using Base.Test
COUNT = 0
empty!(Maker.TARGETS)
include("targets.jl")
make("e.csv")
@test COUNT == 6
include("targets.jl")
make("e.csv")
@test COUNT == 7
COUNT = 0
Maker.variable("c", "c.csv") do # redefine action
    global COUNT += 1
    -readcsv("c.csv")
end
make("e.csv")
@test COUNT == 3
COUNT = 0
Maker.variable("c", ["c.csv", "a"]) do # redefine dependencies
    global COUNT += 1
    -readcsv("c.csv")
end
make("e.csv")
@test COUNT == 3
COUNT = 0
Maker.variable("c", ["c.csv", "a"]) do # redefine to same (shouldn't rerun)
    global COUNT += 1
    -readcsv("c.csv")
end
make("e.csv")
@test COUNT == 1
end # module

Maker.rm("c.csv")
Maker.rm("e.csv")
