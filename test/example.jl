
using Make
using Base.Test
using DataFrames

Make.file("in1.csv")
Make.file("in2.csv")

Make.file("df.csv", ["in1.csv", "in2.csv"]) do 
    println("Reading input data.")
    df = readtable("in1.csv")
    df = vcat(df, readtable("in2.csv"))
    println("Writing 'df.csv'.")
    writetable("df.csv", df) 
end
 
Make.variable("df", "df.csv") do 
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
Make.file(process_df2, "df2.csv", "df")

Make.variable("df2", "df2.csv") do 
    println("Reading `df2`.")
    readtable("df2.csv")
end

# Make.task("default", ["df.csv", "df2.csv"])
Make.task("default", "df2.csv")

Make.task("vars", ["df", "df2"])

# Make.task("default", "outputs")

Make.task("clean") do 
    println("Deleting generated csv files.")
    Make.rm("df.csv")
    Make.rm("df2.csv")
end

make()

make()

Make.file("df2.csv", "df") do 
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

println("Done.")
