SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[viDim_EMComponent] AS

/**************************************************
 * ALTERED:		TMS	2009-06-03
 * Modified:	HH	2010-11-04	#135047	Join bEMCO for company security
 *
 * Usage:  Dimension View for EM Components 
 *		   for use in SSAS Cubes. 
 *
 **************************************************/

SELECT 
	Equipment.KeyID		AS EquipmentID
,	bEMCO.KeyID AS EMCoID	
,	Equipment
,	Description AS EquipmentDescription
,	isnull(Equipment, '') + '  ' + isnull(Description, '') as EquipmentAndDescription

FROM 
	bEMEM Equipment With (NoLock)
Inner Join bEMCO With (NoLock) on bEMCO.EMCo = Equipment.EMCo 
Inner Join vDDBICompanies With (NoLock) ON vDDBICompanies.Co=Equipment.EMCo 
WHERE 
	Type = 'C'

UNION ALL 

-- Unassigned record
SELECT 
	0		
	,null		
	,null	
	,'Unassigned'
	,null


GO
GRANT SELECT ON  [dbo].[viDim_EMComponent] TO [public]
GRANT INSERT ON  [dbo].[viDim_EMComponent] TO [public]
GRANT DELETE ON  [dbo].[viDim_EMComponent] TO [public]
GRANT UPDATE ON  [dbo].[viDim_EMComponent] TO [public]
GRANT SELECT ON  [dbo].[viDim_EMComponent] TO [Viewpoint]
GRANT INSERT ON  [dbo].[viDim_EMComponent] TO [Viewpoint]
GRANT DELETE ON  [dbo].[viDim_EMComponent] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[viDim_EMComponent] TO [Viewpoint]
GO
