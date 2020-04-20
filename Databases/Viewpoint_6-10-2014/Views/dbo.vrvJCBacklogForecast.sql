SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE View [dbo].[vrvJCBacklogForecast]

As

/**********************************************************************
 * Created: DH  10/14/09
 * 
 * 
 * A view that combines Revenue (from the Contract) Cost (from 
 * the Job), and JC Forecast data into one view.  The first two select statements
 * return the same information as the brvJCCostRevenue view.  The last select statement
 * returns information from JCForecastMonth.
 * 
 *
 * The following standard reports use this view: JC Backlog Forecast Drilldown
 * (landscape/portrait)
 *
 * Related views: 
 *
 **********************************************************************/


--WITH
	/*Projected Month CTE returns a month for the client to sort off of to get the 
	  appropriate Projected dollar amount for each item.  This allows the client to provide
	  a ThroughMonth parameter and exclude items that did not have a projected dollar amount
	  as of the provided date.  

	  The Min(p.Mth) returns the minimum month for each each unique JCCP/JCJP row match. */
/*	ProjMth AS
	(SELECT j.JCCo, j.Contract, j.Item, MIN(p.Mth) AS ProjMth 
	 FROM	JCCP p With (NoLock)
				INNER JOIN 
			JCJP j With (NoLock) 
				ON j.JCCo			= p.JCCo 
				AND j.Job			= p.Job 
				AND j.PhaseGroup	= p.PhaseGroup 
				AND j.Phase			= p.Phase
	 WHERE (p.ProjCost <> 0 OR p.ProjPlug = 'Y')
	 GROUP BY j.JCCo, j.Contract, j.Item) */

With ContractFirstJob 
as
(Select JCCo, Contract, min(Job) as MinJob From bJCJM With (NoLock)
 Group By JCCo, Contract), /*CTE to get First Job by Contract*/
                          /*Used for returning PM on first job assigned to contract*/

	/*The ProjectedRevenue CTE is the entire JCIP table with a Row_Number() function applied and grouped by 
	  Company, Contract and Item. */
ProjectedRevenue
    (JCCo,
	 Contract,
	 Item,
	 Mth,
	 ContractAmt,
	 ProjDollars,
	 RowNumber)
	 
   AS 
	(SELECT	 JCCo 
			 ,Contract
			 ,Item
			 ,Mth
			 ,ContractAmt
			 ,ProjDollars
			 ,Row_Number() OVER (Partition BY JCCo,Contract,Item ORDER BY JCCo,Contract,Item,Mth) AS RowNumber 
	 FROM JCIP With (NoLock)
	 /*Any values that do not match the following criteria have values in other columns not relevant to Projections
	   and so should not be evaluated.  */
	 WHERE ProjDollars<>0 OR ContractAmt <> 0),

ProjectedRevenue_with_Previous

/*CTE that selects Contract Amount and Projected Dollars by Contract/Item/Mth.
   PrevProjDollars and PrevContractAmt are running totals of previous amounts prior to the month on the current row

   Estimated Rev Adjustment calculated according to 4 different cases
	 
        - Projected Rev exists in current AND prior months:  Use Projected
		- Projected Rev exists in current month only:  Use Projected, reverse previous contract amounts
		- Projected Rev current + Projected Rev prior = 0 AND Prev Projected<>0:
             (Contract Amt in current month + Contract Amt in prior months) - Prev Projected (reverse previous projected).
		- Projected Rev current + Projected Rev prior = 0 AND Prev Projected=0:
		     Use Contract Amt
*/
	 

(JCCo
,Contract
,Item
,Mth
,ContractAmt
,ProjDollars
,PrevProjDollars
,PrevContractAmt
,EstRevComplete)

as

