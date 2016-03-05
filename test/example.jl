
using Maker
using Base.Test
using DataFrames

@desc "Input file 1"
Maker.file("in1.csv")

@desc "Input file 1"
Maker.file("in2.csv")

@desc "Combine input files"
Maker.file("df.csv", ["in1.csv", "in2.csv"]) do 
    println("Reading input data.")
    df = readtable("in1.csv")
    df = vcat(df, readtable("in2.csv"))
    println("Writing 'df.csv'.")
    writetable("df.csv", df) 
end
 
@desc "Load variable `df`"
Maker.variable("df", "df.csv") do 
    println("Reading `df`.")
    readtable("df.csv")
end

function process_df2()
    # global df = readtable("df.csv") 
    println("Processing `df`.")
    df2 = copy(df)
    df2[:d] = 2 .* df[:a] + maximum(df[:b])
    df2[:e] = rand(nrow(df))
    println("Writing 'df2.csv'.")
    writetable("df2.csv", df2)
end

@desc "Make df2 using second input file"
Maker.file(process_df2, "df2.csv", "df")

@desc "Read `df2`"
Maker.variable("df2", "df2.csv") do 
    println("Reading `df2`.")
    readtable("df2.csv")
end

# Maker.task("default", ["df.csv", "df2.csv"])
Maker.task("default", "df2.csv")

@desc "Load all variables"
Maker.task("vars", ["df", "df2"])

# Maker.task("default", "outputs")

@desc "Delete generated csv files"
Maker.task("clean") do 
    println("Deleting generated csv files.")
    Maker.rm("df.csv")
    Maker.rm("df2.csv")
end

make()

make()

@desc "Make df2 using second input file"
Maker.file("df2.csv", "df") do 
    println("Processing `df` after redefining the df2.csv task.")
    df2 = copy(df)
    df2[:d] = 2 .* df[:a] + maximum(df[:b])
    df2[:e] = rand(nrow(df))
    println("Writing 'df2.csv'.")
    writetable("df2.csv", df2)
end

make()

println("== Touch'ing in1.csv...")

run(`touch in1.csv`)

make()

println("== Changing df...")

df[1,:a] = 3

make()  # This should change `df` back to what it was.

make("clean")

@test length(tasks()) == 9 
@test tasks("clean").name == "clean"
@show tasks()

println("Done.")
