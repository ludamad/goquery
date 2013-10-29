dofile "src/tests/util.lua"

local type = typeof -- DSL redefines 'type'

local function make(parent, chain)
    for i,part in ipairs(chain) do
        if type(part) == "table" then
            for k, v in pairs(part) do
                make(parent.Lookup(k), v)
            end
        else
            parent.Lookup(part)
        end
    end
end

local function test(str, v1, v2, ...)
    return assert(v1 == v2, str:format(v1,v2, ...))
end

local check
local function check_refs(members, sizes, indices)
    for i, member in ipairs(members) do
        check(member, sizes[i], indices[i])
    end
end
function check(node, sizes, indices)
    if type(sizes) == "number" then sizes = {sizes} end
    if type(indices) == "number" then indices = {indices} end

    test("Size %s does not resolve to %s!", node.ResolveSize(), sizes[1])
    test("Index %s does not resolve to %s!", node.ResolveIndex(), indices[1])
    if sizes[2] then
        check_refs(node.members, sizes[2], indices[2])
    end
end

local function ObjectRefTest(chain, sizes, indices)
    local root = goal.ObjectRef("")
    make(root, chain)
    check_refs(root.members, sizes, indices)
end

ObjectRefTest (
    {"Foo"},
    {1}, -- Sizes
    {0} -- Indices
)

ObjectRefTest (
    {{Foo = {"Bar"}}},
    {{2, {1}}}, -- Sizes
    {{0, {1}}} -- Indices
)

ObjectRefTest (
    {{Foo = {"Bar", "Baz"}}},
    {{3, {1, 1}}}, -- Sizes
    {{0, {1, 2}}} -- Indices
)

-- Basic compiler tests

local compiler = goal.Compiler()
compiler.ResolveObject {"Foo", "Bar", "Baz"}
local node = compiler.ResolveObject {"Foo", "Bar", "Baz2"}
check(node, 1, 3)
test("Compiler size %s does not resolve to %s!", compiler.objects.members[1].ResolveSize(), 4)