
```@meta
CurrentModule = Maker
```

# API

The main API here is rather basic:

* `make(name="default")` -- Process the target `name` by evaluating dependencies
  that need to be updated. "default" is the name of the default task. If `name`
  is a Vector of names, each name is processed sequentially.

* [`Maker.directory`](@ref), `Maker.file`, `Maker.phony`, `Maker.task`, and
  `Maker.variable` -- These methods all define tasks or targets to be updated.
  Each task has a name, zero or more dependencies, and an action as follows:

```julia
Maker.task(action::Function, name::AbstractString, dependencies::Vector{AbstractString})
```

Normally with the `file` task, the `action` will perform an operation to create
or update the file of the given name. With the `variable` task, the result of
the action is assigned to a variable with the specified name. The `task` target
is a generic task that can be used for general processing and to  connect
dependencies. All dependencies must be satisfied before running the action.
`phony` is like `task`, but the timestamp always appears old, so it doesn't
trigger upstream actions.

The `action` function can be called with zero or one arguments. If the
one-argument version is available, that version is called. The argument is the
`AbstractTarget` defined. Here is an example of this use:

```julia
Maker.file("in.csv", "out.csv") do t
    x = readcsv(t.dependencies[1])
    writecsv(t.name, 3 * x)
end
```

The following fields of an AbstractTarget are suitable for access: `t.name`,
`t.dependencies`, `t.description`, and `t.action`.

`directory`, `file`, `phony`, `task`, and `variable` are all exported, but it is
best to fully qualify these to help task definitions stand out.

`Maker` works well with [Glob.jl](https://github.com/vtjnash/Glob.jl) for file
and name wildcards.
[Here](https://github.com/tshort/Maker.jl/blob/master/test/glob.jl)
is an example of how globs can be used currently for traditional make-like
file operations.

Although the API is geared towards use in scripts, you can use a standalone
"makerfile.jl" to define tasks. See this
[makerfile.jl](https://github.com/tshort/Maker.jl/blob/master/makerfile.jl)
for an example. Run with `` `julia makerfile.jl cleancov` ``,
`` `bin/maker cleancov` ``,
or define an alias (using the bash shell in this example):

```bash
alias maker='julia makerfile.jl'
maker cleancov
```

By convention, a "makerfile.jl" should end with `make(ARGS)` to run make on
all arguments.
