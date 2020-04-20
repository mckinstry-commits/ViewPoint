SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[vrvJCBacklogNoForecast]

as

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
		

-- Revenue
SELECT  
	JCIP.JCCo
,	JCIP.Contract
,	isnull(JCJM.ProjectMgr,0) as ProjectMgr
,	0 as ActiveOrPotential
,	JCIP.Item

	/*Proj Mth is not used on the revenue side, but for compatability has been set to 12/1/2050 
	  to prevent issues with users who use the old WIP report and don't use revenue projections*/
,	ProjMth = JCIP.Mth
,	JCIP.Mth
,	'12/1/2050' as ForecastMonth /*Placeholder for ForecastMonth*/
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
,isnull(l.LastEarnedMonth,'1/1/1950') as LastEarnedMonth
FROM
	JCIP With (NoLock)
	Join JCCM on JCCM.JCCo=JCIP.JCCo
			  and JCCM.Contract=JCIP.Contract
	/*Join JCCM_No_Forecast on JCCM_No_Forecast.JCCo=JCIP.JCCo
							and JCCM_No_Forecast.Contract=JCIP.Contract*/
	Left Join ContractFirstJob c on c.JCCo=JCIP.JCCo
							and c.Contract=JCIP.Contract
	Left Join JCJM on JCJM.JCCo=c.JCCo
			  and JCJM.Job=c.MinJob
	Left Join LastEarnedMonth l on
			l.JCCo = JCIP.JCCo
			and l.Contract=JCIP.Contract

Where JCCM.ContractStatus=1



UNION ALL

SELECT  
	P.JCCo
,	P.Contract
,	isnull(JCJM.ProjectMgr,0)
,	0 as ActiveOrPotential
,	P.Item

	/*Proj Mth is not used on the revenue side, but for compatability has been set to 12/1/2050 
	  to prevent issues with users who use the old WIP report and don't use revenue projections*/
,	ProjMth = P.Mth
,	P.Mth
,	'12/1/2050' as ForecastMonth /*Placeholder for ForecastMonth*/
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
	,isnull(l.LastEarnedMonth,'1/1/1950')
From ProjectedRevenue_with_Previous P
	 Join JCCM on JCCM.JCCo=P.JCCo
			  and JCCM.Contract=P.Contract
	 /*Join JCCM_No_Forecast on JCCM_No_Forecast.JCCo=P.JCCo
							and JCCM_No_Forecast.Contract=P.Contract*/
	 Left Join ContractFirstJob c on c.JCCo=P.JCCo
							and c.Contract=P.Contract
	 Left Join JCJM on JCJM.JCCo=c.JCCo
			  and JCJM.Job=c.MinJob
	 Left Join LastEarnedMonth l on
			l.JCCo = P.JCCo
			and l.Contract=P.Contract
Where JCCM.ContractStatus = 1



UNION ALL

-- Cost
SELECT 
	JCCP.JCCo
,	JCJP.Contract
,	isnull(JCJM.ProjectMgr,0)
,   0 as ActiveOrPotential
,	JCJP.Item

	/*Use the ProjMth column client-side to exclude cost projections that do not fall within
	  a certain date parameter range.  The calculation would be something like: 
	  If ProjMth <= @ThroughMth Then ProjCost Else CurrEstCost
	  
	  The ISNULL ensures that all records can be returned by providing a ThroughMth <= 12/1/2050.*/

,	JCCostProjMth.FirstProjMth As ProjMth
,	JCCP.Mth
,	'12/1/2050' as ForecastMonth /*Placeholder for ForecastMonth*/
       
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
,isnull(l.LastEarnedMonth,'1/1/1950')
FROM 
	JCCP With (NoLock)
		INNER JOIN 
	JCJP With (NoLock) 
		ON  JCCP.JCCo		= JCJP.JCCo 
		AND JCCP.Job		= JCJP.Job 
		AND JCCP.Phase		= JCJP.Phase 
		AND JCCP.PhaseGroup = JCJP.PhaseGroup 
	Join JCCM on JCCM.JCCo=JCJP.JCCo
			  and JCCM.Contract=JCJP.Contract
   /*Join JCCM_No_Forecast on JCCM_No_Forecast.JCCo=JCJP.JCCo
							and JCCM_No_Forecast.Contract=JCJP.Contract*/

   Left Join JCCostProjMth With (NoLock) on JCCostProjMth.JCCo=JCJP.JCCo
                    and JCCostProjMth.Contract=JCJP.Contract
				    and JCCostProjMth.Item=JCJP.Item
    Left Join ContractFirstJob c on c.JCCo=JCJP.JCCo
							and c.Contract=JCJP.Contract
	Left Join JCJM on JCJM.JCCo=c.JCCo
			  and JCJM.Job=c.MinJob
	Left Join LastEarnedMonth l on
			l.JCCo = JCJP.JCCo
			and l.Contract=JCJP.Contract

