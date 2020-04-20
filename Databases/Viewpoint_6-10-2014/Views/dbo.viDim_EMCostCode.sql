SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[viDim_EMCostCode] AS

/**************************************************
 * ALTERd: TMS 2009-06-03
 * Modified:      
 * Usage:  Dimension View for EM Cost Codes 
 *		   for use in SSAS Cubes. 
 *
 **************************************************/

SELECT 
	KeyID AS CostCodeID
,	CostCode
,	Description As CostCodeDescription
,	CostCode + '  ' + Description as CostCodeAndDescription

FROM 
	bEMCC CostCode

UNION ALL 

-- Unassigned record
SELECT 
	0		,null		,'Unassigned'	,null

GO
GRANT SELECT ON  [dbo].[viDim_EMCostCode] TO [public]
GRANT INSERT ON  [dbo].[viDim_EMCostCode] TO [public]
GRANT DELETE ON  [dbo].[viDim_EMCostCode] TO [public]
GRANT UPDATE ON  [dbo].[viDim_EMCostCode] TO [public]
GRANT SELECT ON  [dbo].[viDim_EMCostCode] TO [Viewpoint]
GRANT INSERT ON  [dbo].[viDim_EMCostCode] TO [Viewpoint]
GRANT DELETE ON  [dbo].[viDim_EMCostCode] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[viDim_EMCostCode] TO [Viewpoint]
GO
