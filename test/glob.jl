
using Make
using Base.Test
using Glob


inputs = glob("in*.csv")
outputs = ["$(splitext(f)[1])-out.csv" for f in inputs]

for i in eachindex(inputs)
    inp = inputs[i]
    Make.file(inp)
    dest = outputs[i]
    Make.file(dest, inp) do
        out = 2 * readcsv(inp, skipstart = 1)
        writecsv(dest, out)
    end
end

Make.task("default", outputs)

Make.clean(outputs)

Make.task("clean2") do   # another way to clean
    for fn in glob("in*-out.csv")
        Make.rm(fn)
    end
end

make()

@test isfile(outputs[1])
@test isfile(outputs[2])

make("clean") 

@test !isfile(outputs[1])
@test !isfile(outputs[2])

make()

@test isfile(outputs[1])
@test isfile(outputs[2])

make("clean2") 

@test !isfile(outputs[1])
@test !isfile(outputs[2])

