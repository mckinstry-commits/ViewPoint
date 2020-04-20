SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMChangeBatchList]
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
select a.ViewpointDB,a.VPTableName,a.VPColumnName,a.VPEMCo,Co=Min(b.VPCo)
From dbo.EMChangeBatchEquipEMCoCol a
Inner Join dbo.EMChangeBatchCol b on a.ViewpointDB=b.ViewpointDB and a.VPTableName=b.VPTableName
and a.VPColumnName=b.VPColumnName
Group by a.ViewpointDB,a.VPTableName,a.VPColumnName,a.VPEMCo



GO
GRANT SELECT ON  [dbo].[EMChangeBatchList] TO [public]
GRANT INSERT ON  [dbo].[EMChangeBatchList] TO [public]
GRANT DELETE ON  [dbo].[EMChangeBatchList] TO [public]
GRANT UPDATE ON  [dbo].[EMChangeBatchList] TO [public]
GO
