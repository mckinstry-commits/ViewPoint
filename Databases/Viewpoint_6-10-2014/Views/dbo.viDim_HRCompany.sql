SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE View [dbo].[viDim_HRCompany]

/********************************************************
 *   
 * Usage:  Humane Resource Company dimension 
 *         to be used in SSAS Cubes. 
 *
 * Maintenance Log
 * Date		Issue#		UpdateBy	Description
 * 05/12/09 129902     C Wirtz		New
 *
 ********************************************************/

AS

Select   bHRCO.KeyID as HRCoID
        ,bHRCO.HRCo
        ,bHQCO.Name  as CompanyName
From bHRCO  With (NoLock)
Inner Join bHQCO With(NoLock) ON bHRCO.HRCo=bHQCO.HQCo
Join vDDBICompanies on vDDBICompanies.Co=bHRCO.HRCo

-- Add null record for missing record identifiers
Union All

Select 0,
	   Null,
	   'Unassigned'

GO
GRANT SELECT ON  [dbo].[viDim_HRCompany] TO [public]
GRANT INSERT ON  [dbo].[viDim_HRCompany] TO [public]
GRANT DELETE ON  [dbo].[viDim_HRCompany] TO [public]
GRANT UPDATE ON  [dbo].[viDim_HRCompany] TO [public]
GRANT SELECT ON  [dbo].[viDim_HRCompany] TO [Viewpoint]
GRANT INSERT ON  [dbo].[viDim_HRCompany] TO [Viewpoint]
GRANT DELETE ON  [dbo].[viDim_HRCompany] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[viDim_HRCompany] TO [Viewpoint]
GO
