SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE View [dbo].[viDim_PMCompany]
as 



Select   bPMCO.KeyID as PMCoID
        ,bPMCO.PMCo
        ,bHQCO.Name
From bPMCO
Join bHQCO on bHQCO.HQCo=bPMCO.PMCo
Join vDDBICompanies on vDDBICompanies.Co=bPMCO.PMCo

union all

Select 0,
	   Null,
	   Null

GO
GRANT SELECT ON  [dbo].[viDim_PMCompany] TO [public]
GRANT INSERT ON  [dbo].[viDim_PMCompany] TO [public]
GRANT DELETE ON  [dbo].[viDim_PMCompany] TO [public]
GRANT UPDATE ON  [dbo].[viDim_PMCompany] TO [public]
GRANT SELECT ON  [dbo].[viDim_PMCompany] TO [Viewpoint]
GRANT INSERT ON  [dbo].[viDim_PMCompany] TO [Viewpoint]
GRANT DELETE ON  [dbo].[viDim_PMCompany] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[viDim_PMCompany] TO [Viewpoint]
GO
