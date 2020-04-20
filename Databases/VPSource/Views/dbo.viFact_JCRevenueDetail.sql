SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE View [dbo].[viFact_JCRevenueDetail]

/**************************************************
 * Alterd: DH 6/4/08
 * Modified: DH 7/28/11     
 *
 * View that Provides the Contract and Revenue measures from JCID for the Job Cost Cube
 * as well as Pending Contract Amounts for non-interfaced change orders.
 * KeyIDs selected from maintenance tables to use in Cube Dimension/Fact relationships.
 * Joined to tables to avoid security overhead - Security done on Cubes in SSAS instead
 * View uses 4 CTEs:  ProjectedRevenue, ProjectedRevenue_with_Previous, JCRevDetail, and ContractFirstJob.
 ***************************************************/

as

--Get each month a projection is entered.

WITH cteProjMth (JCCo, Contract, Item, ProjMth)

as
	
(SELECT JCCo,
		Contract,
		Item,
 		JCIP.Mth

FROM JCIP

WHERE JCIP.ProjDollars<>0 or ProjPlug='Y'
			
),


cteProjRevenueToDate (JCCo, Contract, Item, Mth, MthNum, ProjDollarsToDate, ContractAmtToDate, ProjPlugToDate)

AS


(SELECT bJCIP.JCCo,
		bJCIP.Contract,
		bJCIP.Item,
		bJCIP.Mth,
		ROW_NUMBER() OVER ( PARTITION BY bJCIP.JCCo, bJCIP.Contract, bJCIP.Item ORDER BY bJCIP.Mth ) as MthNum,
		sum(Prev.ProjDollars) as ProjDollarsToDate,
		sum(Prev.ContractAmt) as ContractAmtToDate,
		max(case when cteProjMth.ProjMth = bJCIP.Mth then bJCIP.ProjPlug end) as LastProjPlugToDate

  FROM bJCIP	
  JOIN JCIP Prev ON
		bJCIP.JCCo = Prev.JCCo AND
		bJCIP.Contract = Prev.Contract AND
		bJCIP.Item = Prev.Item AND
		bJCIP.Mth >= Prev.Mth
  LEFT JOIN cteProjMth ON
		cteProjMth.JCCo = bJCIP.JCCo AND
	    cteProjMth.Contract = bJCIP.Contract AND
	    cteProjMth.Item = bJCIP.Item AND
	    cteProjMth.ProjMth = bJCIP.Mth
	    	
   
   GROUP BY bJCIP.JCCo,
			bJCIP.Contract,
			bJCIP.Item,
			bJCIP.Mth
 		
		
		
),

cteEstRevenueComplete

as	

(Select	a.JCCo,
		a.Contract,
		a.Item,
		a.Mth,
		a.ProjDollarsToDate,
		prevMonth.ProjDollarsToDate as ProjDollarsToDatePrevious,
		a.ContractAmtToDate,
		prevMonth.ContractAmtToDate as ContractAmtToDatePrevious,
		a.ProjPlugToDate,
		prevMonth.ProjPlugToDate as ProjPlugToDatePrevious,
		
		/* Estimated Revenue at Completion:  Returns the incremental Estimated Revenue At Completeion by Month.
		   Based on Projected Revenue and Contract Amounts.  Previous amounts through the prior month are subtracted
		   from to date amounts to get monthly amounts 
		   
		   
		   Projected To Date = ProjDollarsToDate <> 0 or ProjPlugToDate=Y
		   Previous Projected = ProjDollarsToDatePrevious <> 0 or ProjPlugToDatePrevious = Y
		   Contract = Current Contract Amount To Date
		   Previous Contract = Current Contract Amount through previous amount
		
		1. Projected To Date, Previous Projected:  Projected To Date - Previous Projected.
		2. Projected To Date, No Previous Projected:  Projected To Date - Previous Contract Amount.
		3. No Projected To Date, No Previous Projected:  Contract To Date - Previous Contract.
		4. No Projected To Date, Previous Projected:  Contract To Date - Previous Projected.  
				
		*/
		case when a.ProjDollarsToDate<>0 or isnull(a.ProjPlugToDate,prevMonth.ProjPlugToDate)='Y'
				then case when prevMonth.ProjDollarsToDate<>0 or prevMonth.ProjPlugToDate='Y'
							then a.ProjDollarsToDate-isnull(prevMonth.ProjDollarsToDate,0)
				          else a.ProjDollarsToDate - isnull(prevMonth.ContractAmtToDate,0)
					  end
			 when a.ProjDollarsToDate=0 and isnull(a.ProjPlugToDate,isnull(prevMonth.ProjPlugToDate,'N'))='N'	
				then case when isnull(prevMonth.ProjDollarsToDate,0)=0 and isnull(prevMonth.ProjPlugToDate,'N')='N'
							then a.ContractAmtToDate - isnull(prevMonth.ContractAmtToDate,0)
					      else a.ContractAmtToDate - isnull(prevMonth.ProjDollarsToDate,0)
					 end     
		End as EstRevCompleteMth				      
					 		
		 				 
From cteProjRevenueToDate a
LEFT JOIN cteProjRevenueToDate prevMonth
		ON a.JCCo=prevMonth.JCCo AND
		   a.Contract=prevMonth.Contract AND
		   a.Item=prevMonth.Item AND
		   a.MthNum-1=prevMonth.MthNum
	   
)	,	   
			