Where JCCM.ContractStatus = 1

UNION ALL

SELECT 
	ECP.JCCo
,	JCJP.Contract
,	isnull(JCJM.ProjectMgr,0)
,	0 as ActiveOrPotential
,	JCJP.Item

	/*Use the ProjMth column client-side to exclude cost projections that do not fall within
	  a certain date parameter range.  The calculation would be something like: 
	  If ProjMth <= @ThroughMth Then ProjCost Else CurrEstCost
	  
	  The ISNULL ensures that all records can be returned by providing a ThroughMth <= 12/1/2050.*/

,	ECP.Mth As ProjMth
,	ECP.Mth
,	'12/1/2050' as ForecastMonth /*Placeholder for ForecastMonth*/
       
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
,isnull(l.LastEarnedMonth,'1/1/1950')
FROM 
	EstCostComplete ECP With (NoLock)
		INNER JOIN 
	JCJP With (NoLock) 
		ON  ECP.JCCo		= JCJP.JCCo 
		AND ECP.Job		= JCJP.Job 
		AND ECP.Phase		= JCJP.Phase 
		AND ECP.PhaseGroup = JCJP.PhaseGroup 
	Join JCCM on JCCM.JCCo=JCJP.JCCo
			  and JCCM.Contract=JCJP.Contract
	/*Join JCCM_No_Forecast on JCCM_No_Forecast.JCCo=JCJP.JCCo
							and JCCM_No_Forecast.Contract=JCJP.Contract*/
	Left Join ContractFirstJob c on c.JCCo=JCJP.JCCo
							and c.Contract=JCJP.Contract
	Left Join JCJM on JCJM.JCCo=c.JCCo
			  and JCJM.Job=c.MinJob
	Left Join LastEarnedMonth l on
			l.JCCo = JCJP.JCCo
			and l.Contract=JCJP.Contract
Where JCCM.ContractStatus = 1

union all

Select
	JCF.JCCo
,	JCF.Contract
,	isnull(JCJM.ProjectMgr,0)
,   0 as ActiveOrPotential
,	Null as Item
,	Null As ProjMth
,	'1/1/1950' as Mth
,	JCF.ForecastMonth /*Placeholder for ForecastMonth*/
       
	--Placeholders for JC Revenue portion of UNION ALL
	,null	,null	,null	,null
	,null	,null	,null	,null
	,null	,null	,null	,null
	,null	,null	,null

--Placeholders for JC Cost portion of UNION ALL
    ,Job=null				,PhaseGroup=null		,Phase=null				,CostType=null 
	,ActualHours= 0.00		,ActualUnits=0.00		,ActualCost=0.00		,OrigEstHours=0.00
	,OrigEstUnits=0.00  	,OrigEstCost=0.00		,CurrEstHours=0.00		,CurrEstUnits=0.00
	,CurrEstCost=0.00		,ProjHours=0.00			,ProjRevUnits=0.00		,ProjCost=0.00
	,ForecastHours=0.00		,ForecastUnits=0.00		,ForecastCost=0.00		,TotalCmtdUnits=0.00
	,TotalCmtdCost=0.00		,RemainCmtdUnits=0.00	,RemainCmtdCost=0.00	,RecvdNotInvcdUnits=0.00
	,RecvdNotInvcdCost=0.00 ,EstCostComplete=0.00
	,isnull(l.LastEarnedMonth,'1/1/1950')
From JCForecastMonth JCF

Join JCCM on JCCM.JCCo=JCF.JCCo
		  and JCCM.Contract=JCF.Contract
Left Join ContractFirstJob c on c.JCCo=JCF.JCCo
							and c.Contract=JCF.Contract
	Left Join JCJM on JCJM.JCCo=c.JCCo
			  and JCJM.Job=c.MinJob
Left Join LastEarnedMonth l on
			l.JCCo = JCF.JCCo
			and l.Contract=JCF.Contract
Where JCCM.ContractStatus = 1
GO
GRANT SELECT ON  [dbo].[vrvJCBacklogNoForecast] TO [public]
GRANT INSERT ON  [dbo].[vrvJCBacklogNoForecast] TO [public]
GRANT DELETE ON  [dbo].[vrvJCBacklogNoForecast] TO [public]
GRANT UPDATE ON  [dbo].[vrvJCBacklogNoForecast] TO [public]
GRANT SELECT ON  [dbo].[vrvJCBacklogNoForecast] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvJCBacklogNoForecast] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvJCBacklogNoForecast] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvJCBacklogNoForecast] TO [Viewpoint]
GO
