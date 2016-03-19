
    {meta}
    CurrentModule = Maker

# Core methods

The following methods are used internally but may be used externally, too. None
are exported.
    
    {index}
    Pages = ["internals.md"]
    
...
    
    {docs}
    dependencies
    execute
    fixcache
    isstale
    register
    resolve
    resolvedependency
    tasks!
    timestamp
    TARGETS


## Internals

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
has file information removed.

Timestamps are stored for all tasks, even file tasks. On some filesystems, 
`mtime` only has an accuracy of one second, and this can cause inaccuracies 
with variable timestamps.

Note that parallel operation may be tricky. One may have to be careful using 
`@everywhere` and friends with `Maker`. Each process might try to update 
dependencies at the same time, leading to race conditions. Another topic to
think about is how to take advantage of parallel operations (or threads when 
they come to Julia). 
  