/*Begin JCRevDetail CTE*/

JCRevDetail
(JCCo,
 Contract,
 ContractItem,
 Mth,
 GLCo,
 ARCo,
 ARTrans,
 ActualDate,
 PostedDate,
 OrigContractAmt,
 OrigContractUnits,
 OrigUnitPrice, /*Original Contract Measures*/
 CurrentContractAmt,
 CurrentContractUnits,
 CurrentUnitPrice, /*Current Contract Measures*/
 ProjDollars,
 ProjUnits, /*ProjPlug - to be used for Contract at Completion*/
 BilledAmt,
 BilledUnits,
 BilledTax, /*Billed Measures*/
 ReceivedAmt, /*Received Measure*/
 CurrentRetainAmt,
 PendingContractChgAmt,
 EstRevenueComplete)

as
(Select 
 bJCID.JCCo,
 bJCID.Contract,
 bJCID.Item,
 bJCID.Mth,
 isnull(bJCID.GLCo,bJCCO.GLCo),
 bJCID.ARCo,
 bJCID.ARTrans,
 ActualDate,
 PostedDate,
 case when bJCID.JCTransType='OC' then bJCID.ContractAmt end as OrigContractAmt,
 case when bJCID.JCTransType='OC' then bJCID.ContractUnits end as OrigContractUnits,
 case when bJCID.JCTransType='OC' then bJCID.UnitPrice end as OrigUnitPrice, /*Original Contract Measures*/
 case when bJCID.ContractAmt<>0 then bJCID.ContractAmt end as CurrentContractAmt,
 case when bJCID.ContractUnits<>0 then bJCID.ContractUnits end as CurrentContractUnits,
 case when bJCID.UnitPrice<>0 then bJCID.UnitPrice end as CurrentUnitPrice,/*Current Contract Measures*/
 case when bJCID.ProjDollars<>0 then bJCID.ProjDollars end,
 case when bJCID.ProjUnits<>0 then bJCID.ProjUnits end, /*ProjPlug - to be used for Contract at Completion*/
 case when bJCID.BilledAmt<>0 then bJCID.BilledAmt end,
 case when bJCID.BilledUnits<>0 then bJCID.BilledUnits end,
 case when bJCID.BilledTax<>0 then bJCID.BilledTax end, /*Billed Measures*/
 case when bJCID.ReceivedAmt<>0 then bJCID.ReceivedAmt end , /*Received Measure*/
 case when bJCID.CurrentRetainAmt<>0 then bJCID.CurrentRetainAmt end,
 Null as PendingContractChgAmt,
 Null as EstRevenueComplete
 From bJCID
 Join bJCCO on bJCCO.JCCo=bJCID.JCCo

union all

/*Select Estimated Revenue at Completion (follows standard WIP report calculations)
  If first month a projection exists before or on bJCIP.Mth (FirstRevProjMth <= bJCIP.Mth)
  then use Projected Dollars, else use Current Contract.  Set to either Projected or 
  Current Contract for all bJCIP records by contract item */

select  R.JCCo,
        R.Contract,
		R.Item,
		R.Mth,
        bJCCO.GLCo,
		Null as ARCo,
		Null as ARTrans,
		R.Mth as ActualDate,
		R.Mth as PostedDate,
		Null as OrigContractAmt,
		Null as OrigContractUnits,
		Null as OrigUnitPrice, 
		Null as CurrentContractAmt,
		Null as CurrentContractUnits,
		Null as CurrentUnitPrice,
		Null as ProjDollars,
		Null as ProjUnits, 
		Null as BilledAmt,
		Null as BilledUnits,
		Null as BilledTax, 
		Null as ReceivedAmt, 
		Null as CurrentRetainAmt,
		Null as PendingContractChgAmt,
		R.EstRevCompleteMth
		
From cteEstRevenueComplete R
Join bJCCO on bJCCO.JCCo=R.JCCo


union all

/*Include Contract Change Amounts from non-interfaced Pending CO's
 *Returns Current Date and Month (based on Current Date)*/ 
Select bPMOI.PMCo,
	    bPMOI.Contract,
	    isnull(bPMOI.ContractItem,space(15)+'0') as ContractItem,
        DATEADD(d,DATEDIFF(d,0,GETDATE()),0) - (Day(DATEADD(d,DATEDIFF(d,0,GETDATE()),0))-1) as Mth,
		bJCCO.GLCo,
		Null as ARCo,
		Null as ARTrans,
		DATEADD(d,DATEDIFF(d,0,GETDATE()),0) as ActualDate, --removes time stamp of getdate
	    DATEADD(d,DATEDIFF(d,0,GETDATE()),0) as PostedDate, --removes time stamp of getdate
		Null as OrigContractAmt,
		Null as OrigContractUnits,
		Null as OrigUnitPrice,
		Null as CurrentContractAmt,
		Null as CurrentContractUnits,
		Null as CurrentUnitPrice,
		Null as ProjDollars,
		Null as ProjUnits,
		Null as BilledAmt,
		Null as BilledUnits,
		Null as BilledTax,
		Null as ReceivedAmt,
		Null as CurrentRetainAmt,
		sum(bPMOI.PendingAmount) as PendingContractChgAmount,
		Null as EstRevenueComplete
 From bPMOI
 Join bPMSC on bPMSC.Status=bPMOI.Status
 Join bJCCO on bJCCO.JCCo=bPMOI.PMCo
Where bPMOI.InterfacedDate is null and bPMSC.IncludeInProj='Y' 
/*Only include statuses to be included in Future CO's column in JC Projections*/
Group By PMCo, Contract, ContractItem, bJCCO.GLCo), /*End JCRevDetail CTE*/


