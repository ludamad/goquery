with RECURSIVE links as (
	select F.tag, F.name, "FuncDecl" as kind, "block" as label, 
		F.location, F.end_location, null as data, F.type, F.block_id as id, N.link_id, 0 as depth
	from FuncDecl F join   node_links N
	where F.tag == N.tag and F.block_id == N.id 
UNION
	select L.tag, L.name, D.kind, N.label, 
		D.location, D.end_location, D.data, D.type, L.link_id as id, N.link_id, L.depth+1
	from links  L join node_links N join  node_data D
	where  L.tag == N.tag and L.link_id == N.id 
	and D.tag == L.tag and D.id == L.link_id
) select  distinct
	tag, name, kind, location, end_location, data, depth
from 
	links
where 
	name == "resolveSpecialMember"
;