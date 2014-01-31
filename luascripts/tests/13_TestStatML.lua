require "Globals"

require "TableUtils"
require "flextypes.Globals" -- Import flextypes

local StatML = require "statml.StatML"

for _,file in ipairs {"01_simple.yaml", "02_object.yaml"} do
    file = "tests/statml/" .. file
    local testname = file:match("(%d%d_%w*%.yaml)")
    if testname then
        StatML.reset()
        StatML.load_file(file)
        StatML.parse_all()
        local asserts = StatML.instances.Asserts
        assert(asserts, "No assert instance defined!")
        for k, v in pairs(asserts) do
            assert(v == true, ("Asserts.%s was not 'true', was '%s'!"):format(k, tostring(v)))
        end
    end
end