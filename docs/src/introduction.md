# Introduction

[![Maker](http://pkg.julialang.org/badges/Maker_0.4.svg)](http://pkg.julialang.org/?pkg=Maker&ver=0.4)

[![Build Status](https://travis-ci.org/tshort/Maker.jl.svg?branch=master)](https://travis-ci.org/tshort/Maker.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/otj9pnwsq32to211?svg=true)](https://ci.appveyor.com/project/tshort/maker-jl)
[![Coverage Status](https://coveralls.io/repos/tshort/Maker.jl/badge.svg?branch=master)](https://coveralls.io/r/tshort/Maker.jl?branch=master)

`Maker` is a [Julia](http://julialang.org/) package to set up tasks and 
dependencies in a similar fashion to
[make](https://en.wikipedia.org/wiki/Makefile) or
[Rake](http://docs.seattlerb.org/rake/). Like make, `Maker` evaluates file and
code dependencies to update processing. The focus here is on data analysis, not
build automation for code. Key features for data analysis include:

- *Detection of code changes*--If part of the code changes, downstream 
  dependencies are updated during processing.
- *Variable tasks*--Most make-like tools rely mainly on files for 
  dependency analysis. In `Maker`, Julia variables can also be used
  in this role. That allows more fine-grained control of code and dependencies. 
 
`Maker` was derived from [Jake.jl](https://github.com/nolta/Jake.jl) by Mike
Nolta. [Juke.jl](https://github.com/kshramt/Juke.jl) is another make-like tool
written in Julia. 

Most build tools like make use a Makefile or other build-instruction file. In
`Maker`, a separate build-script can be used, but the API here focuses on
use within Julia script files. The API in `Maker` is most similar to Ruby's
[Rake](http://docs.seattlerb.org/rake/).

## Example

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
