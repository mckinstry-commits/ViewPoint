SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE View [dbo].[viFact_APJobCost]

/**************************************************
 * Alterd: DH 6/6/08
 * Modified:      
 *
 * Usage:  View that returns AP data for the Job Cost Cube in SSAS.  First
 *         Select in CTE returns all AP Invoice Data.  Second SQL Statement
 *         returns only paid transactions.  View provides data for making it efficient
 *         to calculate Open Payable over a series of Months or Dates.  KeyID fields selected
 *         for joining to dimensions in Cube.
 *
 ***************************************************/

as

With APJob (JCCo,
			 Job,
			 PhaseGroup,
			 Phase,
			 CostType,
			 APCo,
			 APInvoiceID,
			 RetainageYN,
			 Status,
			 VendorGroup,
			 Vendor,
			 GLCo,
			 Mth,
			 Date,
			 DaysDue,
			 APAmount,
			 PaidAmt)

as

(
 Select bAPTL.JCCo,
        bAPTL.Job,
        bAPTL.PhaseGroup,
        bAPTL.Phase,
        bAPTL.JCCType,
		bAPTL.APCo,
		bAPTH.KeyID as APInvoiceID,
		case when bAPCO.PayCategoryYN='N' or bAPTD.PayCategory is null then
            case when bAPTD.PayType=bAPCO.RetPayType then 'Y' else 'N' end
	    else 
			case when bAPTD.PayType=bAPPC.RetPayType then 'Y' else 'N' end 
		end as RetainageYN, /* Retainage:  If not using Pay Categories, return amount based on 
                             APCO Pay Type else get from APPC RetPayType*/
		bAPTD.Status,
		bAPTH.VendorGroup,
		bAPTH.Vendor,
        bAPTL.GLCo,
        bAPTL.Mth,
        bAPTH.InvDate,
        case when bAPTD.Status=1 then datediff(dd,getdate(),bAPTH.DueDate) else 0 end,
        bAPTD.Amount,
		0
    From  bAPTD With (NoLock) 
    Join  bAPTH With (NoLock) ON bAPTD.APCo = bAPTH.APCo AND bAPTD.Mth = bAPTH.Mth AND bAPTD.APTrans = bAPTH.APTrans 
    Join  bAPTL With (NoLock) ON bAPTD.APCo = bAPTL.APCo AND bAPTD.Mth = bAPTL.Mth AND bAPTD.APTrans = bAPTL.APTrans AND bAPTL.APLine = bAPTD.APLine 
    Left Join bAPPC With (NoLock) on bAPPC.APCo=bAPTD.APCo and bAPPC.PayCategory=bAPTD.PayCategory
	Join bAPCO With (NoLock) on  bAPCO.APCo=bAPTD.APCo
	Join bJCJM With (NoLock) on bJCJM.JCCo=bAPTL.JCCo and bJCJM.Job=bAPTL.Job
    

     union all

 Select bAPTL.JCCo,
        bAPTL.Job,
        bAPTL.PhaseGroup,
        bAPTL.Phase,
        bAPTL.JCCType,
		bAPTL.APCo,
		bAPTH.KeyID as APInvoiceID,
		'N' as RetainageYN,
		3 as Status,
		bAPTH.VendorGroup,
		bAPTH.Vendor,
        bAPTL.GLCo,
        bAPTD.PaidMth,
        bAPTD.PaidDate,
        0,
        0,
        bAPTD.Amount
    From  bAPTD With (NoLock) 
    Join  bAPTH With (NoLock) ON bAPTD.APCo = bAPTH.APCo AND bAPTD.Mth = bAPTH.Mth AND bAPTD.APTrans = bAPTH.APTrans 
    Join  bAPTL With (NoLock) ON bAPTD.APCo = bAPTL.APCo AND bAPTD.Mth = bAPTL.Mth AND bAPTD.APTrans = bAPTL.APTrans AND bAPTL.APLine = bAPTD.APLine 
    Join bJCJM With (NoLock) on bJCJM.JCCo=bAPTL.JCCo and bJCJM.Job=bAPTL.Job
    Where bAPTD.PaidMth  is not null)

