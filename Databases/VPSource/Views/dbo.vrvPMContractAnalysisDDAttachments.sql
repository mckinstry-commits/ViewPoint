SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*********************************************************************
 * Created By:	JH 1/22/10 - Initial version for customer 
 *				report PM Contract Analysis DD
 * Modfied By:  #138909 HH 1/5/11 - No modification, created in VPDev640 
 *				for customer report PM Contract Analysis DD to 
 *				become Standard report in PM
 *
 *	Used on PM Contract Analysis DD report
 *
 *********************************************************************/  



CREATE          view [dbo].[vrvPMContractAnalysisDDAttachments] as



select Src='JC',JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType,
	PostedDate,ActualDate,JCTransType,Source,Description,BatchId,InUseBatchId,GLCo,GLTransAcct,GLOffsetAcct,ReversalStatus,
	UM,ActualUnitCost,PerECM,ActualHours,ActualUnits,ActualCost,ProgressCmplt,EstHours,EstUnits,EstCost,ProjHours,ProjUnits,
	ProjCost,ForecastHours,ForecastUnits,ForecastCost,PostedUM,PostedUnits,PostedUnitCost,PostedECM,PostTotCmUnits,PostRemCmUnits,
	TotalCmtdUnits,TotalCmtdCost,RemainCmtdUnits,RemainCmtdCost,DeleteFlag,AllocCode,ACO,ACOItem,PRCo,Employee,Craft,Class,
	Crew,EarnFactor,EarnType,Shift,LiabilityType,VendorGroup,Vendor,APCo,APTrans,APLine,APRef,PO,POItem,SL,SLItem,MO,MOItem,
	MatlGroup,Material,INCo,Loc,INStdUnitCost,INStdECM,INStdUM,MSTrans,MSTicket,JBBillStatus,JBBillMonth,JBBillNumber,EMCo,
	EMEquip,EMRevCode,EMGroup,EMTrans,TaxType,TaxGroup,TaxCode,TaxBasis,TaxAmt,UniqueAttchID=null,SrcJCCo,
	AttachmentID=null,HQATDescription=null,DocName=null
from JCCD with(nolock)
 
union all
   
select distinct 'AP',JCCD.JCCo, JCCD.Mth, JCCD.CostTrans, JCCD.Job, JCCD.PhaseGroup, JCCD.Phase, JCCD.CostType,
	PostedDate,ActualDate,JCTransType,Source,null,null,null,null,null,null,null,
	null,null,null,null,null,null,null,null,null,null,null,null,
	null,null,null,null,null,null,null,null,null,null,
	null,null,null,null,null,null,null,null,null,null,null,null,
	null,null,null,null,null,null,null,null,null,null,null,JCCD.PO,POItem=null,JCCD.SL,SLItem=null,JCCD.MO,MOItem=null,
	MatlGroup=null,Material=null,INCo=null,Loc=null,INStdUnitCost=null,INStdECM=null,INStdUM=null,MSTrans=null,MSTicket=null,JBBillStatus=null,JBBillMonth=null,JBBillNumber=null,EMCo=null,
	EMEquip=null,EMRevCode=null,EMGroup=null,EMTrans=null,TaxType=null,TaxGroup=null,TaxCode=null,TaxBasis=null,TaxAmt=null,APTH.UniqueAttchID,null,
	HQAI.AttachmentID,HQAT.Description,HQAT.DocName
from JCCD with(nolock)
	join HQAI with (nolock) on JCCD.APCo=HQAI.APCo and JCCD.VendorGroup=HQAI.APVendorGroup and JCCD.Vendor=HQAI.APVendor and JCCD.APRef=HQAI.APReference and
               JCCD.JCCo=HQAI.JCCo and JCCD.Job=HQAI.JCJob and JCCD.PhaseGroup=HQAI.JCPhaseGroup and JCCD.Phase=HQAI.JCPhase
             and JCCD.CostType=HQAI.JCCostType
	join HQAT with(nolock) on HQAI.AttachmentID=HQAT.AttachmentID
	join APTH with(nolock) on JCCD.APCo=APTH.APCo and JCCD.Mth=APTH.Mth and JCCD.APTrans=APTH.APTrans
 
union all
  