(select 

	P.JCCo
,	P.Contract
,	P.Item
,	P.Mth
,	max(P.ContractAmt) as ContractAmt /*Contract Amt in current month*/
,	max(P.ProjDollars) as ProjDollars /*Projected Rev in current month*/
,	sum(Prev.ProjDollars) as PrevProjDollars /*sum of Projected Rev for all prior months*/
,	sum(Prev.ContractAmt) as PrevContractAmt /*sum of Contract Amt for all prior months*/

			  /*Use Projected if Projected exists (current and/or prior months)*/
,	case when isnull(max(P.ProjDollars),0)+isnull(sum(Prev.ProjDollars),0)<>0 and isnull(sum(Prev.ProjDollars),0)<>0
             then isnull(max(P.ProjDollars),0) 

              /*First Projection for item, reverse previous Contract Amt*/
		 when isnull(max(P.ProjDollars),0)+isnull(sum(Prev.ProjDollars),0)<>0 and isnull(sum(Prev.ProjDollars),0)=0
		     then isnull(max(P.ProjDollars),0) - isnull(sum(Prev.ContractAmt),0) 

			 /*If Total Projected is set back to 0 (current + prior=0), add total contract amt and reverse prior projected*/
		 when isnull(max(P.ProjDollars),0)+isnull(sum(Prev.ProjDollars),0)=0 and isnull(sum(Prev.ProjDollars),0)<>0
			 then (isnull(max(P.ContractAmt),0) + isnull(sum(Prev.ContractAmt),0)) - isnull(sum(Prev.ProjDollars),0) 

		    /*- Projected Rev current + Projected Rev prior = 0 AND Prev Projected=0: Use Contract Amt*/
		 when isnull(max(P.ProjDollars),0)+isnull(sum(Prev.ProjDollars),0)=0 and isnull(sum(Prev.ProjDollars),0)=0
			 then isnull(max(P.ContractAmt),0) 

    end as EstRevComplete

FROM 
	ProjectedRevenue P 
		LEFT OUTER JOIN 
	ProjectedRevenue Prev 
		ON	 P.RowNumber	    > Prev.RowNumber
		AND  P.JCCo				= Prev.JCCo
		AND  P.Contract			= Prev.Contract
		AND  P.Item				= Prev.Item

Group by
	P.JCCo
,	P.Contract
,	P.Item
,	P.Mth)

,JCCostProjMth

(JCCo,
 Contract,
 Item,
 FirstProjMth)

as

(Select bJCJP.JCCo,
	   bJCJP.Contract,
	   bJCJP.Item,
       min(bJCCP.Mth) as ProjMth
From bJCCP With (NoLock)
Join bJCJP With (NoLock) on bJCJP.JCCo=bJCCP.JCCo and bJCJP.Job=bJCCP.Job and bJCJP.PhaseGroup=bJCCP.PhaseGroup
          and bJCJP.Phase=bJCCP.Phase
Where bJCCP.ProjCost <> 0 or bJCCP.ProjPlug='Y'
Group By bJCJP.JCCo, bJCJP.Contract, bJCJP.Item
        
),

EstCostComplete
	(JCCo,
	 Job,
	 PhaseGroup,
	 Phase,
	 CostType,
	 Mth,
	 EstCostComplete)

as

(Select bJCCP.JCCo,
	   bJCCP.Job,
	   bJCCP.PhaseGroup,
	   bJCCP.Phase,
	   bJCCP.CostType,
	   max(JCCostProjMth.FirstProjMth), 	
       sum(CurrEstCost)*-1 as EstCostComplete

From bJCCP With (NoLock)
Join bJCCO With (NoLock) on bJCCO.JCCo=bJCCP.JCCo
Join bJCJP With (NoLock) on bJCJP.JCCo=bJCCP.JCCo and bJCJP.Job=bJCCP.Job and bJCJP.PhaseGroup=bJCCP.PhaseGroup
          and bJCJP.Phase=bJCCP.Phase
Join JCCostProjMth With (NoLock) on JCCostProjMth.JCCo=bJCJP.JCCo
                    and JCCostProjMth.Contract=bJCJP.Contract
				    and JCCostProjMth.Item=bJCJP.Item
				    and bJCCP.Mth<JCCostProjMth.FirstProjMth
    
Group By bJCCP.JCCo, bJCCP.Job, bJCCP.PhaseGroup, bJCCP.Phase, bJCCP.CostType)

,EstCostRev

as

