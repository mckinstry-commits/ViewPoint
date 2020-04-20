SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE View [dbo].[viDim_PRCrews]
/**************************************************
 * Alterd: DH 6/19/08
 * Modified:      
 * Usage:  Dimension View from PR Crews for use in SSAS Cubes. 
 *         
 *
 ********************************************************/

as

Select	
		bPRCR.KeyID as PRCrewID,
		bPRCR.Crew+' '+isnull(Description,'') as CrewandDescription
From bPRCR

union all

/*Default 0 ID that links back to Fact Views for non-PR transactions (or PR transactions without Crews*/
Select	0 as KeyID,
		'' as CrewandDescription



GO
GRANT SELECT ON  [dbo].[viDim_PRCrews] TO [public]
GRANT INSERT ON  [dbo].[viDim_PRCrews] TO [public]
GRANT DELETE ON  [dbo].[viDim_PRCrews] TO [public]
GRANT UPDATE ON  [dbo].[viDim_PRCrews] TO [public]
GO
