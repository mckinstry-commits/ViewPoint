SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[vrvJCNetCashFlow]

/*****
 Created:  8/10/11 DH
 Modified: 
 Usage:  Returns net cash flow amounts for SSRS reports by JCCo, Contract, and Month
 
 ******/

--Get JC Cost and Revenue amounts summarized by JC Company, Contract, and Month

AS

WITH cteJCCostRev (JCCo, Contract, Mth, ReceivedAmt, ActualCost)

AS


(
 SELECT JCIP.JCCo,
		JCIP.Contract,
		JCIP.Mth,
		sum(ReceivedAmt) as ReceivedAmt,
		null as ActualCost
 FROM JCIP WITH (NOLOCK)
 GROUP BY JCIP.JCCo,
		  JCIP.Contract,
		  JCIP.Mth
 HAVING sum(ReceivedAmt)<>0		  

 UNION ALL

 SELECT JCJM.JCCo,
	    JCJM.Contract,
	    JCCP.Mth,
	    null as ReceivedAmt,
	    sum(ActualCost) as ActualCost
 FROM JCCP WITH (NOLOCK)
 INNER JOIN JCJM WITH (NOLOCK) ON
	  JCJM.JCCo = JCCP.JCCo AND
	  JCJM.Job = JCCP.Job
 GROUP BY JCJM.JCCo,
	      JCJM.Contract,
	      JCCP.Mth	   
 HAVING sum(ActualCost)<>0	       
 
 ),
 
 --Summarize cteJCCostRev by JCCo, Contract, Mth
 
 cteJCCostRevByContract (JCCo, Contract, Mth, ReceivedAmt, ActualCost)
 
 as
 
 (SELECT  cteJCCostRev.JCCo,
		 cteJCCostRev.Contract,
		 cteJCCostRev.Mth,
		 isnull(sum(cteJCCostRev.ReceivedAmt),0)  as ReceivedAmt,
		 isnull(sum(cteJCCostRev.ActualCost),0)  as ActualCost
  		 
		
 FROM cteJCCostRev
 GROUP BY cteJCCostRev.JCCo,
		  cteJCCostRev.Contract,
		  cteJCCostRev.Mth),
 
 --Get Running Total To Date amounts by JCCo, Contract, and Month.
 cteJCCostRevToDate (JCCo, Contract, Mth, PreviousMth, ReceivedAmt, ActualCost, ReceivedAmtToDate, ActualCostToDate)
 
 AS
 
 (
 SELECT  cteJCCostRevByContract.JCCo,
		 cteJCCostRevByContract.Contract,
		 cteJCCostRevByContract.Mth,
		 max(case when Previous.Mth < cteJCCostRevByContract.Mth then Previous.Mth end) as PreviousMth,
		 max(cteJCCostRevByContract.ReceivedAmt) as ReceivedAmt,
		 max(cteJCCostRevByContract.ActualCost) as ActualCost,
		 isnull(sum(Previous.ReceivedAmt),0)  as ReceivedAmtToDate,
		 isnull(sum(Previous.ActualCost),0)  as ActualCostToDate
		
 FROM cteJCCostRevByContract  
 LEFT OUTER JOIN cteJCCostRevByContract Previous ON
		Previous.JCCo = cteJCCostRevByContract.JCCo AND
		Previous.Contract = cteJCCostRevByContract.Contract AND
		Previous.Mth<=cteJCCostRevByContract.Mth
 
 GROUP BY cteJCCostRevByContract.JCCo,
		  cteJCCostRevByContract.Contract,
		  cteJCCostRevByContract.Mth
 )
  
 --Return Results for the report.  Get Unpaid amount from function vf_rptJCOpenPayable
 
 SELECT cteJCCostRevToDate.JCCo,
		cteJCCostRevToDate.Contract,
		Mth,
		PreviousMth,
		ReceivedAmt,
		ReceivedAmtToDate,
		ActualCost,
		ActualCostToDate,
		vf_rptJCOpenPayable.Unpaid as UnPaidToDate,
		vf_rptJCOpenPayable.UnpaidPrevious,
		ActualCostToDate - isnull(Unpaid,0) as PaidToDate,
		ReceivedAmtToDate - (ActualCostToDate - isnull(Unpaid,0)) as NetCashFlowToDate,
		case when (ReceivedAmtToDate - (ActualCostToDate - isnull(Unpaid,0))) <= 0 then 1 else 0 end as NetCashIsNegative,
		case when (ReceivedAmtToDate - (ActualCostToDate - isnull(Unpaid,0))) > 0 then 1 else 0 end as NetCashIsPositive,
		vf_rptJCOpenPayable.Unpaid - isnull(vf_rptJCOpenPayable.UnpaidPrevious,0) as UnpaidMonthDelta,
		ActualCost - (vf_rptJCOpenPayable.Unpaid - isnull(vf_rptJCOpenPayable.UnpaidPrevious,0)) as PaidMonthDelta,
		ReceivedAmt - (ActualCost - (vf_rptJCOpenPayable.Unpaid - isnull(vf_rptJCOpenPayable.UnpaidPrevious,0))) as NetCashFlowMonthDelta
		
  FROM cteJCCostRevToDate 		
 OUTER APPLY vf_rptJCOpenPayable (JCCo, Contract, PreviousMth, Mth)	   
 
	   
	   

GO
GRANT SELECT ON  [dbo].[vrvJCNetCashFlow] TO [public]
GRANT INSERT ON  [dbo].[vrvJCNetCashFlow] TO [public]
GRANT DELETE ON  [dbo].[vrvJCNetCashFlow] TO [public]
GRANT UPDATE ON  [dbo].[vrvJCNetCashFlow] TO [public]
GRANT SELECT ON  [dbo].[vrvJCNetCashFlow] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvJCNetCashFlow] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvJCNetCashFlow] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvJCNetCashFlow] TO [Viewpoint]
GO
