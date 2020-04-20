SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE View [dbo].[viFact_HRBenefitsExpiring]

/**************************************************
 * Alterd: CWW 5/6/09
 * Modified:      
 * Usage:  Fact View returning benefits
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
--Extract specific accident information 
--How many days of eligibility does a employee has left.  This calculation is the 
--difference of the day Cobra benefits starting date or the current date(Which ever is greater)and the the ending date.
With HRBenefits
as

(Select	 
	 bHREB.HRCo
	,bHREB.HRRef
	,bHREB.BenefitCode
	,bHREB.DependentSeq
	,bHREB.EndDate
	,BenefitsExpiringInDays = DateDiff(d,'1/1/1950',isnull(bHREB.EndDate,'1/1/1950'))

From bHREB With (NoLock)
Inner Join vDDBICompanies With (NoLock) ON vDDBICompanies.Co=bHREB.HRCo 
)


--Build the Keys
select 
	bHRCO.KeyID as HRCoID
	,isnull(bHRRM.KeyID,0) as HRRefID
	,isnull(bHRBC.KeyID,0) as BenefitCodeID
	,isnull(bPRCO.KeyID,0) as PRCoID
	,isnull(bPRGR.KeyID,0) as PRGroupID
	,isnull(bHRPC.KeyID,0) as PositionCodeID
	,HRBenefits.DependentSeq
	,HRBenefits.BenefitsExpiringInDays as ExpireDateID
	,BenefitsExpiringCount = 1
From HRBenefits Inner Join bHRCO With (NoLock)
	ON HRBenefits.HRCo = bHRCO.HRCo 
left outer join bHRRM With (NoLOck)
	ON HRBenefits.HRCo = bHRRM.HRCo and HRBenefits.HRRef = bHRRM.HRRef 
left outer join bHRBC With (NoLock)
	ON HRBenefits.HRCo = bHRBC.HRCo and HRBenefits.BenefitCode = bHRBC.BenefitCode
left outer Join bPRCO With (NoLock)
	ON bHRRM.PRCo= bPRCO.PRCo
Left Outer Join bPRGR With (NoLock)
	ON bHRRM.PRCo= bPRGR.PRCo and bHRRM.PRGroup = bPRGR.PRGroup
left Outer Join bHRPC With (NoLock)
	ON HRBenefits.HRCo = bHRPC.HRCo and bHRRM.PositionCode = bHRPC.PositionCode 
Inner Join vDDBICompanies With (NoLock) ON vDDBICompanies.Co=HRBenefits.HRCo

GO
GRANT SELECT ON  [dbo].[viFact_HRBenefitsExpiring] TO [public]
GRANT INSERT ON  [dbo].[viFact_HRBenefitsExpiring] TO [public]
GRANT DELETE ON  [dbo].[viFact_HRBenefitsExpiring] TO [public]
GRANT UPDATE ON  [dbo].[viFact_HRBenefitsExpiring] TO [public]
GO
