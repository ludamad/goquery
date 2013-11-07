goal.DatabaseConnect("test.db", --[[Remove previous]] true) 

goal.DefineTuple("MyTable", {"Name", "Location"}, {"Name", "Location"})

goal.SimpleRun({
    "Foo", "Oshawa"
}, {
    CONSTANT(0), CONSTANT(1), SAVE_TUPLE(0,0, 2),
})

goal.FlushBuffers()

local columns, results = goal.Query "select * from Mytable"
for i, column in ipairs(columns) do
    io.write(column .. '\t')
end
print("\n-------------------")
for i, result in ipairs(results) do
    for j, subresult in ipairs(result) do
        io.write(subresult .. '\t')
    end
    print()
end

