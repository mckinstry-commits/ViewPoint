SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMChangeBatchCol]
as
/*********************************************
*	Created By:  TRL 08/20/08 Issue 126196
*	Modified By:
*
*   Usage:  Used to get all the 'bEquip' columns EMCo columns
*   and Batch Co Columns the selection Viewpoint database for 
*	all Viewpoint Batch Tables. Out used to check if equipment
*   exists in an open batch
*   These record are used by the EM Equipment Change program 
*   
***********************************************/
--Batch Audit Entry Tables
Select e.ViewpointDB,e.VPTableName,e.VPColumnName,VPEMCo=null,VPCo=c.COLUMN_NAME
FROM dbo.EMChangeEquipCol e with(nolock)
Inner JOIN INFORMATION_SCHEMA.COLUMNS c (NOLOCK) ON c.TABLE_CATALOG=e.ViewpointDB and c.TABLE_NAME = e.VPTableName
WHERE e.VPColType In ('Standard','Custom Field') and e.VPTableType In('Audit','Dist')
AND c.DOMAIN_NAME IN('bCompany') and lower(c.COLUMN_NAME)In('co')
and e.VPTableName Not In ('PRRB','PRJC','PREM')

union all 
--Batch Distribution Tables, records can be add during batch validation
--or during Batch Entry
Select e.ViewpointDB,e.VPTableName,e.VPColumnName,VPEMCo=null,
VPCo=case Left(e.VPTableName,2)
	when 'PR' then 'PRCo'
	when 'PO' then 'POCo'
	when 'MS' then 'MSCo'
	when 'EM' then 'EMCo'
	when 'AR' then 'ARCo'
	when 'AP' then 'APCo'
end
FROM dbo.EMChangeEquipCol e with(nolock)
Inner JOIN INFORMATION_SCHEMA.COLUMNS c (NOLOCK) ON c.TABLE_CATALOG=e.ViewpointDB and c.TABLE_NAME = e.VPTableName
WHERE e.VPColType In ('Standard','Custom Field') and e.VPTableType In('Dist')
AND c.DOMAIN_NAME IN('bCompany') and lower(c.COLUMN_NAME)In('emco')
and e.VPTableName Not In ('PRRB','PRJC','PREM','PRER')


GO
GRANT SELECT ON  [dbo].[EMChangeBatchCol] TO [public]
GRANT INSERT ON  [dbo].[EMChangeBatchCol] TO [public]
GRANT DELETE ON  [dbo].[EMChangeBatchCol] TO [public]
GRANT UPDATE ON  [dbo].[EMChangeBatchCol] TO [public]
GRANT SELECT ON  [dbo].[EMChangeBatchCol] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMChangeBatchCol] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMChangeBatchCol] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMChangeBatchCol] TO [Viewpoint]
GO
