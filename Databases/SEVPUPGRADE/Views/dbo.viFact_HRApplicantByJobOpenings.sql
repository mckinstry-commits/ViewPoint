SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE View [dbo].[viFact_HRApplicantByJobOpenings]

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


With HRApplicants
as

(Select	 
	 bHRAP.HRCo
	,bHRAP.HRRef
	,bHRAP.PositionCode



From bHRAP With (NoLock)
Inner Join vDDBICompanies With (NoLock) ON vDDBICompanies.Co=bHRAP.HRCo 
)


--Build the Keys
select 
	bHRCO.KeyID as HRCoID
	,isnull(bHRRM.KeyID,0) as HRRefID
	,isnull(bHRPC.KeyID,0) as PositionCodeID

From HRApplicants Inner Join bHRCO With (NoLock)
	ON HRApplicants.HRCo = bHRCO.HRCo 
left outer join bHRRM With (NoLOck)
	ON HRApplicants.HRCo = bHRRM.HRCo and HRApplicants.HRRef = bHRRM.HRRef 
left outer join bHRPC With (NoLock)
	ON HRApplicants.HRCo = bHRPC.HRCo and HRApplicants.PositionCode = bHRPC.PositionCode 
Inner Join vDDBICompanies With (NoLock) ON vDDBICompanies.Co = HRApplicants.HRCo

GO
GRANT SELECT ON  [dbo].[viFact_HRApplicantByJobOpenings] TO [public]
GRANT INSERT ON  [dbo].[viFact_HRApplicantByJobOpenings] TO [public]
GRANT DELETE ON  [dbo].[viFact_HRApplicantByJobOpenings] TO [public]
GRANT UPDATE ON  [dbo].[viFact_HRApplicantByJobOpenings] TO [public]
GO