(Select JCCo,
	   Contract,
	   Mth,
	   sum(ContractAmt) as ContractAmt,
	   CurrEstCost=0.00,
	   ContractAmtTotalToDate=0.00,
	   CurrEstCostTotalToDate=0.00
From JCIP
Group By JCCo, Contract, Mth

union all

select JCJP.JCCo,
	   JCJP.Contract,
	   JCCP.Mth,
	   ContractAmt=0.00,
	   sum(CurrEstCost) as CurrEstCost,
	   ContractAmtTotalToDate=0.00,
	   CurrEstCostTotalToDate=0.00
From JCCP
Join JCJP With (NoLock) 
		ON  JCCP.JCCo		= JCJP.JCCo 
		AND JCCP.Job		= JCJP.Job 
		AND JCCP.Phase		= JCJP.Phase 
		AND JCCP.PhaseGroup = JCJP.PhaseGroup 
Group by JCJP.JCCo,
	   JCJP.Contract,
	   JCCP.Mth
union all

Select JCCo,
	   Contract,
	   '1/1/1950',
	   ContractAmt=0.00,
	   CurrEstCost=0.00,
	   ContractAmtTotalToDate=ContractAmt,
	   CurrEstCostTotalToDate=0.00
From JCCM With (NoLock) 


union all

select JCJP.JCCo,
	   JCJP.Contract,
	   '1/1/1950',
	   ContractAmt=0.00,
	   CurrEstCost=sum(case when JCCM.ContractStatus = 0 then OrigCost else 0 end),
	   ContractAmtTotalToDate=0.00,
	   CurrEstCostTotalToDate=sum(JCCH.OrigCost)
From JCCH
Join JCJP With (NoLock) 
		ON  JCJP.JCCo		= JCCH.JCCo 
		AND JCJP.Job		= JCCH.Job 
		AND JCJP.Phase		= JCCH.Phase 
		AND JCJP.PhaseGroup = JCCH.PhaseGroup 
Join JCCM With (NoLock)
		ON JCCM.JCCo=JCJP.JCCo
		and JCCM.Contract=JCJP.Contract
Group by JCJP.JCCo,
	   JCJP.Contract

)

,EstCostRevByMth

as

(Select JCCo,
	    Contract,
		Mth,
		sum(ContractAmt) as ContractAmt,
		sum(CurrEstCost) as CurrEstCost,
	    sum(ContractAmtTotalToDate) as ContractAmtTotalToDate,
	    sum(CurrEstCostTotalToDate) as CurrEstCostTotalToDate
 From EstCostRev
Group by JCCo, Contract, Mth
)

,LastEarnedMonth

as

(select JCJP.JCCo,
	   JCJP.Contract,
	   max(case when JCCP.ActualCost<>0 then JCCP.Mth end) as LastEarnedMonth

From JCCP
Join JCJP With (NoLock) 
		ON  JCJP.JCCo		= JCCP.JCCo 
		AND JCJP.Job		= JCCP.Job 
		AND JCJP.Phase		= JCCP.Phase 
		AND JCJP.PhaseGroup = JCCP.PhaseGroup 
Group By JCJP.JCCo, JCJP.Contract)

,JCF /*JC Forecast*/

as

(select JCForecastMonth.JCCo,
		JCForecastMonth.Contract,
		JCForecastMonth.ForecastMonth,
	    JCForecastMonth.RevenuePct,
		JCForecastMonth.CostPct,
		sum(c.ContractAmt) as ContractAmt,
		sum(c.CurrEstCost) as CurrEstCost,
		sum(ContractAmtTotalToDate) as ContractAmtTotalToDate,
		sum(CurrEstCostTotalToDate) as CurrEstCostTotalToDate,
	    Row_Number() Over (Partition By JCForecastMonth.JCCo, JCForecastMonth.Contract
					Order By JCForecastMonth.JCCo, JCForecastMonth.Contract, JCForecastMonth.ForecastMonth) as MonthNumber
 From JCForecastMonth 
 Left Join EstCostRevByMth c
 on c.JCCo=JCForecastMonth.JCCo and c.Contract=JCForecastMonth.Contract and c.Mth<=JCForecastMonth.ForecastMonth
 Group By JCForecastMonth.JCCo,
		JCForecastMonth.Contract,
		JCForecastMonth.ForecastMonth,
	    JCForecastMonth.RevenuePct,
		JCForecastMonth.CostPct
)

,JCF_W_Prev /*JC Forecast with Previous*/

as

(Select  JCF.JCCo,
	    JCF.Contract,
		JCF.ForecastMonth,
		JCF.MonthNumber,
		JCF.RevenuePct,
		JCF.CostPct,
		JCF.ContractAmtTotalToDate,
		JCF.CurrEstCostTotalToDate,
		JCF.CurrEstCost,
		JCF.ContractAmt,
		JCF_Prev.CurrEstCost as CurrEstCostPrev,
		JCF_Prev.ContractAmt as ContractAmtPrev,
		JCF_Prev.RevenuePct as PrevRevPct,
		JCF_Prev.CostPct as PrevCostPct,
		JCF.ContractAmt*JCF.RevenuePct as ForecastRevenue,
		JCF_Prev.ContractAmt*JCF_Prev.RevenuePct as ForecastRevenuePrevious,
		JCF.CurrEstCost*JCF.CostPct as ForecastCost,
		JCF_Prev.CurrEstCost*JCF_Prev.CostPct as ForecastCostPrevious
from JCF
Left Join JCF JCF_Prev on JCF_Prev.JCCo=JCF.JCCo and
		    JCF_Prev.Contract=JCF.Contract and
			JCF_Prev.MonthNumber+1 = JCF.MonthNumber),

