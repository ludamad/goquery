select 
	F.name, F.type, N.link_number as num, D.kind 
from FuncDecl F
join   node_links N
join   node_data D
where
	F.name like '%object%' 
and F.tag == N.tag
and F.block_id == N.id
and N.link_id == D.id
;