select distinct 'JC',JCCD.JCCo, JCCD.Mth, JCCD.CostTrans, JCCD.Job, JCCD.PhaseGroup, JCCD.Phase, JCCD.CostType,
	null,null,JCTransType,JCCD.Source,null,null,null,null,null,null,null,
	null,null,null,null,null,null,null,null,null,null,null,null,
	null,null,null,null,null,null,null,null,null,null,
	null,null,null,null,null,null,null,null,null,null,null,null,
	null,null,null,null,null,null,null,null,null,null,null,JCCD.PO,POItem=null,JCCD.SL,SLItem=null,JCCD.MO,MOItem=null,
	null,null,null,null,null,null,null,null,null,null,null,null,null,
	null,null,null,null,null,null,null,null,null,JCCD.UniqueAttchID,null,
	HQAI.AttachmentID,HQAT.Description,HQAT.DocName
from JCCD with(nolock)
	join HQAI with(nolock) on JCCD.MSTicket=HQAI.MSTicket 
			and JCCD.JCCo=HQAI.JCCo and JCCD.Job=HQAI.JCJob and JCCD.PhaseGroup=HQAI.JCPhaseGroup and JCCD.Phase=HQAI.JCPhase
			and JCCD.CostType=HQAI.JCCostType
	join HQAT with(nolock) on HQAI.AttachmentID=HQAT.AttachmentID

union all
  
--PO attachments
select distinct 'PO',JCCD.JCCo, JCCD.Mth, JCCD.CostTrans, JCCD.Job, JCCD.PhaseGroup, JCCD.Phase, JCCD.CostType,
	null,null,JCTransType,JCCD.Source,null,null,null,null,null,null,null,
	null,null,null,null,null,null,null,null,null,null,null,null,
	null,null,null,null,null,null,null,null,null,null,
	null,null,null,null,null,null,null,null,null,null,null,null,
	null,null,null,null,null,null,null,null,null,null,null,JCCD.PO,POItem=null,JCCD.SL,SLItem=null,JCCD.MO,MOItem=null,
	null,null,null,null,null,null,null,null,null,null,null,null,null,
	null,null,null,null,null,null,null,null,null,POHD.UniqueAttchID,null,
	HQAI.AttachmentID,HQAT.Description,HQAT.DocName
from JCCD with(nolock)
	join (select POCo, PO, POHD.UniqueAttchID
			from POHD with(nolock) 
			group by POCo, PO, POHD.UniqueAttchID) as POHD on JCCD.JCCo=POHD.POCo and JCCD.PO=POHD.PO
	join HQAI with(nolock) on JCCD.JCCo=HQAI.JCCo and JCCD.Job=HQAI.JCJob and JCCD.PhaseGroup=HQAI.JCPhaseGroup and JCCD.Phase=HQAI.JCPhase
			and JCCD.CostType=HQAI.JCCostType and JCCD.PO=HQAI.POPurchaseOrder and JCCD.POItem=HQAI.POItem
	join HQAT with(nolock) on HQAI.AttachmentID=HQAT.AttachmentID
where JCCD.JCTransType like 'PO%' and JCCD.APRef is null and HQAI.APReference is null

union all
  
--SL attachments
select distinct 'SL',JCCD.JCCo, JCCD.Mth, JCCD.CostTrans, JCCD.Job, JCCD.PhaseGroup, JCCD.Phase, JCCD.CostType,
	null,null,JCTransType,JCCD.Source,null,null,null,null,null,null,null,
	null,null,null,null,null,null,null,null,null,null,null,null,
	null,null,null,null,null,null,null,null,null,null,
	null,null,null,null,null,null,null,null,null,null,null,null,
	null,null,null,null,null,null,null,null,null,null,null,PO=null,POItem=null,JCCD.SL,SLItem=null,MO=null,MOItem=null,
	null,null,null,null,null,null,null,null,null,null,null,null,null,
	null,null,null,null,null,null,null,null,null,SLHD.UniqueAttchID,null,
	HQAI.AttachmentID,HQAT.Description,HQAT.DocName
from JCCD with(nolock)
	join (select SLCo, SL, SLHD.UniqueAttchID
			from SLHD with(nolock) 
			group by SLCo, SL, SLHD.UniqueAttchID) as SLHD on JCCD.JCCo=SLHD.SLCo and JCCD.SL=SLHD.SL
	join HQAI with(nolock) on JCCD.JCCo=HQAI.JCCo and JCCD.Job=HQAI.JCJob and JCCD.PhaseGroup=HQAI.JCPhaseGroup and JCCD.Phase=HQAI.JCPhase
			and JCCD.CostType=HQAI.JCCostType and JCCD.SL=HQAI.SLSubcontract and JCCD.SLItem=HQAI.SLSubcontractItem
	join HQAT with(nolock) on HQAI.AttachmentID=HQAT.AttachmentID
where JCCD.JCTransType like 'SL%' and JCCD.APRef is null and HQAI.APReference is null
 
