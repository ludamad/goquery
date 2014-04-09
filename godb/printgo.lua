local LineBuffer = newtype()

function LineBuffer:init(str)
    self.line = str
    self.offset = 0 -- How much accumulated color marking there is
end

function LineBuffer:annotate(ocol, ncol, p1, --[[Optional]] p2)
print(p1, p2)
    local L, o = self.line, self.offset
    -- Apply offset:
    p1 = p1 + o ; p2 = (p2 and p2 + o or #L)
    -- Split the string up:
    local pre, post = L:sub(1, p1 -1), L:sub(p2, #L+1)
    local mid = L:sub(p1,p2-1)
    -- Apply color, update line:
    self.line = pre .. ncol .. mid .. ocol .. post
    -- Update offset:
    self.offset = o + #ocol + #ncol
end

function LineBuffer:slice(p1, --[[Optional]] p2)
    return self.line:sub(p1, p2 or (#self.line + 1))
end

local FileBuffer = newtype()
function FileBuffer:init(fname)
    local lines = {}
    for line in io.lines(fname) do
        append(lines, LineBuffer.create(line))
    end
    self.lines = lines
end
function FileBuffer:line(l)
    return self.lines[l].line
end

local function proc_col(col)
    return '\27[' .. col .. 'm'
end

local FileBufferMap = newtype()
function FileBufferMap:init()
    self.map = {}
    self.color_stack = {proc_col "0"}
end

function FileBufferMap:pop_col()
    self.color_stack[#self.color_stack] = nil
end
function FileBufferMap:peek_col() 
    return self.color_stack[#self.color_stack] 
end

function FileBufferMap:annotate(col, loc1, loc2)
    local fname = loc1.fname
    assert(loc2.fname == fname)
    local buff = self:get(fname)
    for i=loc1.line,loc2.line do
        local pstart,pend = 1,nil
        if i == loc1.line then pstart = loc1.pos end
        if i == loc2.line then pend = loc2.pos end
        buff.lines[i]:annotate(self:peek_col(),col,pstart,pend)
    end
end

function FileBufferMap:slice(loc1, loc2)
    local fname = loc1.fname
    assert(loc2.fname == fname)
    local buff = self:get(fname)
    local ret = ''
    for i=loc1.line,loc2.line do
        local pstart,pend = 1,nil
        if i == loc1.line then pstart = loc1.pos end
        if i == loc2.line then pend = loc2.pos end
        ret = ret .. buff.lines[i]:slice(start,pend) .. '\n'
    end
    return ret
end

function FileBufferMap:push_col(node)
    append(self.color_stack, node)
end

function FileBufferMap:get(fname)
    local buff = self.map[fname] or FileBuffer.create(fname)
    self.map[fname] = buff
    return buff
end

local function parse_loc(str)
    local fname, line, pos = unpack(str:split(":"))
    return {fname=fname, line=tonumber(line), pos=tonumber(pos)}
end

-- Our file buffer map stores our annotated files
local function annotate(node, fmap, callback)
    local col = callback(node)
    if col then
        col = proc_col(col)
        local loc, end_loc = parse_loc(node.location), parse_loc(node.end_location)
        fmap:annotate(col, loc, end_loc)
        fmap:push_col(col)
    end

    for _,child in ipairs(node.links) do
        -- Navigate the tree:
        annotate(child, fmap, callback)
    end
    if col then fmap:pop_col() end
end

local function print_go(root, callback)
    local fmap = FileBufferMap.create()
    annotate(root, fmap, callback)
    local loc, end_loc = parse_loc(root.location), parse_loc(root.end_location)
    for i=loc.line,end_loc.line do
        print(fmap:get(loc.fname):line(i))
    end
end

local file_map = FileBufferMap.create()

local function get_source(node)
    local loc, end_loc = parse_loc(root.location), parse_loc(root.end_location)
    return fmap:get(loc.fname):slice(loc, end_loc)
end

return {
    print_go = print_go,
    get_source = get_source,
    parse_loc = parse_loc
}
