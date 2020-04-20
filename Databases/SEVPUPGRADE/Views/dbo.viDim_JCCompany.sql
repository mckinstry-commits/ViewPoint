SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE View [dbo].[viDim_JCCompany]

/**************************************************
 * Alterd: DH 3/17/08
 * Modified:      
 * Usage:  Dimension View of JC Company Master for use in SSAS Cubes. 
 *
 *
 ********************************************************/

as

Select   bJCCO.KeyID as JCCoID
        ,bJCCO.JCCo
        ,bHQCO.Name
From bJCCO
Join bHQCO on bHQCO.HQCo=bJCCO.JCCo
Join vDDBICompanies on vDDBICompanies.Co=bJCCO.JCCo

Union All

Select 0,
	   Null,
	   'Unassigned'

GO
GRANT SELECT ON  [dbo].[viDim_JCCompany] TO [public]
GRANT INSERT ON  [dbo].[viDim_JCCompany] TO [public]
GRANT DELETE ON  [dbo].[viDim_JCCompany] TO [public]
GRANT UPDATE ON  [dbo].[viDim_JCCompany] TO [public]
GO
