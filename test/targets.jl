
using Make
using Base.Test

Make.variable("a") do
    println("Generating `a`.")
    pi
end

Make.variable("b", "in1.csv") do
    println("Reading `b`.")
    readcsv("in1.csv", skipstart=1)
end

Make.file("in1.csv")
Make.file("in2.csv")

Make.file("c.csv", ["a", "b"]) do
    println("Calculating `c`.")
    writecsv("c.csv", a * b)
end

Make.variable("c", "c.csv") do
    println("Reading `c`.")
    readcsv("c.csv")
end

Make.variable("d", "in2.csv") do
    println("Reading `d`.")
    readcsv("in2.csv", skipstart=1)
end

Make.variable("e", ["c", "d"]) do
    println("Calculating `e`.")
    c .* d
end

Make.file("e.csv", "e") do
    println("Writing 'e.csv'.")
    writecsv("e.csv", e)
end

Make.task("test e") do 
    @test e ≈ 
[65.97344572538566 138.23007675795088 216.76989309769573
 301.59289474462014 392.6990816987241 490.0884539600077
 593.7610115284709 703.7167544041137 819.955682586936]
end