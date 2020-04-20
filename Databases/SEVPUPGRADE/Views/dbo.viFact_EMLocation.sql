SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[viFact_EMLocation] AS

/**************************************************
 * ALTERd: TMS 2009-06-03
 * Modified:      
 * Usage:  Fact View for EM Location Data
 *		   for use in SSAS Cubes. 
 *
 **************************************************/

SELECT EMCo, EMLoc FROM bEMLM With (NoLock)
Inner Join vDDBICompanies With (NoLock) ON vDDBICompanies.Co=bEMLM.EMCo

GO
GRANT SELECT ON  [dbo].[viFact_EMLocation] TO [public]
GRANT INSERT ON  [dbo].[viFact_EMLocation] TO [public]
GRANT DELETE ON  [dbo].[viFact_EMLocation] TO [public]
GRANT UPDATE ON  [dbo].[viFact_EMLocation] TO [public]
GO
