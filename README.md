# Maker.jl: A tool like make for Julia

This repository is an **experimental** approach to process data using
dependencies in a similar fashion to
[make](https://en.wikipedia.org/wiki/Makefile) or
[Rake](http://docs.seattlerb.org/rake/). Like make, Maker.jl evaluates file and
code dependencies to update processing. The focus here is on data analysis, not
build automation for code. The features to support data analysis include:

- *Detection of code changes*--If part of the code changes, downstream 
  dependencies are updated during processing.
- *Variable tasks*--Most make-like tools rely mainly on files for 
  dependency analysis. In Maker.jl, Julia variables can also be used
  in this role. That allows more fine-grained control of code and dependencies. 
 
Maker.jl was derived from [Jake.jl](https://github.com/nolta/Jake.jl) by Mike
Nolta. [Juke.jl](https://github.com/kshramt/Juke.jl) is another Make-like tool
written in Julia. The API here is most similar to Ruby's
[Rake](http://docs.seattlerb.org/rake/).

Most build tools like make use a Makefile or other build-instruction file. In
Maker.jl, a separate build-script can be used, but the API right now focuses on
use within Julia script files.

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

## Utilities

A few utilities are provided to help with tasks:

* `Maker.rm(name)` -- Equivalent to `Base.rm`, but it doesn't error if file `name` is
  missing.

* `Maker.clean(name, filelist)` -- Create a task `name` (defaults to "clean")
* that will delete files given in `filelist`.

## Under the hood

Maker.jl uses the global Dict `Maker.TARGETS` to store active tasks. Some state
is also stored in a [JLD](https://github.com/JuliaLang/JLD.jl) file
".maker-cache.jld" in the active directory. This stores hashes for functions and
variables along with timestamps. This allows Maker.jl to be used between
sessions. 

Note that tasks are defined globally, so they may be defined in modules or
in the `Main` module. `make` works fine in a module for tasks defined in that
module. You cannot run all actions in `Main` that are defined in another module
(particularly for variable tasks).

The hashing for functions and variables is not likely to stay the same between
Julia versions. It's also different for 32- and 64-bit versions. It's still up
in the air how to deal with this.

## Discussions

Here are some miscellaneous questions and open issues on this approach:

- As implemented, each function applied to a tasks takes no arguments. Rake
  and Juke.jl pass the task as an argument at least for some types of tasks.
  Zero arguments is easier and looks cleaner with do syntax, but it might be
  useful in some cases to have the task as an argument. It also may be 
  possible to make this optional. `Maker.execute` would need to use `try`-`catch` 
  or some means to test the number of arguments in the anonymous or generic
  function.
  
- Parallel operation may be tricky. One may have to be careful using 
  `@everywhere` and friends with Maker.jl. Each process might try to update 
  dependencies at the same time, leading to race conditions. Another topic to
  think about is how to take advantage of parallel operations (or threads when 
  they come to Julia). 
  
- API to help with debugging might help.

- File tasks are based on the current working directory. It might be better
  to use `@__FILE__` to work out the path.
  
- Would there be a way to attach docstrings to tasks? You can attach a 
  docstring to a generic function used as an action of a task. 

- Here are additional Rake features that may be nice:
  - `FileLists`
  - Rules
  - Globs for file/task matching (probably using @vtnash's 
    [Glob.jl](https://github.com/vtjnash/Glob.jl)). 
    [Here](https://github.com/tshort/Maker.jl/blob/master/test/glob.jl)
    is an example of how globs can be used currently for traditional make-like 
    file operations.

