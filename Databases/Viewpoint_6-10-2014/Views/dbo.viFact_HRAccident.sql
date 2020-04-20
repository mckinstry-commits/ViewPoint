SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE View [dbo].[viFact_HRAccident]

/**************************************************
 * Alterd: CWW 5/6/09
 * Modified:      
 * Usage:  Fact View returning Accident data
 *         for use as Measures in SSAS Cubes. 
 *
 * The granularity for the HR Accident is Company, Accident 
 * and Accident Sequence level.  Data represented at lower levels 
 * will be aggregated to the defined levels.
 *
 * Maintenance Log
 * Date		Issue#		UpdateBy	Description
 * 05/06/09 129902     C Wirtz		New
 *
 * NOTE:
 * This Fact table retrieves data at the accident item level but
 * AccidentResolved and TotalAccidentCount are really at the accident level .
 * Therefore the Total Accident Count and Accident Resolved are
 * determine by using the HR Accident dimension which is at the
 * accident level.
 ********************************************************/

AS
--Extract specific accident information 
--Data tables bHRAT(Accident Tracking) and bHRAI (Accident Items)
With HRAccidentTracking
as

(Select	 
	 bHRAT.KeyID as AccidentID
	,bHRAT.HRCo
	,bHRAT.Accident
	,bHRAT.AccidentDate
	,bHRAT.JCCo
	,bHRAT.Job
	,bHRAT.Phase
	,bHRAT.PhaseGroup
	,bHRAT.ClosedDate
--HRAI fields
	,bHRAI.Seq  
	,bHRAI.HRRef
    ,bHRAI.WorkersCompYN
    ,bHRAI.WorkerCompClaim
    ,bHRAI.ClaimEstimate
	,bHRAI.AccidentType     --Resource, Equipment, or Third Party
From bHRAT With (NoLock)
Left Outer join bHRAI With (NoLock)
ON bHRAT.HRCo = bHRAI.HRCo and bHRAT.Accident = bHRAI.Accident
Inner Join vDDBICompanies With (NoLock) ON vDDBICompanies.Co=bHRAT.HRCo 
),


--HRAL	
-- Work Days lost or restrictions applied due to an accident
 HRLostRestrictedDays
as
(Select
	 bHRAL.HRCo
	,bHRAL.Accident
	,bHRAL.Seq
	,LostDays = sum(Case bHRAL.Type when 'L' then Days else 0 End)
	,RestrictedDays = sum(Case bHRAL.Type when 'R' then Days else 0 End)
From bHRAL With (Nolock)
Inner Join vDDBICompanies With (NoLock) ON vDDBICompanies.Co=bHRAL.HRCo
Group by HRCo,Accident,Seq),


--HRAC
--Claims filed
HRAccidentClaim
as
(Select
	 bHRAC.HRCo
	,bHRAC.Accident
	,bHRAC.Seq
	,ResourceWorkersCompCostFiled = sum(case When (bHRAI.AccidentType = 'R' and bHRAI.WorkersCompYN ='Y' and FiledYN='Y') Then Cost Else 0 End)
	,ResourceNonWorkersCompCostFiled = sum(case When (bHRAI.AccidentType = 'R' and (bHRAI.WorkersCompYN <>'Y' or FiledYN<>'Y')) Then Cost Else 0 End)
	,ResourceWorkersCompFiledPaid = sum(case When (bHRAI.AccidentType = 'R' and bHRAI.WorkersCompYN ='Y' and FiledYN='Y'and PaidYN='Y') Then PaidAmt Else 0 End)
	,ResourceNonWorkersCompFiledPaid = sum(case When (bHRAI.AccidentType = 'R' and (bHRAI.WorkersCompYN <>'Y' or FiledYN<>'Y')and PaidYN='Y') Then  PaidAmt Else 0 End)
	,ResourceWorkersCompDeductibleFiled = sum(case When (bHRAI.AccidentType = 'R' and bHRAI.WorkersCompYN ='Y' and FiledYN='Y') Then Deductible Else 0 End)
	,ResourceNonWorkersCompDeductibleFiled = sum(case When (bHRAI.AccidentType = 'R' and (bHRAI.WorkersCompYN <>'Y' or FiledYN<>'Y')) Then Deductible Else 0 End)

From bHRAC With (Nolock)
Left Outer Join bHRAI With (Nolock) 
ON bHRAC.HRCo= bHRAI.HRCo and bHRAC.Accident = bHRAI.Accident and bHRAC.Seq = bHRAI.Seq
Inner Join vDDBICompanies With (NoLock) ON vDDBICompanies.Co=bHRAC.HRCo
group by bHRAC.HRCo,bHRAC.Accident,bHRAC.Seq
),


