
# Example

The following shows a brief example of how to define file and variable 
dependencies for data processing.

```julia
Maker.file("in1.csv")    # These are the input files.
Maker.file("in2.csv")

# Two input files are processed to produce the file x.csv.
# "x.csv" is the name of the file task and the name of the file
# associated with the task. "in1.csv" and "in2.csv" are the 
# dependencies for "x.csv". If either of the inputs are 
# changed (newer timestamp), this task will run.
Maker.file("x.csv", ["in1.csv", "in2.csv"]) do 
    x = readcsv("in1.csv") + readcsv("in2.csv")
    println("Writing 'x.csv'.")
    writecsv("x.csv", x) 
end

# This is a variable task. It creates a global variable
# `x` based on the result of this calculation. 
Maker.variable("x", "x.csv") do 
    println("Reading `x`.")
    readcsv("x.csv")
end

# This simple task defines which target to check
# when `make()` is run.
Maker.task("default", "x.csv")

make()  # Run the "default" task.
```

See [here](https://github.com/tshort/Maker.jl/blob/master/test/example.jl) for a
longer version of this example. In the example above, do-syntax is used. These
use anonymous functions to define actions. Normal, generic functions can also be 
used.
