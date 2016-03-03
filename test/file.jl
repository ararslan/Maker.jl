
using Make
using Base.Test

COUNT = 0

path = "tmpdir/tmp"

Make.directory(path)

Make.file("$path/x.csv", path) do
    global COUNT += 1
    writecsv("$path/x.csv", rand(2,2))
end

Make.file("$path/y.csv", "$path/x.csv") do
    global COUNT += 1
    y = readcsv("$path/x.csv") 
    writecsv("$path/y.csv", 2 * y) 
end

Make.task("default", "$path/y.csv")

Make.task("clean") do
    rm("tmpdir", recursive = true)
end

make()

@test COUNT == 2
@test isdir("tmpdir")
@test isdir("tmpdir/tmp")
@test isfile("tmpdir/tmp/x.csv")
@test isfile("tmpdir/tmp/y.csv")
    
make()
make()
@test COUNT == 2

make("clean")

@test !isdir("tmpdir")
@test !isdir("tmpdir/tmp")
@test !isfile("tmpdir/tmp/x.csv")
@test !isfile("tmpdir/tmp/y.csv")


