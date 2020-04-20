SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE View [dbo].[viFact_HRPhysicalsReviewsExpiring]

/**************************************************
 * Alterd: CWW 5/6/09
 * Modified:      
 * Usage:  Fact View returning physicals and reviews
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

With HRReviews
as
(
Select	 
	 bHRRM.HRCo
	,bHRRM.HRRef
	,bHRRM.PositionCode
	,Max(PhysExpireDate)as ExpiredDate 
	,IsPhysicalExpiringCount = 1
	,IsReviewExpiringCount = 0
	
From bHRRM With (NoLock)
Inner Join vDDBICompanies With (NoLock) ON vDDBICompanies.Co=bHRRM.HRCo 
Group by  bHRRM.HRCo,bHRRM.HRRef,bHRRM.PositionCode

Union All

Select	 
	 bHRER.HRCo
	,bHRER.HRRef
	,null as PositionCode
	,Max(NextReviewDate)as ExpiredDate
	,IsPhysicalExpiringCount = 0
	,IsReviewExpiringCount = 1
From bHRER With (NoLock)
Inner Join vDDBICompanies With (NoLock) ON vDDBICompanies.Co=bHRER.HRCo 
Group by  bHRER.HRCo,bHRER.HRRef
)



--Build the Keys
select 
	bHRCO.KeyID as HRCoID
	,isnull(bHRRM.KeyID,0) as HRRefID
	,isnull(bPRCO.KeyID,0) as PRCoID
	,isnull(bPRGR.KeyID,0) as PRGroupID
	,isnull(bHRPC.KeyID,0) as PositionCodeID
	,HRReviews.IsPhysicalExpiringCount
	,HRReviews.IsReviewExpiringCount
	,ExpireDateID =DateDiff(d,'1/1/1950',isnull(HRReviews.ExpiredDate,'1/1/1950'))
From HRReviews Left outer Join bHRCO With (NoLock)
	ON HRReviews.HRCo = bHRCO.HRCo 
left outer join bHRRM With (NoLOck)
	ON HRReviews.HRCo = bHRRM.HRCo and HRReviews.HRRef = bHRRM.HRRef 
left Outer Join bHRPC With (NoLock)
	ON HRReviews.HRCo = bHRPC.HRCo and HRReviews.PositionCode = bHRPC.PositionCode 
left outer Join bPRCO With (NoLock)
	ON bHRRM.PRCo= bPRCO.PRCo
Left Outer Join bPRGR With (NoLock)
	ON bHRRM.PRCo= bPRGR.PRCo and bHRRM.PRGroup = bPRGR.PRGroup
Inner Join vDDBICompanies With (NoLock) ON vDDBICompanies.Co=HRReviews.HRCo

GO
GRANT SELECT ON  [dbo].[viFact_HRPhysicalsReviewsExpiring] TO [public]
GRANT INSERT ON  [dbo].[viFact_HRPhysicalsReviewsExpiring] TO [public]
GRANT DELETE ON  [dbo].[viFact_HRPhysicalsReviewsExpiring] TO [public]
GRANT UPDATE ON  [dbo].[viFact_HRPhysicalsReviewsExpiring] TO [public]
GO
