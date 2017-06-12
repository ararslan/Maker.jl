
using Maker
using Base.Test

Maker.phony("phony") 

Maker.variable("a", "phony") do   # phony limits this to one run
    global COUNT += 1
    println("phony")
    pi
end

Maker.variable("b", "in1.csv") do
    global COUNT += 1
    println("b in1.csv")
    readcsv("in1.csv", skipstart=1)
end

Maker.file("in1.csv")
Maker.file("in2.csv")

Maker.file("c.csv", ["a", "b"]) do
    global COUNT += 1
    println("c.csv a b")
    writecsv("c.csv", a * b)
end

Maker.variable("c", "c.csv") do
    global COUNT += 1
    println("c c.csv")
    readcsv("c.csv")
end

Maker.variable("d", "in2.csv") do
    global COUNT += 1
    println("k in2.csv")
    readcsv("in2.csv", skipstart=1)
end

Maker.variable("e", ["c", "d"]) do
    global COUNT += 1
    println("e c d")
    c .* d
end

Maker.file("e.csv", "e") do
    global COUNT += 1
    println("e.csv e")
    writecsv("e.csv", e)
end

