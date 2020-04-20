SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--Displays columns 
CREATE  VIEW [dbo].[pvViewpointInformationSchemaColumns]

AS

SELECT
	db_name()						as TABLE_CATALOG
	,user_name(obj.uid)				as TABLE_SCHEMA
	,obj.name						as TABLE_NAME
	,col.name						as COLUMN_NAME
	,col.colid						as ORDINAL_POSITION
	,com.text						as COLUMN_DEFAULT
	,case col.isnullable 
		when 1 then 'YES'
		else        'No '
	end								as IS_NULLABLE
	,type_name(col.xtype)					AS DATA_TYPE
FROM
	sysobjects obj,
	systypes typ,
	syscolumns col
	LEFT OUTER JOIN syscomments com on col.cdefault = com.id
		AND com.colid = 1,
	master.dbo.syscharsets		a_cha --charset/1001, not sortorder.
WHERE
	obj.id = col.id
	AND obj.xtype in ('U', 'V')
	AND col.xusertype = typ.xusertype
	AND	a_cha.id = isnull(convert(tinyint, CollationPropertyFromID(col.collationid, 'sqlcharset')),
			convert(tinyint, ServerProperty('sqlcharset'))) -- make sure there's one and only one row selected for each column

GO
GRANT SELECT ON  [dbo].[pvViewpointInformationSchemaColumns] TO [public]
GRANT INSERT ON  [dbo].[pvViewpointInformationSchemaColumns] TO [public]
GRANT DELETE ON  [dbo].[pvViewpointInformationSchemaColumns] TO [public]
GRANT UPDATE ON  [dbo].[pvViewpointInformationSchemaColumns] TO [public]
GRANT SELECT ON  [dbo].[pvViewpointInformationSchemaColumns] TO [VCSPortal]
GRANT SELECT ON  [dbo].[pvViewpointInformationSchemaColumns] TO [Viewpoint]
GRANT INSERT ON  [dbo].[pvViewpointInformationSchemaColumns] TO [Viewpoint]
GRANT DELETE ON  [dbo].[pvViewpointInformationSchemaColumns] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[pvViewpointInformationSchemaColumns] TO [Viewpoint]
GO