PP

as

(Select	
     PW.JCCo
	,PW.PotentialProject
	,PW.ProjectMgr
	,PW.AwardProbPct
	,PCF.ForecastMonth
	,GLFP.FiscalYr
	,PCF.RevenuePct
	,PCF.CostPct
	,PW.RevenueEst*PCF.RevenuePct as ForecastRevenueCumulative
    ,PW.CostEst*PCF.CostPct as ForecastCostCumulative
	,Row_Number() Over (Partition By PW.JCCo, PW.PotentialProject
					Order By PW.JCCo, PW.PotentialProject, PCF.ForecastMonth) as MonthNumber


From PCPotentialWork PW With (NoLock)
Join PCForecastMonth PCF With (NoLock) on PCF.JCCo=PW.JCCo
						and PCF.PotentialProject=PW.PotentialProject
 
Join JCCO With (NoLock) on JCCO.JCCo=PW.JCCo
Left Join GLFP With (NoLock) on GLFP.GLCo=JCCO.GLCo and GLFP.Mth=PCF.ForecastMonth
Where Awarded='N' and AllowForecast='Y' )

-- Revenue
SELECT  
	JCIP.JCCo
,	JCIP.Contract
,	JCCM.ContractStatus
,	JCMP.ProjectMgr
,	JCMP.Name
,	0 as ActiveOrPotential
,	JCIP.Item

	/*Proj Mth is not used on the revenue side, but for compatability has been set to 12/1/2050 
	  to prevent issues with users who use the old WIP report and don't use revenue projections*/
,	ProjMth = JCIP.Mth
,	JCIP.Mth
,	'1/1/1950' as ForecastMonth /*Placeholder for ForecastMonth*/
,	JCIP.OrigContractAmt
,	JCIP.OrigContractUnits
,	JCIP.OrigUnitPrice
,	JCIP.ContractAmt
,	JCIP.ContractUnits
,	JCIP.CurrentUnitPrice
,	JCIP.BilledUnits
,	JCIP.BilledAmt
,	JCIP.ReceivedAmt
,	JCIP.CurrentRetainAmt
,	JCIP.BilledTax
,	JCIP.ProjUnits
,	JCIP.ProjDollars
,	JCIP.ProjPlug
,	EstRevComplete=0.00
	--Placeholders for JC Cost portion of UNION ALL
    ,Job=null				,PhaseGroup=null		,Phase=null				,CostType=null 
	,ActualHours= 0.00		,ActualUnits=0.00		,ActualCost=0.00		,OrigEstHours=0.00
	,OrigEstUnits=0.00  	,OrigEstCost=0.00		,CurrEstHours=0.00		,CurrEstUnits=0.00
	,CurrEstCost=0.00		,ProjHours=0.00			,ProjRevUnits=0.00		,ProjCost=0.00
	,ForecastHours=0.00		,ForecastUnits=0.00		,ForecastCost=0.00		,TotalCmtdUnits=0.00
	,TotalCmtdCost=0.00		,RemainCmtdUnits=0.00	,RemainCmtdCost=0.00	,RecvdNotInvcdUnits=0.00
	,RecvdNotInvcdCost=0.00 ,EstCostComplete=0.00
	
	--Placeholders for JC Forecast fields
	,0.00 as RevenuePct
	,0.00 as CostPct
	,0.00 as ForecastRevenue
    ,0.00 as ForecastCostEstimate
	,0.00 as ForecastRevenueMonth
	,0.00 as ForecastCostMonth
	,0.00 as ContractAmtTotalToDate
	,0.00 as CurrEstCostTotalToDate
	,null as AwardProbPct
	,null as AwardProbPctRange
	,null as AwardProbPctRangeDesc
	,isnull(l.LastEarnedMonth,'1/1/1950') as LastEarnedMonth
FROM
	JCIP With (NoLock)
	Join JCCM With (NoLock) on JCCM.JCCo=JCIP.JCCo
							and JCCM.Contract=JCIP.Contract
	Left Join ContractFirstJob c on c.JCCo=JCIP.JCCo
							and c.Contract=JCIP.Contract
	Left Join JCJM on JCJM.JCCo=c.JCCo
			  and JCJM.Job=c.MinJob
	Left Join JCMP on JCMP.JCCo=c.JCCo
				   and JCMP.ProjectMgr=JCJM.ProjectMgr
	Left Join LastEarnedMonth l on l.JCCo=JCIP.JCCo
							   and  l.Contract = JCIP.Contract
Where JCCM.ContractStatus = 1

UNION ALL

SELECT  
	P.JCCo
