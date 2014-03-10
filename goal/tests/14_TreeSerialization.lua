require "goal"

DataSet("sqlite3", "14_TreeSerialization.db")

--Data "code_blocks" (
--    Key "tag", Key "parent", Key "receiver_type:LONG", "location"
--)

local COMMIT_ID = "test-commit"

DataExec [[
	CREATE TABLE tags(
		tag TEXT,
		parent TEXT,
		receiver_type LONG,
		location TEXT, 
		PRIMARY KEY (tag,parent,receiver_type))
]]