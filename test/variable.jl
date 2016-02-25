using Make
using Base.Test

x = [ 3.14159   6.28319   9.42478
      12.5664   15.708    18.8496
      21.9911   25.1327   28.2743 ]

writecsv("b.csv", x)      

Make.variable("a") do
    println("Generating `a`.")
    pi
end

Make.variable("b", "b.csv") do
    println("Reading `b`.")
    readcsv("b.csv")
end

Make.file("b.csv")

Make.variable("c", ["a", "b"]) do
    println("Calculating `c`.")
    a * b
end

make("c")

@test a ≈ pi
@test b ≈ x 
@test c ≈ pi * x 

# redefine `a`
Make.variable("a") do
    println("Regenerating `a`.")
    2pi
end

make("c")

@test a ≈ 2pi
@test b ≈ x 
@test c ≈ 2pi * x 

# redefine `a` again:

Make.variable("a") do
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

module X

Make.variable("x") do
    27
end

Make.variable("y", "x") do
    x - 2
end

function change_y()
    Make.variable("y", "x") do
        x + 3
    end
end

make("y")

end # module

@test X.x == 27
@test X.y == 25

X.change_y()

@test X.x == 27
@test X.y == 25

make("y")

@test X.x == 27
@test X.y == 30

rm("b.csv")

