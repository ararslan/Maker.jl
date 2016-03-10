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

function genx(t) 
    global COUNT += 1
    f() 
end
Maker.variable(genx, "x", ["in1.csv", "ffun"])


Maker.variable("ffun") do t
    Maker.funhash(f) 
end

Maker.variable("y", "x") do
    global COUNT += 1
    3x
end

make("y")
@test COUNT == 2
make("y")
@test COUNT == 2
# redefine f
f() = 3*readcsv("in1.csv")
make("y")
@test COUNT == 4

# redefine genx to test funhash on generics
function genx(t) 
    global COUNT += 1
    -f() 
end
Maker.variable(genx, "x", ["in1.csv", "ffun"])


make("y")
@test COUNT == 6


rm("in1.csv")      
