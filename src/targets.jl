
"""
`Maker.Targets`

An Associative type for storing `AbstractTargets`. A simple wrapper 
of a Dict to allow more suitable display of the set of AbstractTargets.
"""
immutable Targets <: Associative
    dict::Dict{UTF8String, AbstractTarget}
end

Base.length(x::Targets) = length(x.dict)
Base.keys(x::Targets) = keys(x.dict)
Base.getindex(x::Targets, key) = getindex(x.dict, key)
Base.get(x::Targets, key, default) = get(x.dict, key, default)
Base.setindex!(x::Targets, key, val) = setindex!(x.dict, key, val)
Base.empty!(x::Targets) = empty!(x.dict)
Base.start(x::Targets) = start(x.dict)
Base.done(x::Targets, i) = done(x.dict, i)
Base.next(x::Targets, i) = next(x.dict, i)

"""
```julia
Maker.TARGETS
```

The global `Targets` dictionary for registered AbstractTargets.
"""
const TARGETS = Targets(Dict{UTF8String, AbstractTarget}()) 
NEXTDOC = UTF8String[""]

"""
```julia
@desc
```

Define a description for the next Maker task.
"""
macro desc(arg)
    :(Maker.NEXTDOC[1] = $arg)
end


"""
```julia
tasks()
tasks(name)
```

Return the target `name` or return all targets. Often used to show summaries of
all registered targets or a specific target.
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

function funloc(f::Function)
    if isgeneric(f)
        a = functionloc(f, has1arg(f) ? (AbstractTarget,) : ())
        return string(a[1], " line ", a[2])
    else
        return funloc(Base.uncompressed_ast(f.code))
    end
end
    
function funloc(e::Expr)
    for a in e.args[3].args
         if isa(a, LineNumberNode)
             return string(a.file, " line ", a.line)
         end
   end
   return ""
end
    
function Base.show{T <: AbstractTarget}(io::IO, t::T)
    print(io, "\"", t.name, "\"")
    println(io, " => ", replace(string(t.dependencies), "UTF8String", ""))
    println(io, T)
    !isempty(t.description) && println(io, t.description)
    println(io, "Timestamp: ", t.timestamp, " UTC")
    println(io, "Action defined at: ", funloc(t.action))
    t.isstale && println(io, "STALE task")
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


