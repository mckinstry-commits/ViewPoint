SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[EMChangeEquipCol] 
as
/*********************************************
*	Created By:		TRL 08/20/08 Issue 126196
*	Modified By:	JB	4/28/10	Issue 138918 - Replaced with more efficient query
*
*   Usage:  Used to get all the 'bEquip' columns in
*   the selection Viewpoint database for all Viewpoint Tables.
*   These record are used by the EM Equipment Change program 
*   
***********************************************/

SELECT DISTINCT 
	ViewpointDB = t.TABLE_CATALOG,VPTableType = ISNULL(d.TableType, 'Maint'),
	VPTableName = t.TABLE_NAME, 
	VPColumnName=c.COLUMN_NAME,
	VPColType = CASE WHEN ISNULL(f.Seq, 0) < 5000 THEN 
					'Standard' 
				ELSE 
					CASE WHEN u.TableName IS NOT NULL THEN 
						'User Database' 
					ELSE 
						'Custom Field' 
					END
				END
FROM INFORMATION_SCHEMA.TABLES t WITH (NOLOCK)
	INNER JOIN INFORMATION_SCHEMA.COLUMNS c (NOLOCK)ON c.TABLE_NAME = t.TABLE_NAME AND c.TABLE_CATALOG = t.TABLE_CATALOG
	LEFT JOIN dbo.DDTH d WITH (NOLOCK) ON d.TableName = t.TABLE_NAME 
	LEFT JOIN dbo.DDFIShared f WITH (NOLOCK) ON f.ViewName = c.TABLE_NAME AND f.ColumnName = c.COLUMN_NAME
	LEFT JOIN dbo.UDTH u WITH (NOLOCK) ON u.TableName = t.TABLE_NAME 
WHERE 
	t.TABLE_TYPE = 'VIEW' 
	AND t.TABLE_NAME NOT IN ('EMEM','EMEH','EMED') 
	AND  (d.TableType NOT IN ('View') OR u.TableName IS NOT NULL)
	AND c.DOMAIN_NAME = 'bEquip' 
	

GO
GRANT SELECT ON  [dbo].[EMChangeEquipCol] TO [public]
GRANT INSERT ON  [dbo].[EMChangeEquipCol] TO [public]
GRANT DELETE ON  [dbo].[EMChangeEquipCol] TO [public]
GRANT UPDATE ON  [dbo].[EMChangeEquipCol] TO [public]
GRANT SELECT ON  [dbo].[EMChangeEquipCol] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMChangeEquipCol] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMChangeEquipCol] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMChangeEquipCol] TO [Viewpoint]
GO
