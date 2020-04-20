SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMChangeBatchEquipEMCoCol]
as
/*********************************************
*	Created By:  TRL 08/20/08 Issue 126196
*	Modified By:  TRL 10/21/08 Issue 126196
*
*   Usage:  Used to get all the 'bEquip' columns EMCo columns
*   and Batch Co Columns the selection Viewpoint database for 
*	all Viewpoint Batch Tables. Out used to check if equipment
*   exists in an open batch
*   These record are used by the EM Equipment Change program 
*   
***********************************************/
--Match Equipmet to EMCo
Select  e.ViewpointDB,e.VPTableName,e.VPColumnName,VPEMCo= c.COLUMN_NAME
FROM dbo.EMChangeEquipCol e with(nolock)
Inner JOIN INFORMATION_SCHEMA.COLUMNS c (NOLOCK) ON c.TABLE_NAME = e.VPTableName and c.TABLE_CATALOG=e.ViewpointDB
WHERE e.VPColType = 'Standard' and e.VPTableType  In ('Audit','Dist') AND c.DOMAIN_NAME IN('bCompany')
and lower(c.COLUMN_NAME)='emco'and lower(Left(e.VPColumnName,3))<>'old'

Union all

--Match OldEquipment to OldEMCo
Select  e.ViewpointDB,e.VPTableName,e.VPColumnName,VPEMCo= c.COLUMN_NAME
FROM dbo.EMChangeEquipCol e with(nolock)
Inner JOIN INFORMATION_SCHEMA.COLUMNS c (NOLOCK) ON c.TABLE_NAME = e.VPTableName and c.TABLE_CATALOG=e.ViewpointDB
WHERE e.VPColType = 'Standard' and e.VPTableType  In ('Audit','Dist') AND c.DOMAIN_NAME IN('bCompany') 
and lower(c.COLUMN_NAME)='oldemco'and lower(Left(e.VPColumnName,3))='old'

Union All
--As of 10/5/08 POIB is the only table with Old Equipment/Component Columns and no OldEMCo Column
Select  e.ViewpointDB,e.VPTableName,e.VPColumnName,VPEMCo= c.COLUMN_NAME
FROM dbo.EMChangeEquipCol e with(nolock)
Inner JOIN INFORMATION_SCHEMA.COLUMNS c (NOLOCK) ON c.TABLE_NAME = e.VPTableName and c.TABLE_CATALOG=e.ViewpointDB
WHERE e.VPColType = 'Standard' and e.VPTableType  In ('Audit','Dist') AND c.DOMAIN_NAME IN('bCompany') 
and lower(c.COLUMN_NAME)='emco'and lower(Left(e.VPColumnName,3))='old'
and e.VPTableName = 'POIB'

Union All

--Match Equipment UserMemoFields to Batch Co
Select  e.ViewpointDB,e.VPTableName,e.VPColumnName,VPEMCo= c.COLUMN_NAME
FROM dbo.EMChangeEquipCol e with(nolock)
Inner JOIN INFORMATION_SCHEMA.COLUMNS c (NOLOCK) ON c.TABLE_NAME = e.VPTableName and c.TABLE_CATALOG=e.ViewpointDB
WHERE e.VPColType = 'Custom Field' and e.VPTableType  In ('Audit','Dist') AND c.DOMAIN_NAME IN('bCompany') 
and lower(c.COLUMN_NAME) ='co'

Union All

-- EM Tables
Select e.ViewpointDB,e.VPTableName,e.VPColumnName,VPEMCo=c.COLUMN_NAME
FROM dbo.EMChangeEquipCol e with(nolock)
Inner JOIN INFORMATION_SCHEMA.COLUMNS c (NOLOCK) ON c.TABLE_CATALOG=e.ViewpointDB and c.TABLE_NAME = e.VPTableName
WHERE e.VPColType In ('Standard','Custom Field') and e.VPTableType In ('Audit','Dist')
AND c.DOMAIN_NAME IN('bCompany') and lower(c.COLUMN_NAME)In('co') and Left(e.VPTableName,2) = 'EM'


GO
GRANT SELECT ON  [dbo].[EMChangeBatchEquipEMCoCol] TO [public]
GRANT INSERT ON  [dbo].[EMChangeBatchEquipEMCoCol] TO [public]
GRANT DELETE ON  [dbo].[EMChangeBatchEquipEMCoCol] TO [public]
GRANT UPDATE ON  [dbo].[EMChangeBatchEquipEMCoCol] TO [public]
GO