,	P.Contract
,	JCCM.ContractStatus
,	JCMP.ProjectMgr
,	JCMP.Name
,	0 as ActiveOrPotential
,	P.Item

	/*Proj Mth is not used on the revenue side, but for compatability has been set to 12/1/2050 
	  to prevent issues with users who use the old WIP report and don't use revenue projections*/
,	ProjMth = P.Mth
,	P.Mth
,	'1/1/1950' as ForecastMonth /*Placeholder for ForecastMonth*/
	--Placeholders for JC Revenue portion of UNION ALL
	,OrigContractAmt=0.00,	OrigContractUnits=0.00,	OrigUnitPrice=0.00,	ContractAmt=0.00
	,ContractUnits=0.00,	CurrentUnitPrice=0.00,	BilledUnits=0.00,	BilledAmt=0.00
	,ReceivedAmt=0.00,	CurrentRetainAmt=0.00,	BilledTax=0.00,	ProjUnits=0.00
	,ProjDollars=0.00, ProjPlug=NULL

	,P.EstRevComplete

	--Placeholders for JC Cost portion of UNION ALL
    ,Job=null				,PhaseGroup=null		,Phase=null				,CostType=null 
	,ActualHours= 0.00		,ActualUnits=0.00		,ActualCost=0.00		,OrigEstHours=0.00
	,OrigEstUnits=0.00  	,OrigEstCost=0.00		,CurrEstHours=0.00		,CurrEstUnits=0.00
	,CurrEstCost=0.00		,ProjHours=0.00			,ProjRevUnits=0.00		,ProjCost=0.00
	,ForecastHours=0.00		,ForecastUnits=0.00		,ForecastCost=0.00		,TotalCmtdUnits=0.00
	,TotalCmtdCost=0.00		,RemainCmtdUnits=0.00	,RemainCmtdCost=0.00	,RecvdNotInvcdUnits=0.00
	,RecvdNotInvcdCost=0.00 ,EstCostComplete=0.00
	
	--Placeholders for JC Forecast fields
	,0.00 as RevenuePct
	,0.00 as CostPct
	,0.00 as ForecastRevenue
    ,0.00 as ForecastCostEstimate
	,0.00 as ForecastRevenueMonth
	,0.00 as ForecastCostMonth
	,0.00 as ContractAmtTotalToDate
	,0.00 as CurrEstCostTotalToDate
	,null as AwardProbPct
	,null as AwardProbPctRange
	,null as AwardProbPctRangeDesc
	,isnull(l.LastEarnedMonth,'1/1/1950')
From ProjectedRevenue_with_Previous P
	 Join JCCM With (NoLock) on JCCM.JCCo=P.JCCo
							and JCCM.Contract=P.Contract
	 Left Join ContractFirstJob c on c.JCCo=P.JCCo
							and c.Contract=P.Contract
	 Left Join JCJM on JCJM.JCCo=c.JCCo
			  and JCJM.Job=c.MinJob
	 Left Join JCMP on JCMP.JCCo=c.JCCo
				   and JCMP.ProjectMgr=JCJM.ProjectMgr
	 Left Join LastEarnedMonth l on l.JCCo=P.JCCo
							   and  l.Contract = P.Contract
Where JCCM.ContractStatus = 1

UNION ALL

-- Cost
SELECT 
	JCCP.JCCo
,	JCJP.Contract
,	JCCM.ContractStatus
,	JCMP.ProjectMgr
,	JCMP.Name
,   0 as ActiveOrPotential
,	JCJP.Item

	/*Use the ProjMth column client-side to exclude cost projections that do not fall within
	  a certain date parameter range.  The calculation would be something like: 
	  If ProjMth <= @ThroughMth Then ProjCost Else CurrEstCost
	  
	  The ISNULL ensures that all records can be returned by providing a ThroughMth <= 12/1/2050.*/

,	JCCostProjMth.FirstProjMth As ProjMth
,	JCCP.Mth
,	'1/1/1950' as ForecastMonth /*Placeholder for ForecastMonth*/
       
	--Placeholders for JC Revenue portion of UNION ALL
	,null	,null	,null	,null
	,null	,null	,null	,null
	,null	,null	,null	,null
	,null	,null	,null

