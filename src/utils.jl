"""
```julia
rm(name::AbstractString)
```

Equivalent to `Base.rm`, but it doesn't error if file `name` is missing.
"""
rm(f::AbstractString) = isfile(f) && Base.rm(f)


"""
```julia
clean(name::AbstractString, filelist)
clean(filelist)
```

Create a task `name` (defaults to "clean") that will delete files given in
`filelist`.
"""
function clean(name::AbstractString, filelist)
    task(name) do
        for f in filelist
            rm(f)
        end
    end
end
clean(filelist) = clean("clean", filelist)
