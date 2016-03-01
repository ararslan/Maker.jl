
using Make
using Base.Test

Make.variable("a") do
    global COUNT += 1
    pi
end

Make.variable("b", "in1.csv") do
    global COUNT += 1
    readcsv("in1.csv", skipstart=1)
end

Make.file("in1.csv")
Make.file("in2.csv")

Make.file("c.csv", ["a", "b"]) do
    global COUNT += 1
    writecsv("c.csv", a * b)
end

Make.variable("c", "c.csv") do
    global COUNT += 1
    readcsv("c.csv")
end

Make.variable("d", "in2.csv") do
    global COUNT += 1
    readcsv("in2.csv", skipstart=1)
end

Make.variable("e", ["c", "d"]) do
    global COUNT += 1
    c .* d
end

Make.file("e.csv", "e") do
    global COUNT += 1
    writecsv("e.csv", e)
end


# writecsv("x.csv", [2.])
# @show mtime("x.csv") 
# @show time()