,	JCCP.Job
,	JCCP.PhaseGroup
,	JCCP.Phase
,	JCCP.CostType
,	JCCP.ActualHours
,	JCCP.ActualUnits
,	JCCP.ActualCost
,	JCCP.OrigEstHours
,	JCCP.OrigEstUnits
,	JCCP.OrigEstCost
,	JCCP.CurrEstHours
,	JCCP.CurrEstUnits
,	JCCP.CurrEstCost
,	JCCP.ProjHours
,	JCCP.ProjUnits
,	JCCP.ProjCost
,	JCCP.ForecastHours
,	JCCP.ForecastUnits
,	JCCP.ForecastCost
,	JCCP.TotalCmtdUnits
,	JCCP.TotalCmtdCost
,	JCCP.RemainCmtdUnits
,	JCCP.RemainCmtdCost
,	JCCP.RecvdNotInvcdUnits
,	JCCP.RecvdNotInvcdCost
,    case when JCCostProjMth.FirstProjMth<=JCCP.Mth 
             then isnull(JCCP.ProjCost,0) 
        else isnull(JCCP.CurrEstCost,0) end as EstCostComplete
	--Placeholders for JC Forecast fields
	,0.00 as RevenuePct
	,0.00 as CostPct
	,0.00 as ForecastRevenue
    ,0.00 as ForecastCostEstimate
	,0.00 as ForecastRevenueMonth
	,0.00 as ForecastCostMonth
	,0.00 as ContractAmtTotalToDate
	,0.00 as CurrEstCostTotalToDate
	,null as AwardProbPct
	,null as AwardProbPctRange
	,null as AwardProbPctRangeDesc
	,isnull(l.LastEarnedMonth,'1/1/1950')
FROM 
	JCCP With (NoLock)
		INNER JOIN 
	JCJP With (NoLock) 
		ON  JCCP.JCCo		= JCJP.JCCo 
		AND JCCP.Job		= JCJP.Job 
		AND JCCP.Phase		= JCJP.Phase 
		AND JCCP.PhaseGroup = JCJP.PhaseGroup 
   Join JCCM With (NoLock) on JCCM.JCCo=JCJP.JCCo
							and JCCM.Contract=JCJP.Contract

   Left Join JCCostProjMth With (NoLock) on JCCostProjMth.JCCo=JCJP.JCCo
                    and JCCostProjMth.Contract=JCJP.Contract
				    and JCCostProjMth.Item=JCJP.Item
    Left Join ContractFirstJob c on c.JCCo=JCJP.JCCo
							and c.Contract=JCJP.Contract
	Left Join JCJM on JCJM.JCCo=c.JCCo
			  and JCJM.Job=c.MinJob
	Left Join JCMP on JCMP.JCCo=c.JCCo
				   and JCMP.ProjectMgr=JCJM.ProjectMgr
	Left Join LastEarnedMonth l on l.JCCo=JCJP.JCCo
							   and  l.Contract = JCJP.Contract
Where JCCM.ContractStatus = 1

UNION ALL

SELECT 
	ECP.JCCo
,	JCJP.Contract
,	JCCM.ContractStatus
,	JCMP.ProjectMgr
,	JCMP.Name
,	0 as ActiveOrPotential
,	JCJP.Item

	/*Use the ProjMth column client-side to exclude cost projections that do not fall within
	  a certain date parameter range.  The calculation would be something like: 
	  If ProjMth <= @ThroughMth Then ProjCost Else CurrEstCost
	  
	  The ISNULL ensures that all records can be returned by providing a ThroughMth <= 12/1/2050.*/

,	ECP.Mth As ProjMth
,	ECP.Mth
,	'1/1/1950' as ForecastMonth /*Placeholder for ForecastMonth*/
       
	--Placeholders for JC Revenue portion of UNION ALL
	,null	,null	,null	,null
	,null	,null	,null	,null
	,null	,null	,null	,null
	,null	,null	,null

,	ECP.Job
,	ECP.PhaseGroup
,	ECP.Phase
,	ECP.CostType
,	ActualHours=0.00
,	ActualUnits=0.00
,	ActualCost=0.00
,	OrigEstHours=0.00
,	OrigEstUnits=0.00
,	OrigEstCost=0.00
,	CurrEstHours=0.00
,	CurrEstUnits=0.00
,	CurrEstCost=0.00
,	ProjHours=0.00
,	ProjUnits=0.00
,	ProjCost=0.00
,	ForecastHours=0.00
,	ForecastUnits=0.00
,	ForecastCost=0.00
,	TotalCmtdUnits=0.00
,	TotalCmtdCost=0.00
,	RemainCmtdUnits=0.00
,	RemainCmtdCost=0.00
,	RecvdNotInvcdUnits=0.00
,	RecvdNotInvcdCost=0.00
,	ECP.EstCostComplete
	--Placeholders for JC Forecast fields
	,0.00 as RevenuePct
	,0.00 as CostPct
	,0.00 as ForecastRevenue
    ,0.00 as ForecastCostEstimate
	,0.00 as ForecastRevenueMonth
	,0.00 as ForecastCostMonth
	,0.00 as ContractAmtTotalToDate
	,0.00 as CurrEstCostTotalToDate
	,null as AwardProbPct
	,null as AwardProbPctRange
	,null as AwardProbPctRangeDesc
	,isnull(l.LastEarnedMonth,'1/1/1950')
