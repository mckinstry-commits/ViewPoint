SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO












CREATE View [dbo].[vrvPCPotentialWorkForecast]

as

With PP

as

(Select	
     PW.JCCo
	,PW.PotentialProject
	,PW.StartDate
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


/*,EstCostRev

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
From JCCM


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

ContractFirstJob 
as
(Select JCCo, Contract, min(Job) as MinJob From bJCJM With (NoLock)
 Group By JCCo, Contract)

*/
SELECT  
	 PP.JCCo
	,PP.PotentialProject
	,PP.StartDate
	,ActiveOrPotential = 1
	,isnull(PP.ProjectMgr,0) as ProjectMgr
	,JCMP.Name
	,PP.AwardProbPct
	,PP.ForecastMonth
	,PP.FiscalYr
	,PP.RevenuePct
	,PP.CostPct
	,PP.ForecastRevenueCumulative
    ,PP.ForecastCostCumulative
	,PP_Prev.ForecastRevenueCumulative as PreviousForecastRevenueCumulative
	,PP_Prev.ForecastCostCumulative as PreviousForecastCostCumalative
	,PP.ForecastRevenueCumulative - isnull(PP_Prev.ForecastRevenueCumulative,0) as ForecatRevenueMonthly
	,PP.ForecastCostCumulative - isnull(PP_Prev.ForecastCostCumulative,0) as ForecastCostMonthly

From PP

Left Join PP PP_Prev on PP_Prev.JCCo=PP.JCCo
				and PP_Prev.PotentialProject=PP.PotentialProject
				and PP_Prev.MonthNumber+1=PP.MonthNumber
Left Join JCMP With (NoLock) on JCMP.JCCo=PP.JCCo
							 and JCMP.ProjectMgr=PP.ProjectMgr


/*UNION ALL

SELECT  
	JCF_W_Prev.JCCo
	,JCF_W_Prev.Contract
	,JCCM.StartMonth
	,ActiveOrPotential = 0
	,isnull(JCMP.ProjectMgr,0)
	,JCMP.Name
	,Null as AwardProbPct
	,JCF_W_Prev.ForecastMonth
	,Null as FiscalYr
	,JCF_W_Prev.RevenuePct
	,JCF_W_Prev.CostPct
	,ForecastRevenue
    ,ForecastCost
	,Null as PreviousForecastRevenueCumulative
	,Null as PreviousForecastCostCumalative
	,isnull(ForecastRevenue,0)-isnull(ForecastRevenuePrevious,0) as ForecastRevenueMonth
	,isnull(ForecastCost,0)-isnull(ForecastCostPrevious,0) as ForecastCostMonth


From JCF_W_Prev
Join JCCM on JCCM.JCCo=JCF_W_Prev.JCCo
		  and JCCM.Contract = JCF_W_Prev.Contract
Left Join ContractFirstJob c on c.JCCo=JCF_W_Prev.JCCo
							and c.Contract=JCF_W_Prev.Contract
	Left Join JCJM on JCJM.JCCo=c.JCCo
			  and JCJM.Job=c.MinJob
	Left Join JCMP on JCMP.JCCo=c.JCCo
				   and JCMP.ProjectMgr=JCJM.ProjectMgr
Where JCCM.ContractStatus = 0*/

	

















GO
GRANT SELECT ON  [dbo].[vrvPCPotentialWorkForecast] TO [public]
GRANT INSERT ON  [dbo].[vrvPCPotentialWorkForecast] TO [public]
GRANT DELETE ON  [dbo].[vrvPCPotentialWorkForecast] TO [public]
GRANT UPDATE ON  [dbo].[vrvPCPotentialWorkForecast] TO [public]
GO
