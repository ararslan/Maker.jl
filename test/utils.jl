
using Make
using Base.Test

fname = "t.txt"
open(fname, "w") do f
    println(f, "hello")
end
@test isfile(fname)
Make.rm(fname)
@test !isfile(fname)
Make.rm(fname)
@test !isfile(fname)

Make.file("t.txt")

Make.file("t1.txt") do 
    open("t1.txt", "w") do f
        println(f, "hello")
    end
end
Make.file("t2.txt") do 
    open("t2.txt", "w") do f
        println(f, "hello")
    end
end
Make.task("create files", ["t1.txt", "t2.txt"])
Make.clean(["t1.txt", "t2.txt"])

make("create files")
@test isfile("t1.txt")
@test isfile("t2.txt")

make("clean")
@test !isfile("t1.txt")
@test !isfile("t2.txt")



