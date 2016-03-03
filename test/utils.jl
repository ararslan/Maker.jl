
using Maker
using Base.Test

fname = "t.txt"
open(fname, "w") do f
    println(f, "hello")
end
@test isfile(fname)
Maker.rm(fname)
@test !isfile(fname)
Maker.rm(fname)
@test !isfile(fname)

Maker.file("t.txt")

Maker.file("t1.txt") do 
    open("t1.txt", "w") do f
        println(f, "hello")
    end
end
Maker.file("t2.txt") do 
    open("t2.txt", "w") do f
        println(f, "hello")
    end
end
Maker.task("create files", ["t1.txt", "t2.txt"])
Maker.clean(["t1.txt", "t2.txt"])

make("create files")
@test isfile("t1.txt")
@test isfile("t2.txt")

make("clean")
@test !isfile("t1.txt")
@test !isfile("t2.txt")



