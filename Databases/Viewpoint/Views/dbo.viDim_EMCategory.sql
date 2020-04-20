SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[viDim_EMCategory] AS

/**************************************************
 * ALTERED:		TMS 2009-06-03
 * Modified:	HH 2010-11-04	#135047	Join bEMCO for company security
 *
 * Usage:  Dimension View for EM Categories 
 *		   for use in SSAS Cubes. 
 *
 **************************************************/

SELECT 
	bEMCO.KeyID AS EMCoID
,	Category.KeyID		AS CategoryID
,	Category.Category
,	Category.Description AS CategoryDescription
,	Cast(Category.Category AS varchar)  + '  ' + Category.Description AS CategoryAndDescription

FROM bEMCM Category With (NoLock)
Inner Join bEMCO With (NoLock) on bEMCO.EMCo = Category.EMCo
Inner Join vDDBICompanies With (NoLock) 
	ON vDDBICompanies.Co=Category.EMCo 


UNION ALL 

-- Unassigned record
SELECT 
	 null	,0		,null	,'Unassigned'	,null


GO
GRANT SELECT ON  [dbo].[viDim_EMCategory] TO [public]
GRANT INSERT ON  [dbo].[viDim_EMCategory] TO [public]
GRANT DELETE ON  [dbo].[viDim_EMCategory] TO [public]
GRANT UPDATE ON  [dbo].[viDim_EMCategory] TO [public]
GO
