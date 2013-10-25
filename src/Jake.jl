module Jake

export AbstractTarget,
       FileTarget,
       PhonyTarget,
       add_action,
       add_dependency,
       dependencies,
       execute,
       isstale,
       register,
       timestamp

abstract AbstractTarget

const TARGETS = (UTF8String => AbstractTarget)[]

for T in (:FileTarget, :PhonyTarget)
    @eval begin
        immutable $T <: AbstractTarget
            name::UTF8String
            dependencies::Array{UTF8String,1}
            actions::Array{Function,1}
        end

        $T(name::String) = $T(utf8(name), UTF8String[], Function[])
    end
end

add_action(t::AbstractTarget, a::Function) = push!(t.actions, a)

add_dependency(t::AbstractTarget, d::String) = push!(t.dependencies, utf8(d))

dependencies(t::AbstractTarget) = [resolve(d) for d in t.dependencies]

execute(t::AbstractTarget) = for a in t.actions; a() end

function invoke(t::AbstractTarget)
    for d in dependencies(t)
        invoke(d)
    end
    isstale(t) && execute(t)
end
invoke(s::String) = invoke(resolve(s))

function isstale(t::FileTarget)
    if !isfile(t.name) return true end
    ds = dependencies(t)
    length(ds) == 0 ? false : timestamp(t) < maximum([timestamp(d) for d in ds])
end
isstale(t::AbstractTarget) = true

register(t::AbstractTarget) = (TARGETS[t.name] = t; nothing)
resolve(s::String) = get(TARGETS, utf8(s), nothing)

timestamp(t::FileTarget) = mtime(t.name)
timestamp(t::AbstractTarget) = time()

end # module
