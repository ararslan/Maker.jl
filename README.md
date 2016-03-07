# Maker
#### A tool like make for data analysis in Julia

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

# Two input files are processed to produce the file df.csv.
# "df.csv" is the name of the file task and the name of the file
# associated with the task. "in1.csv" and "in2.csv" are the 
# dependencies for "df.csv". If either of the inputs are 
# changed (newer timestamp), this task will run.
Maker.file("df.csv", ["in1.csv", "in2.csv"]) do 
    df = readtable("in1.csv")
    df = vcat(df, readtable("in2.csv"))
    writetable("df.csv", df) 
end

# This is a variable task. It creates a global variable
# `df` based on the result of this calculation. 
Maker.variable("df", "df.csv") do 
    println("Reading `df`.")
    readtable("df.csv")
end

# This simple task defines which dependencies to check
# when `make()` is run.
Maker.task("default", "df.csv")

make()  # Run the "default" task.
```

See [here](https://github.com/tshort/Maker.jl/blob/master/test/example.jl) for a
longer version of this example. In the example above, do-syntax is used. These
use anonymous functions to define actions. Normal, generic functions can also be 
used.

## API 

The main API here is rather basic:

* `make(task="default")` -- Process the target `task` by evaluating dependencies
  that need to be updated. "default" is the name of the default task.

* `Maker.directory`, `Maker.file`, `Maker.task`, and `Maker.variable` -- These
  methods all define tasks or targets to be updated. Each task has a name, zero
  or more dependencies, and an action as follows:
    
```julia 
Maker.task(action::Function, name::AbstractString, dependencies::Vector{AbstractString})
```
Normally with the `file` task, the `action` will perform an operation to create
or update the file of the given name. With the `variable` task, the result
of the action is assigned to a variable with the specified name. The `task`
target is a generic task that can be used for general processing and to 
connect dependencies (like the PHONY target in a Makefile). All dependencies
(also called prerequisites) must be satisfied before running the action.

`directory`, `file`, `task`, and `variable` are all exported, but it is best
to fully qualify these to help task definitions stand out.

`Maker` works well with [Glob.jl](https://github.com/vtjnash/Glob.jl) for file
and name wildcards. 
[Here](https://github.com/tshort/Maker.jl/blob/master/test/glob.jl)
is an example of how globs can be used currently for traditional make-like 
file operations.

## Utilities

A few utilities are provided to help with tasks:

* `Maker.rm(name)` -- Equivalent to `Base.rm`, but it doesn't error if file 
  `name` is missing. Not exported.

* `Maker.clean(name, filelist)` -- Create a task `name` (defaults to "clean")
  that will delete files given in `filelist`. Not exported.

* `tasks()` or `tasks(name)` -- Return (and show) all registered tasks or 
  task `name`. Exported.

Although the API is geared towards use in scripts, you can use a standalone
"makerfile.jl" to define tasks. See this
[makerfile.jl](https://github.com/tshort/Maker.jl/blob/master/makerfile.jl)
for an example. Run with `julia makerfile.jl cleancov`, `bin/maker cleancov`,
or define an alias (using the bash shell in this example):

```bash
alias maker='julia makerfile.jl' 
maker cleancov
```

By convention, a "makerfile.jl" should end with `make(ARGS)` to run make on
all arguments.

## Under the hood

`Maker` uses the global Dict `Maker.TARGETS` to store active tasks. Some state
is also stored in a [JLD](https://github.com/JuliaLang/JLD.jl) file
".maker-cache.jld" in the active directory. This stores hashes for functions and
variables along with timestamps. This allows `Maker` to be used between
sessions. 

Note that tasks are defined globally, so they may be defined in modules or
in the `Main` module. `make` works fine in a module for tasks defined in that
module. You cannot run all actions in `Main` that are defined in another module
(particularly for variable tasks).

The hashing for functions and variables is not likely to stay the same between
Julia versions. It's also different for 32- and 64-bit versions. It's still up
in the air how to deal with this. Also, hashing for v0.4 anonymous functions 
includes file information, so two actions with the same definition won't look
the same. Line numbers are removed, so the same definitions or redefinitions 
within one file will have the same hash.

Timestamps are stored for all tasks, even file tasks. On some filesystems, 
`mtime` only has an accuracy of one second, and this can cause inaccuracies 
with variable timestamps.

Note that parallel operation may be tricky. One may have to be careful using 
`@everywhere` and friends with `Maker`. Each process might try to update 
dependencies at the same time, leading to race conditions. Another topic to
think about is how to take advantage of parallel operations (or threads when 
they come to Julia). 
  
