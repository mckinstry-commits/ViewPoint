SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--Identifies table constraints for tables where the current user has any permissions on object.
CREATE VIEW [dbo].[pvViewpointInformationSchemaTableConstraints]
 
AS

SELECT
	db_name()				as CONSTRAINT_CATALOG
	,user_name(c_obj.uid)	as CONSTRAINT_SCHEMA
	,c_obj.name				as CONSTRAINT_NAME
	,db_name()				as TABLE_CATALOG
	,user_name(t_obj.uid)	as TABLE_SCHEMA
	,t_obj.name				as TABLE_NAME
	,case c_obj.xtype
					when 'C' then	'CHECK'
					when 'UQ' then	'UNIQUE'
					when 'PK' then	'PRIMARY KEY'
					when 'F' then	'FOREIGN KEY'
		 		  end		as CONSTRAINT_TYPE
	,'NO'					as IS_DEFERRABLE
	,'NO'					as INITIALLY_DEFERRED
FROM
	sysobjects	c_obj
	,sysobjects	t_obj
WHERE
	t_obj.id = c_obj.parent_obj
	and c_obj.xtype	in ('C' ,'UQ' ,'PK' ,'F')

GO
GRANT SELECT ON  [dbo].[pvViewpointInformationSchemaTableConstraints] TO [public]
GRANT INSERT ON  [dbo].[pvViewpointInformationSchemaTableConstraints] TO [public]
GRANT DELETE ON  [dbo].[pvViewpointInformationSchemaTableConstraints] TO [public]
GRANT UPDATE ON  [dbo].[pvViewpointInformationSchemaTableConstraints] TO [public]
GRANT SELECT ON  [dbo].[pvViewpointInformationSchemaTableConstraints] TO [VCSPortal]
GO