union all

   
select distinct 'PR',JCCD.JCCo, JCCD.Mth, JCCD.CostTrans, JCCD.Job, JCCD.PhaseGroup, JCCD.Phase, JCCD.CostType,
	PostedDate,ActualDate,JCTransType,Source,Description=null,BatchId=null,InUseBatchId=null,GLCo=null,GLTransAcct=null,GLOffsetAcct=null,ReversalStatus=null,
	null,null,null,null,null,null,null,null,null,null,null,null,
	null,null,null,null,null,null,null,null,null,null,
	null,null,null,null,null,null,null,null,null,null,null,null,
	null,null,null,null,null,null,null,null,null,null,null,PO=null,POItem=null,JCCD.SL,SLItem=null,MO=null,MOItem=null,
	null,null,null,null,null,null,null,null,null,null,null,null,null,
	null,null,null,null,null,null,null,null,null,JCCD.UniqueAttchID,null,
	HQAT.AttachmentID,HQAT.Description, HQAT.DocName
from JCCD with(nolock)
	join (select PRTH.PRCo, Employee, Job, Phase, Date=Case when PRCO.JCIPostingDate = 'N' then PREndDate else PostDate end,
				PRTH.UniqueAttchID  
			from PRTH with(nolock)
				join PRCO with(nolock) on PRTH.PRCo=PRCO.PRCo
			where PRTH.UniqueAttchID is not null) 
			as c
			on JCCD.PRCo=c.PRCo and JCCD.Job=c.Job and JCCD.Employee=c.Employee and  c.Phase=JCCD.Phase and c.Date=JCCD.ActualDate
	join HQAT with(nolock) on c.UniqueAttchID=HQAT.UniqueAttchID
 
union all
 
select distinct 'JC',JCCD.JCCo, JCCD.Mth, JCCD.CostTrans, JCCD.Job, JCCD.PhaseGroup, JCCD.Phase, JCCD.CostType,
	null,null,JCTransType,JCCD.Source,null,null,null,null,null,null,null,
	null,null,null,null,null,null,null,null,null,null,null,null,
	null,null,null,null,null,null,null,null,null,null,
	null,null,null,null,null,null,null,null,null,null,null,null,
	null,null,null,null,null,null,null,null,null,null,null,JCCD.PO,POItem=null,JCCD.SL,SLItem=null,JCCD.MO,MOItem=null,
	null,null,null,null,null,null,null,null,null,null,null,null,null,
	null,null,null,null,null,null,null,null,null,JCCD.UniqueAttchID,null,
	HQAT.AttachmentID,HQAT.Description,HQAT.DocName
from JCCD with(nolock)
	join HQAT with(nolock) on HQAT.UniqueAttchID=JCCD.UniqueAttchID

union all
 
select distinct 'IN',JCCD.JCCo, JCCD.Mth, JCCD.CostTrans, JCCD.Job, JCCD.PhaseGroup, JCCD.Phase, JCCD.CostType,
	null,null,JCTransType,JCCD.Source,null,null,null,null,null,null,null,
	null,null,null,null,null,null,null,null,null,null,null,null,
	null,null,null,null,null,null,null,null,null,null,
	null,null,null,null,null,null,null,null,null,null,null,null,
	null,null,null,null,null,null,null,null,null,null,null,JCCD.PO,POItem=null,JCCD.SL,SLItem=null,JCCD.MO,MOItem=null,
	null,null,null,null,null,null,null,null,null,null,null,null,null,
	null,null,null,null,null,null,null,null,null,INMO.UniqueAttchID,null,
	HQAT.AttachmentID,HQAT.Description,HQAT.DocName
from JCCD with(nolock)
	join HQAI with(nolock) on JCCD.INCo=HQAI.INCo and JCCD.Loc=HQAI.INLoc and JCCD.MO=HQAI.MO and JCCD.MOItem=HQAI.MOItem 
      and JCCD.GLCo=HQAI.GLCo and JCCD.GLTransAcct=HQAI.GLAcct
	join INMO with(nolock) on HQAI.INCo=INMO.INCo and HQAI.MO=INMO.MO 
	join HQAT with(nolock) on HQAT.AttachmentID=HQAI.AttachmentID

GO
GRANT SELECT ON  [dbo].[vrvPMContractAnalysisDDAttachments] TO [public]
GRANT INSERT ON  [dbo].[vrvPMContractAnalysisDDAttachments] TO [public]
GRANT DELETE ON  [dbo].[vrvPMContractAnalysisDDAttachments] TO [public]
GRANT UPDATE ON  [dbo].[vrvPMContractAnalysisDDAttachments] TO [public]
GO
