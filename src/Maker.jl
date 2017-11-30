module Maker

using Compat
using Compat.Dates
using JLD2

export directory,
       file,
       make,
       phony,
       task,
       tasks,
       variable,
       @desc

const CACHEFILE = ".maker-cache.jld2"
const CACHEVERSION = v"0.1"


"""
`Maker.AbstractTarget`

`AbstractTarget` is an abstract type covering various "targets" or "tasks".
Each of these targets normally has an action and zero or more dependencies.
"""
abstract type AbstractTarget end

abstract type AbstractCached end

include("targets.jl")
include("abstracttarget.jl")
include("task.jl")
include("phony.jl")
include("directory.jl")
include("file.jl")
include("variable.jl")
include("utils.jl")



end # module

