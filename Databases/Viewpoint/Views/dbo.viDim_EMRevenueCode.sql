SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[viDim_EMRevenueCode] AS

/**************************************************
 * ALTERd: TMS 2009-06-03
 * Modified:      
 * Usage:  Dimension View for Revenue Codes
 *		   for use in SSAS Cubes. 
 *
 **************************************************/

SELECT 
	KeyID		AS RevenueCodeID
,	RevCode		AS RevenueCode
,	Description AS RevenueCodeDescription

FROM 
	bEMRC RevenueCode With (NoLock)

UNION ALL 

-- Unassigned record
SELECT 
	0		,null		,'Unassigned'

GO
GRANT SELECT ON  [dbo].[viDim_EMRevenueCode] TO [public]
GRANT INSERT ON  [dbo].[viDim_EMRevenueCode] TO [public]
GRANT DELETE ON  [dbo].[viDim_EMRevenueCode] TO [public]
GRANT UPDATE ON  [dbo].[viDim_EMRevenueCode] TO [public]
GO