FROM 
	EstCostComplete ECP With (NoLock)
		INNER JOIN 
	JCJP With (NoLock) 
		ON  ECP.JCCo		= JCJP.JCCo 
		AND ECP.Job		= JCJP.Job 
		AND ECP.Phase		= JCJP.Phase 
		AND ECP.PhaseGroup = JCJP.PhaseGroup 
	Join JCCM With (NoLock) on JCCM.JCCo=JCJP.JCCo
							and JCCM.Contract=JCJP.Contract
	Left Join ContractFirstJob c on c.JCCo=JCJP.JCCo
							and c.Contract=JCJP.Contract
	Left Join JCJM on JCJM.JCCo=c.JCCo
			  and JCJM.Job=c.MinJob
	Left Join JCMP on JCMP.JCCo=c.JCCo
				   and JCMP.ProjectMgr=JCJM.ProjectMgr
	Left Join LastEarnedMonth l on l.JCCo=JCJP.JCCo
							   and  l.Contract = JCJP.Contract
Where JCCM.ContractStatus = 1

UNION ALL

SELECT  
	JCF_W_Prev.JCCo
	,JCF_W_Prev.Contract
	,JCCM.ContractStatus
	,JCMP.ProjectMgr
	,JCMP.Name
	,0 as ActiveOrPotential
	,NULL /*Item*/

	/*Proj Mth is not used on the revenue side, but for compatability has been set to 12/1/2050 
	  to prevent issues with users who use the old WIP report and don't use revenue projections*/
	,ProjMth = '12/1/2050'
	,Mth = '1/1/1950' /*Month set to first possible month so that it's not filtered out in record selection*/
	,JCF_W_Prev.ForecastMonth
	--Placeholders for JC Revenue portion of UNION ALL
	,OrigContractAmt=0.00,	OrigContractUnits=0.00,	OrigUnitPrice=0.00,	ContractAmt=0.00
	,ContractUnits=0.00,	CurrentUnitPrice=0.00,	BilledUnits=0.00,	BilledAmt=0.00
	,ReceivedAmt=0.00,	CurrentRetainAmt=0.00,	BilledTax=0.00,	ProjUnits=0.00
	,ProjDollars=0.00, ProjPlug=NULL, EstRevComplete=0.00

	--Placeholders for JC Cost portion of UNION ALL
    ,Job=null				,PhaseGroup=null		,Phase=null				,CostType=null 
	,ActualHours= 0.00		,ActualUnits=0.00		,ActualCost=0.00		,OrigEstHours=0.00
	,OrigEstUnits=0.00  	,OrigEstCost=0.00		,CurrEstHours=0.00		,CurrEstUnits=0.00
	,CurrEstCost=0.00		,ProjHours=0.00			,ProjRevUnits=0.00		,ProjCost=0.00
	,ForecastHours=0.00		,ForecastUnits=0.00		,ForecastCost=0.00		,TotalCmtdUnits=0.00
	,TotalCmtdCost=0.00		,RemainCmtdUnits=0.00	,RemainCmtdCost=0.00	,RecvdNotInvcdUnits=0.00
	,RecvdNotInvcdCost=0.00, EstCostComplete=0.00
	,JCF_W_Prev.RevenuePct
	,JCF_W_Prev.CostPct
	,ForecastRevenue
    ,ForecastCost
	,isnull(ForecastRevenue,0)-isnull(ForecastRevenuePrevious,0) as ForecastRevenueMonth
	,isnull(ForecastCost,0)-isnull(ForecastCostPrevious,0) as ForecastCostMonth
	,ContractAmtTotalToDate
	,CurrEstCostTotalToDate
	,null as AwardProbPct
	,null as AwardProbPctRange
	,null as AwardProbPctRangeDesc
	,isnull(l.LastEarnedMonth,'1/1/1950')
From JCF_W_Prev
	Join JCCM With (NoLock) on JCCM.JCCo=JCF_W_Prev.JCCo
							and JCCM.Contract=JCF_W_Prev.Contract
	Left Join LastEarnedMonth l on l.JCCo=JCF_W_Prev.JCCo
							   and  l.Contract = JCF_W_Prev.Contract
	Left Join ContractFirstJob c on c.JCCo=JCF_W_Prev.JCCo
							and c.Contract=JCF_W_Prev.Contract
	Left Join JCJM on JCJM.JCCo=c.JCCo
			  and JCJM.Job=c.MinJob
	Left Join JCMP on JCMP.JCCo=c.JCCo
				   and JCMP.ProjectMgr=JCJM.ProjectMgr

