
using Maker
using Base.Test
using Glob

x = [ 3.14159   6.28319   9.42478
      12.5664   15.708    18.8496
      21.9911   25.1327   28.2743 ]
writecsv("in1.csv", x)      
writecsv("in2.csv", 3x)      

inputs = glob("in*.csv")
outputs = ["$(splitext(f)[1])-out.csv" for f in inputs]

for i in eachindex(inputs)
    inp = inputs[i]
    Maker.file(inp)
    dest = outputs[i]
    Maker.file(dest, inp) do
        out = 2 * readcsv(inp, skipstart = 1)
        writecsv(dest, out)
    end
end

Maker.task("default", outputs)

Maker.clean(outputs)

Maker.task("clean2") do   # another way to clean
    println("CLEAN2")
    for fn in glob("in*-out.csv")
        Maker.rm(fn)
    end
end

Maker.task("cleanall") do   # another way to clean
    for fn in glob("in*.csv")
        Maker.rm(fn)
    end
end

make()

@test isfile(outputs[1])
@test isfile(outputs[2])

make("clean") 

@test !isfile(outputs[1])
@test !isfile(outputs[2])

make([]) # the [] are to test this call method

@test isfile(outputs[1])
@test isfile(outputs[2])

make("clean2") 

@test !isfile(outputs[1])
@test !isfile(outputs[2])

make("cleanall") 
