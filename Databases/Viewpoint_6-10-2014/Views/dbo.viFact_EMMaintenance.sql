SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[viFact_EMMaintenance] AS

/**************************************************
 * ALTERd: TMS 2009-06-03
 * Modified:      
 * Usage:  Fact View for EM Maintenance Data
 *		   for use in SSAS Cubes. 
 *
 **************************************************/

SELECT EMCo, Equipment, CostCode FROM bEMSI With (NoLock)
Inner Join vDDBICompanies With (NoLock) ON vDDBICompanies.Co=bEMSI.EMCo

GO
GRANT SELECT ON  [dbo].[viFact_EMMaintenance] TO [public]
GRANT INSERT ON  [dbo].[viFact_EMMaintenance] TO [public]
GRANT DELETE ON  [dbo].[viFact_EMMaintenance] TO [public]
GRANT UPDATE ON  [dbo].[viFact_EMMaintenance] TO [public]
GRANT SELECT ON  [dbo].[viFact_EMMaintenance] TO [Viewpoint]
GRANT INSERT ON  [dbo].[viFact_EMMaintenance] TO [Viewpoint]
GRANT DELETE ON  [dbo].[viFact_EMMaintenance] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[viFact_EMMaintenance] TO [Viewpoint]
GO
