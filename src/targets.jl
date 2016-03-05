
immutable Targets
    dict::Dict{UTF8String, AbstractTarget}
end

Base.length(x::Targets) = length(x.dict)
Base.keys(x::Targets) = keys(x.dict)
Base.getindex(x::Targets, key) = getindex(x.dict, key)
Base.get(x::Targets, key, default) = get(x.dict, key, default)
Base.setindex!(x::Targets, key, val) = setindex!(x.dict, key, val)
Base.empty!(x::Targets) = empty!(x.dict)

const TARGETS = Targets(Dict{UTF8String, AbstractTarget}()) 
NEXTDOC = UTF8String[""]

"""
```julia
@desc
```

Define a docstring for the next Maker task.
"""
macro desc(arg)
    :(Maker.NEXTDOC[1] = $arg)
end


"""
```julia
tasks()
tasks(name)
```

Return the target `name` or return a Vector of all targets.
"""
tasks() = TARGETS

tasks(name) = TARGETS.dict[name]

"""
```julia
tasks!(name, target)
```

Add the `target` task with name `name` to the global database of targets.
"""
function tasks!{T <: AbstractTarget}(name, val::T)
    TARGETS[name] = val
end
    
function Base.show{T <: AbstractTarget}(io::IO, t::T)
    print(io, "\"", t.name, "\"")
    println(io, " => ", replace(string(t.dependencies), "UTF8String", ""))
    !isempty(t.description) && println(io, "      ", t.description)
end

function markdown(X::Targets)
    ks = collect(keys(X))
    md = """
         task | dependencies | description
         :----|:-------------|:-----------
         """
    for k in sort(ks)
        t = X[k]
        md *= "\"" * t.name * "\" | " *
              replace(string(t.dependencies), "UTF8String", "") * 
              " | " * t.description * "\n"
    end
    Base.Markdown.parse(md)
end

function Base.show(io::IO, X::Targets)
    writemime(io, MIME"text/plain"(), markdown(X))
end

function Base.writemime(io::IO, T::MIME"text/plain", X::Targets)
    writemime(io, T, markdown(X))
end

function Base.display(d::Base.REPL.REPLDisplay, X::Targets)
    Base.Markdown.term(Base.REPL.outstream(d.repl), markdown(X))
end


