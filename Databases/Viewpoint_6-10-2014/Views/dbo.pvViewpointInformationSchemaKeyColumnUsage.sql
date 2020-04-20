SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--Identifies columns which have constrained keys 
CREATE  VIEW [dbo].[pvViewpointInformationSchemaKeyColumnUsage] 

AS
 
SELECT
	db_name()				as CONSTRAINT_CATALOG
	,user_name(c_obj.uid)	as CONSTRAINT_SCHEMA
	,c_obj.name				as CONSTRAINT_NAME
	,db_name()				as TABLE_CATALOG
	,user_name(t_obj.uid)	as TABLE_SCHEMA
	,t_obj.name				as TABLE_NAME
	,col.name				as COLUMN_NAME
	,case col.colid	
		when ref.fkey1 then 1			
		when ref.fkey2 then 2			
		when ref.fkey3 then 3			
		when ref.fkey4 then 4			
		when ref.fkey5 then 5			
		when ref.fkey6 then 6			
		when ref.fkey7 then 7			
		when ref.fkey8 then 8			
		when ref.fkey9 then 9			
		when ref.fkey10 then 10			
		when ref.fkey11 then 11			
		when ref.fkey12 then 12			
		when ref.fkey13 then 13			
		when ref.fkey14 then 14			
		when ref.fkey15 then 15			
		when ref.fkey16 then 16
	end						as ORDINAL_POSITION
FROM
	sysobjects	c_obj
	,sysobjects	t_obj
	,syscolumns	col
	,sysreferences  ref
WHERE
	c_obj.xtype	in ('F ')
	and t_obj.id	= c_obj.parent_obj
	and t_obj.id	= col.id
	and col.colid   in 
	(ref.fkey1,ref.fkey2,ref.fkey3,ref.fkey4,ref.fkey5,ref.fkey6,
	ref.fkey7,ref.fkey8,ref.fkey9,ref.fkey10,ref.fkey11,ref.fkey12,
	ref.fkey13,ref.fkey14,ref.fkey15,ref.fkey16)
	and c_obj.id	= ref.constid

/*
UNION
 
SELECT
	db_name()				as CONSTRAINT_CATALOG
	,user_name(c_obj.uid)	as CONSTRAINT_SCHEMA
	,i.name					as CONSTRAINT_NAME
	,db_name()				as TABLE_CATALOG
	,user_name(t_obj.uid)	as TABLE_SCHEMA
	,t_obj.name				as TABLE_NAME
	,col.name				as COLUMN_NAME
	,v.number				as ORDINAL_POSITION
FROM
	sysobjects		c_obj
	,sysobjects		t_obj
	,syscolumns		col
	,master.dbo.spt_values 	v
	,sysindexes		i
WHERE
	c_obj.xtype	in ('UQ' ,'PK')
	and t_obj.id	= c_obj.parent_obj
	and t_obj.xtype  = 'U'
	and t_obj.id	= col.id
	and col.name	= index_col(t_obj.name,i.indid,v.number)
	and t_obj.id	= i.id
	and c_obj.name  = i.name
	and v.number 	> 0 
 	and v.number 	<= i.keycnt 
 	and v.type 	= 'P'


*/

GO
GRANT SELECT ON  [dbo].[pvViewpointInformationSchemaKeyColumnUsage] TO [public]
GRANT INSERT ON  [dbo].[pvViewpointInformationSchemaKeyColumnUsage] TO [public]
GRANT DELETE ON  [dbo].[pvViewpointInformationSchemaKeyColumnUsage] TO [public]
GRANT UPDATE ON  [dbo].[pvViewpointInformationSchemaKeyColumnUsage] TO [public]
GRANT SELECT ON  [dbo].[pvViewpointInformationSchemaKeyColumnUsage] TO [VCSPortal]
GRANT SELECT ON  [dbo].[pvViewpointInformationSchemaKeyColumnUsage] TO [Viewpoint]
GRANT INSERT ON  [dbo].[pvViewpointInformationSchemaKeyColumnUsage] TO [Viewpoint]
GRANT DELETE ON  [dbo].[pvViewpointInformationSchemaKeyColumnUsage] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[pvViewpointInformationSchemaKeyColumnUsage] TO [Viewpoint]
GO