select  bJCCO.KeyID as JCCoID,
		bPMCO.KeyID as PMCoID,
        bJCJM.KeyID as JobID,
        bJCJP.KeyID as JobPhaseID,
	    bJCCH.KeyID as JobPhaseCostTypeID,
        bJCCT.KeyID as CostTypeID,
        bJCCM.KeyID as ContractID,
		bARCM.KeyID as CustomerID,
        bJCCI.KeyID as ContractItemID,
        bJCDM.KeyID as JCDeptID,
        isnull(bJCMP.KeyID,0) as ProjectMgrID,
        bJCCI.KeyID as DeptContractHierarchyID,
		bAPVM.KeyID as APVendorID,
        datediff(mm,'1/1/1950',APJob.Mth) as MonthID,
		Cast(cast(bGLFP.GLCo as varchar(3))+cast(Datediff(dd,'1/1/1950',bGLFP.Mth) as varchar(10)) as int) as FiscalMthID,
        --viDim_GLFiscalMth.FiscalMthID,
        APJob.Mth,
        datediff(dd,'1/1/1950',APJob.Date) as ActualDateID,
        APJob.Date,
		APJob.APInvoiceID,
        APJob.DaysDue,
        --case when APJob.Status<>2 and APJob.RetainageYN='N' then APJob.APAmount else 0 end as InvoiceAmt,
		APJob.APAmount as InvoiceAmt,
        case when APJob.Status=2 and APJob.RetainageYN='N' then APJob.APAmount else 0 end as OnHoldAmt,
		case when APJob.RetainageYN='Y' then APJob.APAmount else 0 end as APRetainage,
		APJob.PaidAmt
        
        
        
From APJob 
Join vDDBICompanies on vDDBICompanies.Co=APJob.JCCo
Join bJCJP With (NoLock) ON bJCJP.JCCo = APJob.JCCo AND bJCJP.Job = APJob.Job AND bJCJP.PhaseGroup = APJob.PhaseGroup AND bJCJP.Phase = APJob.Phase
Join bJCCO With (NoLock) on bJCCO.JCCo=APJob.JCCo
Left Join bPMCO With (NoLock) on bPMCO.PMCo=APJob.JCCo
Join bJCJM With (NoLock) on bJCJM.JCCo=APJob.JCCo and bJCJM.Job=APJob.Job
Join bJCCH With (NoLock) on bJCCH.JCCo=APJob.JCCo and bJCCH.Job=APJob.Job
                         and bJCCH.PhaseGroup=APJob.PhaseGroup and bJCCH.Phase=APJob.Phase 
                         and bJCCH.CostType=APJob.CostType
Left Join bJCMP With (NoLock) on bJCMP.JCCo=bJCJM.JCCo and bJCMP.ProjectMgr=bJCJM.ProjectMgr
Left Join bJCCT With (NoLock) on bJCCT.PhaseGroup=APJob.PhaseGroup and bJCCT.CostType=APJob.CostType
/*Join viDim_JCJobPhases With (NoLock) on viDim_JCJobPhases.JCCo=APJob.JCCo 
								 and viDim_JCJobPhases.Job=APJob.Job
                                 and viDim_JCJobPhases.PhaseGroup=APJob.PhaseGroup
                                 and viDim_JCJobPhases.JobPhase=APJob.Phase*/
Join bJCCM With (NoLock) on bJCCM.JCCo=bJCJM.JCCo and bJCCM.Contract=bJCJM.Contract
Left Join bARCM With (NoLock) on bARCM.CustGroup=bJCCM.CustGroup and bARCM.Customer=bJCCM.Customer
Left Join bJCCI With (NoLock) on bJCCI.JCCo=bJCJP.JCCo and bJCCI.Contract=bJCJP.Contract and bJCCI.Item=bJCJP.Item
Left Join bJCDM With (NoLock) on bJCDM.JCCo=bJCCI.JCCo and bJCDM.Department=bJCCI.Department
Left Join bGLFP With (NoLock) on bGLFP.GLCo=APJob.GLCo and bGLFP.Mth=APJob.Mth
--Join viDim_GLFiscalMth With (NoLock) on viDim_GLFiscalMth.Mth=bGLFP.Mth and viDim_GLFiscalMth.FiscalPd=bGLFP.FiscalPd
/*Join viDim_JCDeptContract_Hierarchy With (NoLock) 
                                 on viDim_JCDeptContract_Hierarchy.JCCo=bJCJP.JCCo
                                 and viDim_JCDeptContract_Hierarchy.Contract=bJCJP.Contract
                                 and viDim_JCDeptContract_Hierarchy.Item=bJCJP.Item*/
Left Join bAPVM on bAPVM.VendorGroup=APJob.VendorGroup and bAPVM.Vendor=APJob.Vendor




GO
GRANT SELECT ON  [dbo].[viFact_APJobCost] TO [public]
GRANT INSERT ON  [dbo].[viFact_APJobCost] TO [public]
GRANT DELETE ON  [dbo].[viFact_APJobCost] TO [public]
GRANT UPDATE ON  [dbo].[viFact_APJobCost] TO [public]
GO
