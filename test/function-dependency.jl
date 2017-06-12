# This is an example of how to include a dependency on code 
# outside of an action.

using Maker
using Base.Test

x = [ 3.14159   6.28319   9.42478
      12.5664   15.708    18.8496
      21.9911   25.1327   28.2743 ]
writecsv("in1.csv", x)      

COUNT = 0

f() = readcsv("in1.csv")

Maker.file("in1.csv")

Maker.variable("x", ["in1.csv", "ffun"]) do
    global COUNT += 1
    f() 
end

Maker.variable("ffun") do t
    Maker.funhash(f) 
end

Maker.variable("y", "x") do
    global COUNT += 1
    3x
end

dump(Maker.TARGETS["ffun"])
make("y", verbose = true)
dump(Maker.TARGETS["ffun"])
# @test COUNT == 2
make("y", verbose = true)
dump(Maker.TARGETS["ffun"])
# @test COUNT == 2
# redefine f
f() = 2*readcsv("in1.csv")
make("y", verbose = true)
# @test COUNT == 4


# rm("in1.csv")      
