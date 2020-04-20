SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view  [dbo].[EMChangeEquipEMCoCol]
as
/*********************************************
*	Created By:  TRL 08/20/08 Issue 126196
*	Modified By:	JB	4/28/10		Issue 138918 - Replaced with better performing query
*
*   Usage:  Used to get all the 'bEquip' columns EMCo columns
*   the selection Viewpoint database for all Viewpoint Tables.
*   These record are used by the EM Equipment Change program 
*   
***********************************************/
	SELECT DISTINCT
		e.ViewpointDB,
		e.VPTableName,
		e.VPColumnName,
		VPEMCo =	CASE WHEN c.DOMAIN_NAME = 'bCompany' THEN
						CASE WHEN e.VPColumnName LIKE '%UsedOn%' THEN 
							'UsedOnEquipCo' 
						ELSE 
							c.COLUMN_NAME 
						END
					ELSE
						NULL
					END,
		e.VPColType
	FROM dbo.EMChangeEquipCol e WITH (NOLOCK)
		INNER JOIN INFORMATION_SCHEMA.COLUMNS c WITH (NOLOCK) ON c.TABLE_NAME = e.VPTableName AND c.TABLE_CATALOG = e.ViewpointDB
		LEFT JOIN dbo.DDFIShared f WITH (NOLOCK) ON f.ViewName = c.TABLE_NAME AND f.ColumnName = c.COLUMN_NAME
	WHERE 
		e.VPTableType NOT IN ('Audit','View') 
		AND c.DOMAIN_NAME IN('bCompany')AND LOWER(c.COLUMN_NAME) IN ('emco','oldemco','co')

GO
GRANT SELECT ON  [dbo].[EMChangeEquipEMCoCol] TO [public]
GRANT INSERT ON  [dbo].[EMChangeEquipEMCoCol] TO [public]
GRANT DELETE ON  [dbo].[EMChangeEquipEMCoCol] TO [public]
GRANT UPDATE ON  [dbo].[EMChangeEquipEMCoCol] TO [public]
GRANT SELECT ON  [dbo].[EMChangeEquipEMCoCol] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMChangeEquipEMCoCol] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMChangeEquipEMCoCol] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMChangeEquipEMCoCol] TO [Viewpoint]
GO
