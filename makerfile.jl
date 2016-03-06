# These are various tasks to help with package development.

using Maker
using Glob

Maker.task("cleancov") do 
    for fn in glob("*/*.cov")
        rm(fn)
    end
end

Maker.task("coverage", "cleancov") do
    cd("test") do
        run(`julia --code-coverage=user --inline=no runtests.jl`)
    end
    # coverage = Coverage.process_folder("src")
    # @show Coverage.get_summary(coverage)       
end
       
Maker.task("tests") do
    Pkg.test("Maker")
end

Maker.task("localtests") do
    cd("$(Pkg.dir())/Maker/test") do
        include("runtests.jl")
    end
end

Maker.task("register") do
    Pkg.register("Maker")
end

Maker.task("tagminor") do
    Pkg.tag("Maker", :minor)
end
 
Maker.task("tagpatch") do
    Pkg.tag("Maker", :patch)
end
 
Maker.task("publish") do
    Pkg.publish()
end

Maker.task("pull") do
    run(`git pull origin $(Pkg.Git.branch())`)
end

Maker.task("push") do
    run(`git push origin $(Pkg.Git.branch())`)
end

make(ARGS)