Where JCCM.ContractStatus in (0,1)

UNION ALL

SELECT  
	 PP.JCCo
	,'zzzzzzzzzz' as Contract
	,1 as ContractStatus
	,PP.ProjectMgr
	,max(JCMP.Name)
	,ActiveOrPotential = 1
	,Null /*Item*/

	/*Proj Mth is not used on the revenue side, but for compatability has been set to 12/1/2050 
	  to prevent issues with users who use the old WIP report and don't use revenue projections*/
	,ProjMth = '12/1/2050'
	,Mth = '1/1/1950' /*Month set to first possible month so that it's not filtered out in record selection*/
	,'1/1/1950' as ForecastMonth
	--Placeholders for JC Revenue portion of UNION ALL
	,OrigContractAmt=0.00,	OrigContractUnits=0.00,	OrigUnitPrice=0.00,	ContractAmt=0.00
	,ContractUnits=0.00,	CurrentUnitPrice=0.00,	BilledUnits=0.00,	BilledAmt=0.00
	,ReceivedAmt=0.00,	CurrentRetainAmt=0.00,	BilledTax=0.00,	ProjUnits=0.00
	,ProjDollars=0.00, ProjPlug=NULL, EstRevComplete=0.00

	--Placeholders for JC Cost portion of UNION ALL
    ,Job=null				,PhaseGroup=null		,Phase=null				,CostType=null 
	,ActualHours= 0.00		,ActualUnits=0.00		,ActualCost=0.00		,OrigEstHours=0.00
	,OrigEstUnits=0.00  	,OrigEstCost=0.00		,CurrEstHours=0.00		,CurrEstUnits=0.00
	,CurrEstCost=0.00		,ProjHours=0.00			,ProjRevUnits=0.00		,ProjCost=0.00
	,ForecastHours=0.00		,ForecastUnits=0.00		,ForecastCost=0.00		,TotalCmtdUnits=0.00
	,TotalCmtdCost=0.00		,RemainCmtdUnits=0.00	,RemainCmtdCost=0.00	,RecvdNotInvcdUnits=0.00
	,RecvdNotInvcdCost=0.00, EstCostComplete=0.00
	,0 as RevPct
	,0 as CostPct
	,0 as ForecastRevenue
    ,0 as ForecastCost
	,sum(PP.ForecastRevenueCumulative) - isnull(sum(PP_Prev.ForecastRevenueCumulative),0) as ForecatRevenueMonth
	,sum(PP.ForecastCostCumulative) - isnull(sum(PP_Prev.ForecastCostCumulative),0) as ForecastCostMonth
	,0 as ContractAmtTotalToDate
	,0 as CurrEstCostTotalToDate
	,PP.AwardProbPct
	,case when PP.AwardProbPct < .50 then 1
		  when PP.AwardProbPct < .75 then 2
		  when PP.AwardProbPct < 1.0 then 3
	 end as AwardProbPctRange
	,case when PP.AwardProbPct < .50 then 'Less than 50%'
		  when PP.AwardProbPct < .75 then '50 - 75%'
		  when PP.AwardProbPct < 1.0 then '75 - 100%'
	 end as AwardProbPctRangeDesc
	,null as LastEarnedMonth
From PP
Left Join PP PP_Prev on PP_Prev.JCCo=PP.JCCo
				and PP_Prev.PotentialProject=PP.PotentialProject
				and PP_Prev.MonthNumber+1=PP.MonthNumber	
Left Join JCMP on JCMP.JCCo = PP.JCCo
			   and JCMP.ProjectMgr = PP.ProjectMgr
		  
Group By 	 PP.JCCo
			,PP.ProjectMgr
			,PP.AwardProbPct
			





GO
GRANT SELECT ON  [dbo].[vrvJCBacklogForecast] TO [public]
GRANT INSERT ON  [dbo].[vrvJCBacklogForecast] TO [public]
GRANT DELETE ON  [dbo].[vrvJCBacklogForecast] TO [public]
GRANT UPDATE ON  [dbo].[vrvJCBacklogForecast] TO [public]
GRANT SELECT ON  [dbo].[vrvJCBacklogForecast] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvJCBacklogForecast] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvJCBacklogForecast] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvJCBacklogForecast] TO [Viewpoint]
GO