--Combined all the CTEs into one data set  
--The common key is Company, Accident, and Seq
HRAccident
as
(Select	 
	 HRAccidentTracking.AccidentID
	,HRAccidentTracking.HRCo
	,HRAccidentTracking.Accident
	,HRAccidentTracking.Seq
	,AccidentDate
	,JCCo
	,Job
	,Phase
	,PhaseGroup
	,ClosedDate
--HRAI fields
	,HRRef
    ,WorkersCompYN
    ,WorkerCompClaim
    ,ClaimEstimate 
--HRAL
	,LostDays
	,RestrictedDays
--HRAC	
	,ResourceWorkersCompCostFiled
	,ResourceNonWorkersCompCostFiled
	,ResourceWorkersCompFiledPaid 
	,ResourceNonWorkersCompFiledPaid 
	,ResourceWorkersCompDeductibleFiled 
	,ResourceNonWorkersCompDeductibleFiled 

from  HRAccidentTracking 
Left Outer Join HRLostRestrictedDays
	ON	HRAccidentTracking.HRCo = HRLostRestrictedDays.HRCo  
		and HRAccidentTracking.Accident = HRLostRestrictedDays.Accident 
		and HRAccidentTracking.Seq = HRLostRestrictedDays.Seq
Left Outer Join HRAccidentClaim
	ON	HRAccidentTracking.HRCo = HRAccidentClaim.HRCo  
		and HRAccidentTracking.Accident = HRAccidentClaim.Accident 
		and HRAccidentTracking.Seq = HRAccidentClaim.Seq
)

--Build the Keys
select 
	 HRAccident.AccidentID
	,bHRCO.KeyID as HRCoID
	,isnull(bHRRM.KeyID,0) as HRRefID
	,isnull(bPRCO.KeyID,0) as PRCoID
	,isnull(bPRGR.KeyID,0) as PRGroupID
	,isnull(bHRPC.KeyID,0) as PositionCodeID
	,isnull(bJCJM.KeyID,0) as JobID
	,isnull(bJCJP.KeyID,0) as JobPhaseID  
	,isnull(bJCMP.KeyID,0) as ProjMgrID  
	,HRAccident.Accident -- Used to count the number accidents 
--	,HRAccident.AccidentDate   --DateDiff
   ,Datediff(dd,'1/1/1950',isnull(HRAccident.AccidentDate,'1/1/1950')) as AccidentDateID
--	,HRAccident.ClosedDate --DateDiff
   ,Datediff(dd,'1/1/1950',isnull(HRAccident.ClosedDate,'1/1/1950')) as AccidentClosedDateID
	,AccidentResolved = 
		case when HRAccident.ClosedDate is not null then 1 Else null end 
	,TotalAccidentCount = 1
--HRAI fields
    ,WorkerCompClaim  --Used to count the number of Workers Comp Claims 
    ,ClaimEstimate 
--HRAL
	,LostDays
	,RestrictedDays
--HRAC	
	,ResourceWorkersCompCostFiled
	,ResourceNonWorkersCompCostFiled
	,ResourceWorkersCompFiledPaid 
	,ResourceNonWorkersCompFiledPaid 
	,ResourceWorkersCompDeductibleFiled 
	,ResourceNonWorkersCompDeductibleFiled 

From HRAccident Left Outer Join bHRCO With (NoLock)
	ON HRAccident.HRCo = bHRCO.HRCo 
left outer join bHRRM With (NoLOck)
	ON HRAccident.HRCo = bHRRM.HRCo and HRAccident.HRRef = bHRRM.HRRef 
left outer Join bPRCO With (NoLock)
	ON bHRRM.PRCo= bPRCO.PRCo
Left Outer Join bPRGR With (NoLock)
	ON bHRRM.PRCo= bPRGR.PRCo and bHRRM.PRGroup = bPRGR.PRGroup
Left Outer Join bHRPC With (NoLock)
	ON bHRRM.HRCo = bHRPC.HRCo and bHRRM.PositionCode = bHRPC.PositionCode
Left Outer Join bJCJP With (NoLock)
	ON HRAccident.JCCo = bJCJP.JCCo and HRAccident.Job = bJCJP.Job 
		and HRAccident.PhaseGroup = bJCJP.PhaseGroup and HRAccident.Phase = bJCJP.Phase 
Left Outer Join bJCJM With (NoLock)
	ON HRAccident.JCCo = bJCJM.JCCo and HRAccident.Job = bJCJM.Job 
Left Outer Join bJCMP With (NoLock)
	ON bJCJM.JCCo = bJCMP.JCCo and bJCJM.ProjectMgr = bJCMP.ProjectMgr
Inner Join vDDBICompanies With (NoLock) ON vDDBICompanies.Co=HRAccident.HRCo

GO
GRANT SELECT ON  [dbo].[viFact_HRAccident] TO [public]
GRANT INSERT ON  [dbo].[viFact_HRAccident] TO [public]
GRANT DELETE ON  [dbo].[viFact_HRAccident] TO [public]
GRANT UPDATE ON  [dbo].[viFact_HRAccident] TO [public]
GRANT SELECT ON  [dbo].[viFact_HRAccident] TO [Viewpoint]
GRANT INSERT ON  [dbo].[viFact_HRAccident] TO [Viewpoint]
GRANT DELETE ON  [dbo].[viFact_HRAccident] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[viFact_HRAccident] TO [Viewpoint]
GO
