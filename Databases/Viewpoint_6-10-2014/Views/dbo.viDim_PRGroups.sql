SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE View [dbo].[viDim_PRGroups]

/********************************************************
 *   
 * Usage:  Payroll Groups dimension 
 *         to be used in SSAS Cubes. 
 *
 * Maintenance Log
 * Date		Issue#		UpdateBy	Description
 * 05/12/09 129902     C Wirtz		New
 *
 ********************************************************/

AS

Select   bPRGR.KeyID as PRGroupID
		,bPRGR.PRGroup
		,bPRGR.Description as PRGroupDescription
From bPRGR  With (NoLock)
Join vDDBICompanies With (NoLock)on vDDBICompanies.Co=bPRGR.PRCo

Union All

select   0 as PRGroupID
		,Null as PRGroup
        ,'Unassigned' as PRGroupDescription

GO
GRANT SELECT ON  [dbo].[viDim_PRGroups] TO [public]
GRANT INSERT ON  [dbo].[viDim_PRGroups] TO [public]
GRANT DELETE ON  [dbo].[viDim_PRGroups] TO [public]
GRANT UPDATE ON  [dbo].[viDim_PRGroups] TO [public]
GRANT SELECT ON  [dbo].[viDim_PRGroups] TO [Viewpoint]
GRANT INSERT ON  [dbo].[viDim_PRGroups] TO [Viewpoint]
GRANT DELETE ON  [dbo].[viDim_PRGroups] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[viDim_PRGroups] TO [Viewpoint]
GO
