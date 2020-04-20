SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[viDim_EMCostType] AS

/**************************************************
 * ALTERd: TMS 2009-06-03
 * Modified:      
 * Usage:  Dimension View for EM Cost Types 
 *		   for use in SSAS Cubes. 
 *
 **************************************************/

SELECT 
	KeyID AS CostTypeID
,	CostType
,	Description as CostTypeDescription
,	Cast(CostType AS varchar) + '  ' + Description AS CostTypeAndDescription

FROM 
	bEMCT CostType

UNION ALL 

-- Unassigned record
SELECT 
	0		,null		,'Unassigned'	,null

GO
GRANT SELECT ON  [dbo].[viDim_EMCostType] TO [public]
GRANT INSERT ON  [dbo].[viDim_EMCostType] TO [public]
GRANT DELETE ON  [dbo].[viDim_EMCostType] TO [public]
GRANT UPDATE ON  [dbo].[viDim_EMCostType] TO [public]
GO
