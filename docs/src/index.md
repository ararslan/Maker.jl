# Maker.jl

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


## Documentation

    {contents}
    Pages = [
        "introduction.md",
        "api.md",
        "make.md",
        "targets.md",
        "utilities.md",
        "terminology.md",
        "internals.md"
    ]
    Depth = 2

## Documentation Index

    {index}
    Pages = ["make.md", "targets.md", "utilities.md"]
