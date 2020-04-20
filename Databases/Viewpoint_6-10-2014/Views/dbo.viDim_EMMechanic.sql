SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[viDim_EMMechanic] AS

/**************************************************
 * ALTERED:		TMS 2009-06-03
 * Modified:	HH 2010-11-04	#135047	Join bEMCO for company security
 *
 * Usage:   Dimension View to list all mechanics that
 *		    have worked on a Work Order
 *			for use in SSAS Cubes. 
 *
 **************************************************/

SELECT DISTINCT
	Employee.KeyID				AS MechanicID
,	bEMCO.KeyID					AS EMCoID	
,	Mechanic
,	FirstName + ' ' + LastName	AS MechanicName

FROM bEMWH WorkOrder With (NoLock)
INNER JOIN	bPREH Employee With (NoLock)
		ON Employee.PRCo = WorkOrder.PRCo
		AND Employee.Employee = WorkOrder.Mechanic
Inner Join bEMCO With (NoLock) on bEMCO.EMCo = WorkOrder.EMCo 
Inner Join vDDBICompanies With (NoLock) ON vDDBICompanies.Co=WorkOrder.EMCo 



UNION ALL 

-- Unassigned record
SELECT 
	 0		,null		,null		,'Unassigned'



GO
GRANT SELECT ON  [dbo].[viDim_EMMechanic] TO [public]
GRANT INSERT ON  [dbo].[viDim_EMMechanic] TO [public]
GRANT DELETE ON  [dbo].[viDim_EMMechanic] TO [public]
GRANT UPDATE ON  [dbo].[viDim_EMMechanic] TO [public]
GRANT SELECT ON  [dbo].[viDim_EMMechanic] TO [Viewpoint]
GRANT INSERT ON  [dbo].[viDim_EMMechanic] TO [Viewpoint]
GRANT DELETE ON  [dbo].[viDim_EMMechanic] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[viDim_EMMechanic] TO [Viewpoint]
GO
