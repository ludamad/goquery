package.path = package.path .. ';./.libs/?.lua'
package.cpath = package.cpath .. ';./.libs/?.so'

local sql = require "ljsqlite3"
local conn = sql.open("goal/14_TreeSerialization.db")  

local rec = conn:exec "SELECT * FROM functions"
for k,v in ipairs(rec) do
    print(k,v)
end

conn:close() -- Close stmt as well.