ContractFirstJob (JCCo, Contract, Job)
as
(Select JCCo, Contract, min(Job) From bJCJM With (NoLock)
 Group By JCCo, Contract) /*CTE to get First Job by Contract*/
                          /*Used for returning PM on first job assigned to contract*/

/*Final Select*/
Select   bJCCO.KeyID as JCCoID
		,bPMCO.KeyID as PMCoID
        ,bJCCM.KeyID as ContractID
        ,bARCM.KeyID as CustomerID
        ,bJCCI.KeyID as ContractItemID
        ,bJCDM.KeyID as JCDeptID
        ,isnull(bJCMP.KeyID,0) as ProjectMgrID
        ,bJCCI.KeyID as DeptContractHierarchyID
        ,JCRevDetail.Mth
        ,Datediff(mm,'1/1/1950',JCRevDetail.Mth) as MonthID
        ,JCRevDetail.ActualDate
        ,datediff(dd,'1/1/1950',JCRevDetail.ActualDate) as ActualDateID
        ,JCRevDetail.PostedDate
        ,datediff(dd,'1/1/1950',JCRevDetail.PostedDate) as PostedDateID
		,isnull(Cast(cast(bGLFP.GLCo as varchar(3))+cast(Datediff(dd,'1/1/1950',bGLFP.Mth) as varchar(10)) as int),0) as FiscalMthID
        --,isnull(viDim_GLFiscalMth.FiscalMthID,0) as FiscalMthID
		--,isnull(viDim_ARInvoice.ARInvoiceID,0) as ARInvoiceID
        ,JCRevDetail.OrigContractAmt
        ,JCRevDetail.OrigContractUnits
        ,JCRevDetail.OrigUnitPrice /*Original Contract Measures*/
		,case when bJCCM.ContractStatus=0 then JCRevDetail.OrigContractAmt end as PendingContractAmt
        ,JCRevDetail.CurrentContractAmt as CurrentContractAmt
        ,JCRevDetail.CurrentContractUnits as CurrentContractUnits
        ,JCRevDetail.CurrentUnitPrice /*Current Contract Measures*/
        ,JCRevDetail.ProjDollars, JCRevDetail.ProjUnits /*ProjPlug - to be used for Contract at Completion*/
        ,JCRevDetail.BilledAmt, JCRevDetail.BilledUnits, JCRevDetail.BilledTax /*Billed Measures*/
        ,JCRevDetail.ReceivedAmt /*Received Measure*/
		,isnull(JCRevDetail.BilledAmt,0)-isnull(JCRevDetail.CurrentRetainAmt,0)-isnull(JCRevDetail.ReceivedAmt,0) as CurrentReceivable /*Current Receivables*/
        ,JCRevDetail.CurrentRetainAmt /*Retainage*/
		--,case when viDim_ARInvoice.OpenYN='Y' then datediff(dd,getdate(),viDim_ARInvoice.DueDate) else 0 end as DaysDue
		,JCRevDetail.PendingContractChgAmt
        ,JCRevDetail.EstRevenueComplete 
        

