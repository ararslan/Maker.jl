
using Maker
using Base.Test

writecsv("in1.csv", rand(3,3))
writecsv("in2.csv", rand(3,3))

@desc "Combine input files"
Maker.file("x.csv", ["in1.csv", "in2.csv"]) do 
    println("Reading input data.")
    x = readcsv("in1.csv") + readcsv("in2.csv")
    println("Writing 'x.csv'.")
    writecsv("x.csv", x) 
end
 
@desc "Load variable `x`"
Maker.variable("x", "x.csv") do 
    println("Reading `x`.")
    readcsv("x.csv")
end

function process_x2()
    println("Processing `x`.")
    x2 = copy(x)
    x2 = pi .* x
    println("Writing 'x2.csv'.")
    writecsv("x2.csv", x2)
end

@desc "Make x2 using second input file"
Maker.file(process_x2, "x2.csv", "x")

show(tasks("x2.csv"))

@desc "Read `x2`"
Maker.variable("x2", "x2.csv") do 
    println("Reading `x2`.")
    readcsv("x2.csv")
end

Maker.task("default", "x2.csv")

@desc "Load all variables"
Maker.task("vars", ["x", "x2"])


@desc "Delete generated csv files"
Maker.task("clean") do 
    println("Deleting generated csv files.")
    Maker.rm("in1.csv")
    Maker.rm("in2.csv")
    Maker.rm("x.csv")
    Maker.rm("x2.csv")
end

make()

make()

@desc "Make x2 using second input file"
Maker.file("x2.csv", "x") do 
    println("Processing `x` after redefining the x2.csv task.")
    x2 = copy(x)
    x2 = pi .* x
    println("Writing 'x2.csv'.")
    writecsv("x2.csv", x2)
end

make()

println("== Touch'ing in1.csv...")

run(`touch in1.csv`)

make()

println("== Changing x...")

tmp = x[1,1]
x[1,1] = 3

make()  # This should change `x` back to what it was.

@test tmp == x[1,1]

make("clean")

@test length(tasks()) == 7
@test tasks("clean").name == "clean"
show(tasks())
show(tasks("x.csv"))

println("Done.")
