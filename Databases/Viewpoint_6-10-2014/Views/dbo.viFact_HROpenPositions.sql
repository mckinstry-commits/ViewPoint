SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE View [dbo].[viFact_HROpenPositions]

/**************************************************
 * Alterd: CWW 5/6/09
 * Modified:      
 * Usage:  Fact View returning job and applicant 
 *         data for use as Measures in SSAS Cubes. 
 *
 * The granularity will be at the resource level 
 *
 * Maintenance Log
 * Date		Issue#		UpdateBy	Description
 * 05/06/09 129902     C Wirtz		New
 *
 ********************************************************/

AS


With HRPosition
as

(
select 
	'Applicant' as RecType
	,bHRPC.HRCo
	,bHRPC.PositionCode
	,bHRAP.HRRef
	,bHRPC.ClosingDate
	,IsTotalPositionOpenedCount = 1
	,IsTotalApplicantCount = Case When (bHRAP.HRRef is not null) then 1 Else 0 End
	,EventDate = bHRPC.ClosingDate
from bHRPC With (NoLock)
Left Outer Join bHRCO With (NoLock)
	ON bHRPC.HRCo = bHRCO.HRCo 
Left Outer Join bHRAP With (NoLock)
	ON bHRAP.HRCo = bHRPC.HRCo and bHRAP.PositionCode = bHRPC.PositionCode
Inner Join vDDBICompanies With (NoLock) ON vDDBICompanies.Co=bHRPC.HRCo 
where 
isnull(bHRPC.OpenJobs,0) > 0  
		and (bHRPC.ClosingDate is null or bHRPC.ClosingDate > GetDate()) )


--Build the Keys
select 
	bHRCO.KeyID as HRCoID
--,HRPosition.HRRef
	,isnull(bHRRM.KeyID,0) as HRRefID
	,isnull(bPRCO.KeyID,0) as PRCoID
	,isnull(bPRGR.KeyID,0) as PRGroupID
	,isnull(bHRPC.KeyID,0) as PositionCodeID
	,HRPosition.IsTotalPositionOpenedCount
	,HRPosition.IsTotalApplicantCount
	,PositionDateClosingID = 	datediff(dd,'1/1/1950',isnull(HRPosition.EventDate,'1/1/1950')) 


From HRPosition 
Left Outer Join bHRRM With (NoLock)
	ON HRPosition.HRCo = bHRRM.HRCo and HRPosition.HRRef = bHRRM.HRRef
left Outer Join bHRPC With (NoLock)
	ON HRPosition.HRCo = bHRPC.HRCo and HRPosition.PositionCode = bHRPC.PositionCode 
left outer Join bPRCO With (NoLock)
	ON bHRRM.PRCo= bPRCO.PRCo
Left Outer Join bPRGR With (NoLock)
	ON bHRRM.PRCo= bPRGR.PRCo and bHRRM.PRGroup = bPRGR.PRGroup
Inner Join bHRCO With (NoLock)
	ON HRPosition.HRCo = bHRCO.HRCo
Inner Join vDDBICompanies With (NoLock) ON vDDBICompanies.Co=HRPosition.HRCo

GO
GRANT SELECT ON  [dbo].[viFact_HROpenPositions] TO [public]
GRANT INSERT ON  [dbo].[viFact_HROpenPositions] TO [public]
GRANT DELETE ON  [dbo].[viFact_HROpenPositions] TO [public]
GRANT UPDATE ON  [dbo].[viFact_HROpenPositions] TO [public]
GRANT SELECT ON  [dbo].[viFact_HROpenPositions] TO [Viewpoint]
GRANT INSERT ON  [dbo].[viFact_HROpenPositions] TO [Viewpoint]
GRANT DELETE ON  [dbo].[viFact_HROpenPositions] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[viFact_HROpenPositions] TO [Viewpoint]
GO