From JCRevDetail With (NoLock)
Join vDDBICompanies on vDDBICompanies.Co=JCRevDetail.JCCo
Join bJCCO With (NoLock) on bJCCO.JCCo=JCRevDetail.JCCo
Left Join bPMCO With (NoLock) on bPMCO.PMCo=JCRevDetail.JCCo
Join bJCCM With (NoLock) on bJCCM.JCCo=JCRevDetail.JCCo and bJCCM.Contract=JCRevDetail.Contract
Left Join bARCM With (NoLock) on bARCM.CustGroup=bJCCM.CustGroup and bARCM.Customer=bJCCM.Customer
Left Join bJCCI With (NoLock) on bJCCI.JCCo=JCRevDetail.JCCo and bJCCI.Contract=JCRevDetail.Contract and bJCCI.Item=JCRevDetail.ContractItem
Left Join bJCDM With (NoLock) on bJCDM.JCCo=JCRevDetail.JCCo and bJCDM.Department=bJCCI.Department
Left Join bGLFP With (NoLock) on bGLFP.GLCo=isnull(JCRevDetail.GLCo,bJCCO.GLCo) and bGLFP.Mth=JCRevDetail.Mth
--Join viDim_GLFiscalMth With (NoLock) on viDim_GLFiscalMth.GLCo=bGLFP.GLCo and viDim_GLFiscalMth.Mth=bGLFP.Mth and viDim_GLFiscalMth.FiscalPd=bGLFP.FiscalPd
Left Join ContractFirstJob C on C.JCCo=JCRevDetail.JCCo and C.Contract=JCRevDetail.Contract
Left Join bJCJM With (NoLock) on bJCJM.JCCo=C.JCCo and bJCJM.Job=C.Job  
Left Join bJCMP With (NoLock) on bJCMP.JCCo=bJCJM.JCCo and bJCMP.ProjectMgr=bJCJM.ProjectMgr
/*Join viDim_JCDeptContract_Hierarchy With (NoLock) 
                                 on viDim_JCDeptContract_Hierarchy.JCCo=JCRevDetail.JCCo
                                 and viDim_JCDeptContract_Hierarchy.Contract=JCRevDetail.Contract
                                 and viDim_JCDeptContract_Hierarchy.Item=JCRevDetail.ContractItem*/
--Left Join bARTH on bARTH.ARCo=JCRevDetail.ARCo and bARTH.Mth=JCRevDetail.Mth and bARTH.ARTrans=JCRevDetail.ARTrans
--Left Join viDim_ARInvoice on viDim_ARInvoice.ARCo=JCRevDetail.ARCo and viDim_ARInvoice.Mth=JCRevDetail.Mth and viDim_ARInvoice.ARTrans=JCRevDetail.ARTrans





GO
GRANT SELECT ON  [dbo].[viFact_JCRevenueDetail] TO [public]
GRANT INSERT ON  [dbo].[viFact_JCRevenueDetail] TO [public]
GRANT DELETE ON  [dbo].[viFact_JCRevenueDetail] TO [public]
GRANT UPDATE ON  [dbo].[viFact_JCRevenueDetail] TO [public]
GO
