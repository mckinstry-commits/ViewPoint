SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE View [dbo].[viDim_PRCompany]

/********************************************************
 *   
 * Usage:  Payroll Company dimension to be used in SSAS Cubes. 
 *
 * Maintenance Log
 * Date		Issue#		UpdateBy	Description
 * 05/12/09 129902     C Wirtz		New
 *
 ********************************************************/

AS

Select   bPRCO.KeyID as PRCoID
        ,bPRCO.PRCo
        ,bHQCO.Name  as CompanyName
From bPRCO  With (NoLock)
Inner Join bHQCO With(NoLock) ON bPRCO.PRCo=bHQCO.HQCo
Join vDDBICompanies on vDDBICompanies.Co=bPRCO.PRCo

-- Add null record
Union All

Select 0,
	   Null,
	   'Unassigned'

GO
GRANT SELECT ON  [dbo].[viDim_PRCompany] TO [public]
GRANT INSERT ON  [dbo].[viDim_PRCompany] TO [public]
GRANT DELETE ON  [dbo].[viDim_PRCompany] TO [public]
GRANT UPDATE ON  [dbo].[viDim_PRCompany] TO [public]
GRANT SELECT ON  [dbo].[viDim_PRCompany] TO [Viewpoint]
GRANT INSERT ON  [dbo].[viDim_PRCompany] TO [Viewpoint]
GRANT DELETE ON  [dbo].[viDim_PRCompany] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[viDim_PRCompany] TO [Viewpoint]
GO
