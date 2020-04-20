SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[viDim_EMCompany] AS

/**************************************************
 * ALTERd: TMS 2009-06-03
 * Modified:      
 * Usage:  Dimension View for EM Companies
 *		   for use in SSAS Cubes. 
 *
 **************************************************/

SELECT 
	bEMCO.KeyID	AS EMCoID	
,	bEMCO.EMCo	AS Company
,	bHQCO.Name	AS CompanyName
,	Cast(bEMCO.EMCo AS varchar) + '  ' + bHQCO.Name As CompanyAndName

FROM 	bEMCO 
left join bHQCO 
		on bEMCO.EMCo = bHQCO.HQCo
Inner Join vDDBICompanies on vDDBICompanies.Co=bEMCO.EMCo


UNION ALL 

-- Unassigned record
SELECT 
	0,	0		,'Unassigned'	,null


GO
GRANT SELECT ON  [dbo].[viDim_EMCompany] TO [public]
GRANT INSERT ON  [dbo].[viDim_EMCompany] TO [public]
GRANT DELETE ON  [dbo].[viDim_EMCompany] TO [public]
GRANT UPDATE ON  [dbo].[viDim_EMCompany] TO [public]
GO
