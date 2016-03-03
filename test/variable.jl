using Maker
using Base.Test

x = [ 3.14159   6.28319   9.42478
      12.5664   15.708    18.8496
      21.9911   25.1327   28.2743 ]

writecsv("b.csv", x)      

Maker.variable("a") do
    println("Generating `a`.")
    pi
end

Maker.variable("b", "b.csv") do
    println("Reading `b`.")
    readcsv("b.csv")
end

Maker.file("b.csv")

Maker.variable("c", ["a", "b"]) do
    println("Calculating `c`.")
    a * b
end

make("a")
make("b")
make("c")

@test a ≈ pi
@test b ≈ x 
@test c ≈ pi * x 

# redefine `a`
Maker.variable("a") do
    println("Regenerating `a`.")
    2pi
end

make("c", verbose = true)

@test a ≈ 2pi
@test b ≈ x 
@test c ≈ 2pi * x 

# redefine `a` again:

Maker.variable("a") do
    println("Generating `a`.")
    pi
end

make("a", verbose=true)

@test a ≈ pi
@test c ≈ 2pi * x 

make("c", verbose=true)

@test a ≈ pi
@test c ≈ pi * x 

# change `a`

a = -pi

make("c")

@test a ≈ pi
@test c ≈ pi * x 


rm("b.csv")

