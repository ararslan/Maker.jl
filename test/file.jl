
using Maker
using Base.Test

COUNT = 0

path = "tmpdir/tmp"

Maker.directory(path)

Maker.file("$path/x.csv", path) do t
    global COUNT += 1
    writecsv(t.name, rand(2,2))
end

@desc "Update y.csv"
function update_y_csv(t)
    global COUNT += 1
    y = readcsv(t.dependencies[1]) 
    writecsv(t.name, 2 * y) 
end
Maker.file(update_y_csv, "$path/y.csv", "$path/x.csv")
show(tasks("$path/y.csv"))

Maker.task("default", "$path/y.csv")

Maker.task("clean") do
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

rm("tmpdir/tmp", recursive = true)
make()
@test COUNT == 4

make("clean")

@test !isdir("tmpdir")
@test !isdir("tmpdir/tmp")
@test !isfile("tmpdir/tmp/x.csv")
@test !isfile("tmpdir/tmp/y.csv")

Maker.fixcache()
