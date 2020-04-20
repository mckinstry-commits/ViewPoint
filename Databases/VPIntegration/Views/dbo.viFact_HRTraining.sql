SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE View [dbo].[viFact_HRTraining]

/**************************************************
 * Alterd: CWW 5/6/09
 * Modified:      
 * Usage:  Fact View returning training and skill
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

With HRTraining
as
(select 
	'TrainingComplete' as RecType
	,bHRET.HRCo
	,bHRET.HRRef
	,bHRET.Seq
	,bHRET.TrainCode
	,bHRCM.KeyID as CodeMasterID
	,IsTrainingCompleteCount = 1
	,IsTrainingCompleteSafetyCount = Case when bHRCM.SafetyYN = 'Y' Then 1 Else null End
	,IsTrainingExpiringCount =null
	,IsTrainingExpiringSafetyCount =null
	,IsSkillCertifiedCount = Null
	,IsSkillCertifiedSafetyCount = null
	,IsSkillExpiringCount = null
	,IsSkillExpiringSafetyCount = null
	,EventDate = bHRET.CompleteDate 
	,TestDate = bHRET.CompleteDate


from bHRET
left outer join bHRCM With (NoLock)
	ON bHRET.HRCo = bHRCM.HRCo and bHRET.TrainCode = bHRCM.Code and bHRET.Type = bHRCM.Type
Inner Join vDDBICompanies With (NoLock) ON vDDBICompanies.Co=bHRET.HRCo 
where bHRET.CompleteDate is not null

Union All

select 
	'TrainingExpiring' as RecType
	,bHRET.HRCo
	,bHRET.HRRef
	,bHRET.Seq
	,bHRET.TrainCode
	,bHRCM.KeyID as CodeMasterID
	,IsTrainingCompleteCount = null
	,IsTrainingCompleteSafetyCount = null
	,IsTrainingExpiringCount =1
	,IsTrainingExpiringSafetyCount =Case when bHRCM.SafetyYN = 'Y' Then 1 Else null End
	,IsSkillCertifiedCount = Null
	,IsSkillCertifiedSafetyCount = null
	,IsSkillExpiringCount = null
	,IsSkillExpiringSafetyCount = null
	,EventDate = DateAdd(m,bHRCM.CertPeriod,bHRET.CompleteDate) 

	,TestDate = bHRET.CompleteDate


from bHRET
left outer join bHRCM With (NoLock)
	ON bHRET.HRCo = bHRCM.HRCo and bHRET.TrainCode = bHRCM.Code and bHRET.Type = bHRCM.Type
Inner Join vDDBICompanies With (NoLock) ON vDDBICompanies.Co=bHRET.HRCo 
where bHRET.CompleteDate is not null and bHRCM.CertPeriod is not null

Union All
Select
	'SkillCertified' as RecType
	,bHRRS.HRCo
	,bHRRS.HRRef
	,Seq = 0
	,bHRRS.Code as TrainCode
	,bHRCM.KeyID as CodeMasterID
	,IsTrainingCompleteCount = null
	,IsTrainingCompleteSafetyCount = null
	,IsTrainingExpiringCount =null
	,IsTrainingExpiringSafetyCount =null
	,IsSkillCertifiedCount = 1
	,IsSkillCertifiedSafetyCount = Case when bHRCM.SafetyYN = 'Y' Then 1 Else null End
	,IsSkillExpiringCount = null
	,IsSkillExpiringSafetyCount = null
	,EventDate = bHRRS.CertDate

	,TestDate = bHRRS.CertDate

From bHRRS With (NoLock)
left outer join bHRCM With (NoLock)
	ON bHRRS.HRCo = bHRCM.HRCo and bHRRS.Code = bHRCM.Code and bHRRS.Type = bHRCM.Type
Inner Join vDDBICompanies With (NoLock) ON vDDBICompanies.Co=bHRRS.HRCo 
where bHRRS.CertDate is not null

Union All
Select
	'SkillExpired' as RecType	 
	,bHRRS.HRCo
	,bHRRS.HRRef
	,Seq = 0
	,bHRRS.Code as TrainCode
	,bHRCM.KeyID as CodeMasterID
	,IsTrainingCompleteCount = null
	,IsTrainingCompleteSafetyCount = null
	,IsTrainingExpiringCount =null
	,IsTrainingExpiringSafetyCount =null
	,IsSkillCertifiedCount = Null
	,IsSkillCertifiedSafetyCount = null
	,IsSkillExpiringCount = 1
	,IsSkillExpiringSafetyCount = Case when bHRCM.SafetyYN = 'Y' Then 1 Else null End
	,EventDate = bHRRS.ExpireDate

	,TestDate = bHRRS.CertDate

From bHRRS With (NoLock)
left outer join bHRCM With (NoLock)
	ON bHRRS.HRCo = bHRCM.HRCo and bHRRS.Code = bHRCM.Code and bHRRS.Type = bHRCM.Type
Inner Join vDDBICompanies With (NoLock) ON vDDBICompanies.Co=bHRRS.HRCo 
where bHRRS.CertDate is not null and bHRRS.ExpireDate is not null
)


----Build the Keys
select 

	bHRCO.KeyID as HRCoID
--	,HRTraining.RecType
	,isnull(bHRRM.KeyID,0) as HRRefID
	,isnull(bPRCO.KeyID,0) as PRCoID
	,isnull(bPRGR.KeyID,0) as PRGroupID
	,isnull(bHRPC.KeyID,0) as PositionCodeID
	,HRTraining.CodeMasterID
	,HRTraining.IsTrainingCompleteCount
	,HRTraining.IsTrainingCompleteSafetyCount
	,HRTraining.IsTrainingExpiringCount
	,HRTraining.IsTrainingExpiringSafetyCount
	,HRTraining.IsSkillCertifiedCount
	,HRTraining.IsSkillCertifiedSafetyCount
	,HRTraining.IsSkillExpiringCount
	,HRTraining.IsSkillExpiringSafetyCount 
	,EventDateID = DateDiff(d,'1/1/1950',isnull(HRTraining.EventDate,'1/1/1950'))
--	,HRTraining.TestDate
From HRTraining Inner Join bHRCO With (NoLock)
	ON HRTraining.HRCo = bHRCO.HRCo 
left outer join bHRRM With (NoLOck)
	ON HRTraining.HRCo = bHRRM.HRCo and HRTraining.HRRef = bHRRM.HRRef 
left outer Join bPRCO With (NoLock)
	ON bHRRM.PRCo= bPRCO.PRCo
Left Outer Join bPRGR With (NoLock)
	ON bHRRM.PRCo= bPRGR.PRCo and bHRRM.PRGroup = bPRGR.PRGroup
left Outer Join bHRPC With (NoLock)
	ON HRTraining.HRCo = bHRPC.HRCo and bHRRM.PositionCode = bHRPC.PositionCode 
Inner Join vDDBICompanies With (NoLock) ON vDDBICompanies.Co=HRTraining.HRCo

GO
GRANT SELECT ON  [dbo].[viFact_HRTraining] TO [public]
GRANT INSERT ON  [dbo].[viFact_HRTraining] TO [public]
GRANT DELETE ON  [dbo].[viFact_HRTraining] TO [public]
GRANT UPDATE ON  [dbo].[viFact_HRTraining] TO [public]
GO
