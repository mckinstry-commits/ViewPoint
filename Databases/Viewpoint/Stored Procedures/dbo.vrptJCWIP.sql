SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE proc [dbo].[vrptJCWIP]

(@Company bCompany=1, @BegContract bContract=' ', @EndContract bContract='zzzzzzzzzz',
 @Department bDept=' ', @ProjectMgr int=0, 
 @DeptProjMgrSort char(1)='C',
 @ThroughMonth bMonth = '12/1/2050',
 @PriorFiscalYearMonth bMonth = '12/1/2050',
 @SummarizeCloseContract char(1)='N',
 @SummarizeSmallContract char(1)='N',
 @SmallContractThreshold decimal (12,2),
 @IncludeOverrideRevenue char(1)='N',
 @IncludeOverrideCost char(1)='N',
 @SortContractOption char(1)='C',
 @ReportColumnLimit tinyint = 29,
 @IncludePotential char(1)='N')
 

/******************
 Created:  4/7/2010 DH
 Modified: 12/8/2010 DH Issue 142048.  Changed Cost section to group by Contract/Item so that Est Cost at Complete summarized 
										by properly for calculation on reports.
		   
		   6/24/11 DH TK-04319.  Added Potential and Pending projects	
		   7/6/11 DH D-02251.  Estimated Revenue at Completion changed to return amount if Projection plugged even when 0.									
		   4/17/12 HH TK-13974   Added ISNULL check on MonthClosed comparison with ContractStatus within JCWIPData-CTE
 
 Usage:  The procedure will return all the necessary columns, including Gross Profit and Earned
	     Revenue calculations for the JC Work in Progress - Wide Format report.  
	     The table variable @JCWIPRows is joined to the data set, which results in each department
	     department/contract record being repeated for each record in @JCWIPRows.  This allows the final 
	     result set to be summarized in a cross tab report with department/contract on rows and the column 
	     number field from @JCWIPRows.  If additional columns are to be added, change @ReportColumnLimit parameter 
	     default to the number of columns needed.  Procedure will also return separate rows for the following
	     subtotals:  Department or Project Manager, Contract Status (Open and Closed), Small Contracts.
	 
 Granularity of data set:  Department/Contract/Subtotals/ColumnNumber (see above).  Data set repeats
					       for x number of rows in JCWIPColumns.  
 
 Sort Fields (Sorting done in report)
		   1. Department or Project Manager 
		   2. Status (Open or Closed)
		   3. Row Type: 0 = Headers, 1 = Contract Rows, 2=Small Contract Summary, 3 = Subtotals
		   4. Contract Sort Order = Based on @SortContractOption (see below)
		   5. Contract:  set to zzzzzzz for Subtotals (zzzSmallContract for small contracts)
		   
	     
 Parameters: @Company, @BegContract, @EndContract (Normal Selection criteria)
			 @DeptProjMgrSort:  Sort by (D)epartment, (P)roject Mgr, (C)ontract
			 @ThroughMonth:  Includes all revenue and cost through month selected
			 @PriorFiscalYearMonth:  Used to retrieve prior year data
			 @SummarizeCloseContract:  Y or N.  One Line Summary for Closed Contracts?
			 @SummarizeSmallContract:  Y or N.  One Line Summary for Small Contracts?
			 @SmallContractThreshold:  Criteria for summarizing small contracts.
			 @IncludeOverrideRevenue:  Y or N.  Include Overrides in Estimated Revenue at Completion?
			 @IncludeOverrideCost:  Y or N.  Include Overrides in Estimated Cost at Completion?
			 @SortContractOption:  Sort Contracts by (C)ontract Number, Contract (A)mount, > Estimated (G)ross Profit, Start (M)onth
			 
Other Criteria/Restrictions:  (Procedure will include the following data:
			1. All Contracts where the Closed Month is blank or is later than @ThroughMonth

*************/						  
										   		 
with recompile			  	     

AS



declare @PriorFiscalYearBegMonth smalldatetime, /*Prior Fiscal Year Begin Month*/
	    @GLCo tinyint, /*GL Company*/
	    @CompanyName varchar(60), /*Used to return company name for report*/
	    @ColumnNumber tinyint /*ColumnNumber for while loop that creates x number of columns*/

Select @CompanyName = HQCO.Name 
		From HQCO 
			where HQCO.HQCo = @Company

/*Get GL Company assigned to the Job Cost company*/
Select @GLCo=JCCO.GLCo From JCCO Where JCCO.JCCo = @Company

/*Get the Begin Month for the Prior Fiscal Year*/
Select @PriorFiscalYearBegMonth = GLFY.BeginMth
	   From GLFY 
	   Where GLFY.GLCo = @GLCo and GLFY.FYEMO = @PriorFiscalYearMonth

/*If @PriorFiscalYearBegMonth is not found, set to @ThroughMonth so that report returns data*/ 
if @PriorFiscalYearBegMonth is null
	select @PriorFiscalYearBegMonth = @ThroughMonth




DECLARE @JCWIPRows TABLE ( ColumnNumber tinyint  )

SET @ColumnNumber = 1
 

     WHILE @ColumnNumber <= @ReportColumnLimit
     BEGIN
           INSERT INTO @JCWIPRows (ColumnNumber) VALUES (@ColumnNumber)
           SET @ColumnNumber = @ColumnNumber + 1
     END;

/**
 CTE gets the first job assigned to a contract in order to retrieve a project manager by contract.
 In cases where multiple jobs exist for a single contract, the project manager for the contract
 must be assigned to job with the lowest number (for that contract)
 */


With

FirstJobByContract

as

(Select   JCCo
		, Contract
		, min(Job) as FirstJob
 From JCJM With (NoLock)	
 Group By JCCo, Contract), 

/**
 CTE returns only contracts that are open or were open up to @ThroughMonth.
 CTE Joined to other SQL statements to limit information returned by procedure.
 **/
 
  ActiveContracts

as

(select   JCCM.JCCo
		, JCCM.Contract
		, JCCI.Item
		, max(JCJM.ProjectMgr) as ProjectMgr
		 FROM JCCM
		 JOIN JCCI
			ON JCCI.JCCo=JCCM.JCCo
			AND JCCI.Contract = JCCM.Contract
		 JOIN FirstJobByContract f
			ON  f.JCCo = JCCM.JCCo
			AND f.Contract = JCCM.Contract
		 JOIN JCJM
			ON  JCJM.JCCo = f.JCCo
			AND JCJM.Job = f.FirstJob
	
			
    where JCCM.JCCo = @Company and isnull(JCCM.MonthClosed,'12/1/2050')  >= @PriorFiscalYearBegMonth
		  and JCCI.Department = (case when @Department<>' ' then @Department else JCCI.Department end)
	      and isnull(JCJM.ProjectMgr,0) = (case when @ProjectMgr <> 0 then @ProjectMgr else isnull(JCJM.ProjectMgr,0) end)  
	      and JCCM.ContractStatus > 0
	Group By  JCCM.JCCo
			, JCCM.Contract
			, JCCI.Item
      
    ),

/*CTE gets the last month a revenue projection amount was recorded or plugged (including 0 plugs).
  Joined to Revenue CTE to return plug flags for current, prior year, and prior months*/

  RevProjMth

(JCCo,
 Contract,
 Item,
 LastProjMthToDate,
 LastProjMthPriorYear,
 LastProjMthPriorMonth)
 
 as
 
 (SELECT  JCIP.JCCo
		, JCIP.Contract
		, JCIP.Item
		, max(JCIP.Mth) as LastProjMthToDate
		, max(case when JCIP.Mth <= @PriorFiscalYearMonth then JCIP.Mth end) as LastProjMthPriorYear
		, max(case when JCIP.Mth <= dateadd(month,-1,@ThroughMonth) then JCIP.Mth end) as LastProjMthPriorMonth
 FROM JCIP
 JOIN ActiveContracts a ON
	a.JCCo=JCIP.JCCo AND
	a.Contract=JCIP.Contract AND
	a.Item=JCIP.Item
 
 WHERE (ProjDollars<>0 or ProjPlug='Y' ) and JCIP.Mth <= @ThroughMonth
 GROUP BY JCIP.JCCo, JCIP.Contract, JCIP.Item
 ),

/****Revenue CTE:  
  Returns Contract amounts, projected revenue, and billings by Contract and Item.
  Second select statement returns projected override revenue
  Projected Revenue and Current Contract evaluated later in procedure to derive
  Estimated Revenue at completion
 ****/ 
 
Revenue

as

(Select   JCIP.JCCo ,JCIP.Contract ,JCIP.Item, max(JCCI.Department) as Department, max(ac.ProjectMgr) as ProjectMgr
		,	sum(JCIP.OrigContractAmt) as OrigContractAmt
		,	sum(JCIP.ContractAmt) as ContractAmt
		,	sum(JCIP.CurrentUnitPrice) as ContractUnits
		,	sum(JCIP.BilledAmt) as BilledAmtToDate
		,	sum(case when JCIP.Mth<=@PriorFiscalYearMonth then JCIP.BilledAmt else 0 end) as BilledAmtPriorYear
		,	sum(case when JCIP.Mth<=dateadd(month,-1,@ThroughMonth) then JCIP.BilledAmt else 0 end) as BilledAmtPriorMonth
		,	sum(JCIP.ReceivedAmt) as ReceivedAmt
		,	sum(JCIP.CurrentRetainAmt) as CurrentRetainAmt
		,	sum(JCIP.BilledTax) as  BilledTax
		,	sum(JCIP.ProjDollars) as  ProjDollars
		,   sum(JCIP.ProjDollars) as ProjDollarsToDate
		,   sum(JCIP.ContractAmt) as ContractAmtToDate
		,   sum(case when JCIP.Mth <= @PriorFiscalYearMonth then JCIP.ProjDollars else 0 end) as ProjDollarsPriorYear
		,   sum(case when JCIP.Mth <= @PriorFiscalYearMonth then JCIP.ContractAmt else 0 end) as ContractAmtPriorYear
		,   sum(case when JCIP.Mth <= dateadd(month,-1,@ThroughMonth) then JCIP.ProjDollars else 0 end) as ProjDollarsPriorMonth
		,   sum(case when JCIP.Mth <= dateadd(month,-1,@ThroughMonth) then JCIP.ContractAmt else 0 end) as ContractAmtPriorMonth
		,   max(case when JCIP.Mth = r.LastProjMthToDate then JCIP.ProjPlug end) as ProjPlugToDate
		,   max(case when JCIP.Mth = r.LastProjMthPriorYear then JCIP.ProjPlug end) as ProjPlugPriorYear
		,   max(case when JCIP.Mth = r.LastProjMthPriorMonth then JCIP.ProjPlug end) as ProjPlugPriorMth
		,   0 as RevenueOverridePriorYear
		,   0 as RevenueOverridePriorMonth
		,   0 as RevenueOverrideToDate
		   
 From  JCIP
 
 JOIN ActiveContracts ac
	ON  ac.JCCo = JCIP.JCCo
	AND ac.Contract = JCIP.Contract
	AND ac.Item = JCIP.Item

 JOIN JCCI on JCCI.JCCo=JCIP.JCCo
		   and JCCI.Contract=JCIP.Contract
		   and JCCI.Item = JCIP.Item	

 LEFT JOIN RevProjMth r 
	ON  r.JCCo = JCIP.JCCo
	AND	r.Contract = JCIP.Contract
	AND r.Item = JCIP.Item	   
 
 Where JCIP.JCCo=@Company 
	   and JCIP.Mth<=@ThroughMonth 
	   and JCIP.Contract >= @BegContract and JCIP.Contract <= @EndContract
	
 Group by JCIP.JCCo, JCIP.Contract, JCIP.Item
 
 union all
 
 Select JCOR.JCCo, JCOR.Contract, Null as Item, max(JCCM.Department), max(JCJM.ProjectMgr)

		,0, 0, 0, 0, 0, 0, 0, 0
		,0, 0, 0, 0, 0, 0, 0, 0, null, null, null	 /*Place holders for contract amounts*/
		
		, sum(case when JCOR.Month = @PriorFiscalYearMonth and JCOR.RevCost<>0
				  then JCOR.RevCost else 0
		  end) as RevenueOverridePriorYear
		
		, sum(case when JCOR.Month = dateadd(month,-1,@ThroughMonth) and JCOR.RevCost<>0
				  then JCOR.RevCost else 0
		  end) as RevenueOverridePriorMonth
		 
		, sum(case when JCOR.Month = @ThroughMonth and JCOR.RevCost<>0
				   then JCOR.RevCost else 0
		  end) as RevenueOverrideToDate 
	From JCOR
	
	/*JOIN ActiveContracts ac
		ON  ac.JCCo = JCOR.JCCo
		AND ac.Contract = JCOR.Contract*/
	JOIN JCCM 
		ON  JCCM.JCCo = JCOR.JCCo
		AND JCCM.Contract = JCOR.Contract
	JOIN FirstJobByContract f
			ON  f.JCCo = JCCM.JCCo
			AND f.Contract = JCCM.Contract
	 JOIN JCJM
			ON  JCJM.JCCo = f.JCCo
			AND JCJM.Job = f.FirstJob
			
	Where JCOR.JCCo=@Company 
		  and JCOR.Month<=@ThroughMonth 
		  and JCOR.Contract >= @BegContract and JCOR.Contract <= @EndContract
		  and JCCM.Department = (case when @Department<>' ' then @Department else JCCM.Department end)
		  and isnull(JCCM.MonthClosed,'12/1/2050')  >= @PriorFiscalYearBegMonth
		  and isnull(JCJM.ProjectMgr,0) = (case when @ProjectMgr <> 0 then @ProjectMgr else isnull(JCJM.ProjectMgr,0) end)
	
	Group by 
		    JCOR.JCCo
		 ,  JCOR.Contract

			 
 ),

/***
 Cost CTE:  Returns job cost data by Job/Phase/CT.  Second statment returns projected override cost
			by Job.  Projected and Current Estimates used later in procedure to derive
			Estimated Cost at Completion
****/			
			
 
Cost

as

(Select JCCP.JCCo, JCJP.Contract, JCJP.Item 
		,	max(JCCI.Department) as Department
		,	max(ac.ProjectMgr) as ProjectMgr
		,	sum(JCCP.ActualHours) as  ActualHours
		,	sum(JCCP.ActualCost) as  ActualCostToDate
		,	sum(case when JCCP.Mth<=@PriorFiscalYearMonth then JCCP.ActualCost else 0 end) as ActualCostPriorYear
		,	sum(case when JCCP.Mth<=dateadd(month,-1,@ThroughMonth) then JCCP.ActualCost else 0 end) as ActualCostPriorMonth
		,	sum(JCCP.OrigEstHours) as  OrigEstHours
		,	sum(JCCP.OrigEstCost) as  OrigEstCost
		,	sum(JCCP.CurrEstHours) as  CurrEstHours
		,	sum(JCCP.CurrEstCost) as  CurrEstCost
		,	sum(JCCP.ProjHours) as  ProjHours
		,	sum(JCCP.ProjCost) as  ProjCost
		,	sum(JCCP.ForecastHours) as  ForecastHours
		,	sum(JCCP.ForecastCost) as  ForecastCost
		,	sum(JCCP.TotalCmtdCost) as  TotalCmtdCost
		,	sum(JCCP.RemainCmtdCost) as  RemainCmtdCost
		,	sum(JCCP.RecvdNotInvcdCost) as  RecvdNotInvcdCost
		,	sum(JCCP.ProjCost) as ProjCostToDate
		,	sum(JCCP.CurrEstCost) as CurrEstCostToDate
		,	min(case when JCCP.ProjPlug='Y' or JCCP.ProjCost<>0 then JCCP.Mth end) as ProjMth
		,	sum(case when JCCP.Mth <= @PriorFiscalYearMonth then JCCP.ProjCost else 0 end) as ProjCostPriorYear
		,	sum(case when JCCP.Mth <= @PriorFiscalYearMonth then JCCP.CurrEstCost else 0 end) as CurrEstCostPriorYear
		,	max(case when JCCP.Mth <= @PriorFiscalYearMonth then JCCP.ProjPlug end) as ProjPlugPriorYear
		,	sum(case when JCCP.Mth <= dateadd(month,-1,@ThroughMonth) then JCCP.ProjCost else 0 end) as ProjCostPriorMonth
		,	sum(case when JCCP.Mth <= dateadd(month,-1,@ThroughMonth) then JCCP.CurrEstCost else 0 end) as CurrEstCostPriorMonth
		,	max(case when JCCP.Mth <= dateadd(month,-1,@ThroughMonth) then JCCP.ProjPlug end) as ProjPlugPriorMonth
		,	0 as CostOverridePriorYear
		,	0 as CostOverridePriorMonth
		,	0 as CostOverrideToDate
 from JCCP
 
 JOIN JCJP 
	ON  JCJP.JCCo = JCCP.JCCo
	AND JCJP.Job = JCCP.Job
	AND JCJP.PhaseGroup = JCCP.PhaseGroup
	AND JCJP.Phase = JCCP.Phase
 
 JOIN ActiveContracts ac
	ON  ac.JCCo = JCJP.JCCo
	AND ac.Contract = JCJP.Contract	
	AND ac.Item = JCJP.Item
 
 JOIN JCCI 
	ON  JCCI.JCCo = JCJP.JCCo
	AND JCCI.Contract = JCJP.Contract
	AND JCCI.Item = JCJP.Item
  
 Where JCCP.JCCo=@Company and JCCP.Mth<=@ThroughMonth  
		and JCJP.Contract >= @BegContract and JCJP.Contract <= @EndContract

 Group By JCCP.JCCo, JCJP.Contract, JCJP.Item
 
 union all
 
 --Cost Overrides
 
 Select JCOP.JCCo, JCJM.Contract, NULL
		, max(JCCM.Department), max(JCJM.ProjectMgr)
		, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		, 0, 0, NULL, 0, 0, 'N', 0, 0, 'N' /*Placeholders for Estimated and Projected Costs*/
		, sum(case when JCOP.ProjCost<>0 and JCOP.Month = @PriorFiscalYearMonth 
				   then JCOP.ProjCost
				   else 0
			  end) as CostOverridePriorYear
		
		, sum(case when JCOP.ProjCost<>0 and JCOP.Month = dateadd(month,-1,@ThroughMonth) 
			      then JCOP.ProjCost
			      else 0
			   end) as CostOverridePriorMonth
		
		, sum(case when JCOP.ProjCost <> 0 and JCOP.Month=@ThroughMonth
				   then JCOP.ProjCost
				   else 0
			  end) as CostOverrideToDate	   
 From JCOP
 JOIN JCJM
	ON  JCJM.JCCo=JCOP.JCCo
	AND JCJM.Job=JCOP.Job
 
 JOIN JCCM 
	ON  JCCM.JCCo = JCJM.JCCo
	AND	JCCM.Contract = JCJM.Contract	
 
Where JCOP.JCCo=@Company and JCOP.Month<=@ThroughMonth  
		and JCJM.Contract >= @BegContract and JCJM.Contract <= @EndContract
		and JCCM.Department = (case when @Department<>' ' then @Department else JCCM.Department end)
		and isnull(JCJM.ProjectMgr,0) = (case when @ProjectMgr <> 0 then @ProjectMgr else isnull(JCJM.ProjectMgr,0) end)
		and isnull(JCCM.MonthClosed,'12/1/2050')  >= @PriorFiscalYearBegMonth

 
 Group By   JCOP.JCCo
		  , JCOP.Job	
		  , JCJM.Contract
 	
 ),
 
 /*CTE to return Original Estimated Cost by contract for pending contracts.  
  Used in JobCostRevenueByContract CTE*/
  
JCJobContract (JCCo, Contract, OrigEstCost)

AS

(SELECT	JCJM.JCCo, JCJM.Contract, sum(JCCH.OrigCost) as OrigEstCost	
FROM JCCH
JOIN JCJM on  JCJM.JCCo = JCCH.JCCo
		  and JCJM.Job = JCCH.Job
JOIN JCCM ON  JCCM.JCCo=JCJM.JCCo
		  and JCCM.Contract=JCJM.Contract		  
WHERE JCCM.JCCo = @Company and (JCCM.ContractStatus = 0 or JCCM.StartMonth > @ThroughMonth) --Pending = Status 0 or StartMonth later than Through Month
GROUP BY JCJM.JCCo, JCJM.Contract	)	,
 
 /****
  CTE returns 4 data sets.  One for revenue and cost grouped by Contract, Department, ProjectManager.
  Also returns Potential and Pending Projects for Original and Backlog numbers - Added 6/24/11 DH
  
  Revenue Estimate and Cost Estimate at Completion calculated as follows:
  
  Revenue Estimate at Complete:	Uses one of three possible amounts in the following order by Contract, Item
								1. Override Revenue (by Contract)
								2. Projected Revenue
								3. Current Contract Amount
  
  Cost Estimate at Complete:  Uses one of three possible amounts in the following order by Job/Phase/CT
							  1. Override Cost (by Job)		
							  2. Projected Cost
							  3. Current Estimated Cost

  All amounts rolled up by Contract, Department, ProjectManager
  
  
  
  ******/	
  
				  												
 

JobCostRevenueByContract

as

(Select	r.JCCo, r.Contract, 'Interfaced' as PendingStatus, r.Department, r.ProjectMgr

		,   sum(r.OrigContractAmt) as OrigContractAmt
		,	sum(r.ContractAmt) as ContractAmt
		,	sum(BilledAmtToDate) as BilledAmtToDate
		,	sum(r.BilledAmtPriorYear) as BilledAmtPriorYear
		,	sum(r.BilledAmtPriorMonth) as BilledAmtPriorMonth
		,	sum(r.ReceivedAmt) as ReceivedAmt
		,	sum(r.CurrentRetainAmt) as CurrentRetainAmt
		,	sum(r.BilledTax) as  BilledTax
		,   sum(r.ProjDollars) as ProjDollarsToDate
		,   sum(r.ContractAmt) as ContractAmtToDate
		,   sum(r.ProjDollarsPriorYear) as ProjDollarsPriorYear
		,   sum(r.ContractAmtPriorYear) as ContractAmtPriorYear
		,   sum(r.ProjDollarsPriorMonth) as ProjDollarsPriorMonth
		,   sum(r.ContractAmtPriorMonth) as ContractAmtPriorMonth
		,   sum(r.RevenueOverridePriorYear) as RevenueOverridePriorYear
		,   sum(r.RevenueOverridePriorMonth) as RevenueOverridePriorMonth
		,   sum(r.RevenueOverrideToDate) as RevenueOverrideToDate
		,	case when max(r.RevenueOverrideToDate)<>0 and @IncludeOverrideRevenue='Y' 
					then max(r.RevenueOverrideToDate)
				  else		
					sum(case when r.ProjDollarsToDate<>0 or r.ProjPlugToDate = 'Y' then r.ProjDollarsToDate 
							 else r.ContractAmtToDate end) 
			end as RevenueEstimateComplete_ToDate
			
		,	case when max(r.RevenueOverridePriorYear) <>0 and @IncludeOverrideRevenue='Y' 
					then max(r.RevenueOverridePriorYear)	
				 else			 
		   		   sum(case when r.ProjDollarsPriorYear<>0 or r.ProjPlugPriorYear='Y' then r.ProjDollarsPriorYear 
							else r.ContractAmtPriorYear end)
			end as RevenueEstimateComplete_PriorYear
		
		, case when max(r.RevenueOverridePriorMonth)<>0 and @IncludeOverrideRevenue='Y' 
				 then max(r.RevenueOverridePriorMonth)
				else
				    sum(case when r.ProjDollarsPriorMonth<>0 or ProjPlugPriorMth='Y'  then r.ProjDollarsPriorMonth 
							else r.ContractAmtPriorMonth end) 
		  end as RevenueEstimateComplete_PriorMonth
				    
		,	0 as ActualHours
		,	0 as  ActualCostToDate
		,	0 as ActualCostPriorYear
		,	0 as ActualCostPriorMonth
		,	0 as  OrigEstHours
		,	0 as OrigEstCost
		,	0 as  CurrEstHours
		,	0 as  CurrEstCost
		,	0 as  ProjHours
		,	0 as  ProjCost
		,	0 as  ForecastHours
		,	0 as  ForecastCost
		,	0 as  TotalCmtdCost
		,	0 as  RemainCmtdCost
		,	0 as  RecvdNotInvcdCost
		,	0 as ProjCostToDate
		,	0 as CurrEstCostToDate
		,	0 as ProjCostPriorYear
		,	0 as CurrEstCostPriorYear
		,	0 as ProjCostPriorMonth
		,	0 as CurrEstCostPriorMonth
		,	0 as CostOverridePriorYear
		,	0 as CostOverridePriorMonth
		,	0 as CostOverrideToDate
		,	0 as CostEstimateComplete_ToDate	
		,	0 as CostEstimateComplete_PriorYear		
		,	0 as CostEstimateComplete_PriorMonth		    
		
 From Revenue r
 /*JOIN JCCI 
		ON JCCI.JCCo = r.JCCo
		AND JCCI.Contract = r.Contract
		AND JCCI.Item = r.Item
 
 JOIN FirstJobByContract f
		ON  f.JCCo = r.JCCo
		AND	f.Contract = r.Contract

 JOIN JCJM
		ON  JCJM.JCCo= f.JCCo
		AND	JCJM.Job = f.FirstJob		*/
		
 GROUP BY r.JCCo, r.Contract, r.Department, r.ProjectMgr	
 
 union all 
 


Select c.JCCo, c.Contract, 'Interfaced' as PendingStatus, c.Department, c.ProjectMgr
		,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 
		,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 /*Revenue Placeholders*/
		,	sum(c.ActualHours) as  ActualHours
		,	sum(c.ActualCostToDate) as ActualCostToDate
		,	sum(c.ActualCostPriorYear) as ActualCostPriorYear
		,	sum(c.ActualCostPriorMonth) as ActualCostPriorMonth
		,	sum(c.OrigEstHours) as  OrigEstHours
		,	sum(c.OrigEstCost) as  OrigEstCost
		,	sum(c.CurrEstHours) as  CurrEstHours
		,	sum(c.CurrEstCost) as  CurrEstCost
		,	sum(c.ProjHours) as  ProjHours
		,	sum(c.ProjCost) as  ProjCost
		,	sum(c.ForecastHours) as  ForecastHours
		,	sum(c.ForecastCost) as  ForecastCost
		,	sum(c.TotalCmtdCost) as  TotalCmtdCost
		,	sum(c.RemainCmtdCost) as  RemainCmtdCost
		,	sum(c.RecvdNotInvcdCost) as  RecvdNotInvcdCost
		,	sum(c.ProjCostToDate) as ProjCostToDate
		,	sum(c.CurrEstCostToDate) as CurrEstCostToDate
		,	sum(c.ProjCostPriorYear) as ProjCostPriorYear
		,	sum(c.CurrEstCostPriorYear) as CurrEstCostPriorYear
		,	sum(c.ProjCostPriorMonth) as ProjCostPriorMonth
		,	sum(c.CurrEstCostPriorMonth) as CurrEstCostPriorMonth
		,	sum(c.CostOverridePriorYear) as CostOverridePriorYear
		,	sum(c.CostOverridePriorMonth) as CostOverridePriorMonth
		,	sum(c.CostOverrideToDate) as CostOverrideToDate
		
		, case when max(c.CostOverrideToDate)<>0 and @IncludeOverrideCost='Y' 
				then max(c.CostOverrideToDate)
			 else		
				 sum(case when c.ProjCostToDate<>0 or c.ProjMth<=@ThroughMonth 
							then c.ProjCostToDate
					 else CurrEstCostToDate end) 
		end as CostEstimateComplete_ToDate
		
		, case when max(c.CostOverridePriorYear)<>0 and @IncludeOverrideCost='Y' 
				then max(c.CostOverridePriorYear)
			 else  		
				 sum(case when c.ProjCostPriorYear<>0 or c.ProjMth <= @PriorFiscalYearMonth 
							then c.ProjCostPriorYear 
					 else CurrEstCostPriorYear end) 
		  end as CostEstimateComplete_PriorYear
		
		, case when max(c.CostOverridePriorMonth)<>0 and @IncludeOverrideCost='Y' 
				then max(c.CostOverridePriorMonth)
		     else			
			    sum(case when c.ProjCostPriorMonth<>0 or c.ProjMth < @ThroughMonth
						then c.ProjCostPriorMonth 
					else CurrEstCostPriorMonth end) 
		  end as CostEstimateComplete_PriorMonth
		  
 From Cost c

	
Group By c.JCCo, c.Contract, c.Department, c.ProjectMgr
 
UNION ALL

/*Select Potential projects that have not been updated to Job Cost*/
 
SELECT	PC.JCCo, PC.PotentialProject, 'Potential' as PendingStatus
		, NULL as Dept /*sort at end of all Depts in DeptPMSort (see JCWIPData CTE)*/
		, NULL as PM  /*PM null for Pending Projects. Will be sorted at end of report in PMSort field*/
		,   PC.RevenueEst as OrigContractAmt
		,	PC.RevenueEst as ContractAmt
		,	0 as BilledAmtToDate
		,	0 as BilledAmtPriorYear
		,	0 as BilledAmtPriorMonth
		,	0 as ReceivedAmt
		,	0 as CurrentRetainAmt
		,	0 as BilledTax
		,   0 as ProjDollarsToDate
		,   0 as ContractAmtToDate
		,   0 as ProjDollarsPriorYear
		,   0 as ContractAmtPriorYear
		,   0 as ProjDollarsPriorMonth
		,   0 as ContractAmtPriorMonth
		,   0 as RevenueOverridePriorYear
		,   0 as RevenueOverridePriorMonth
		,   0 as RevenueOverrideToDate
		,	PC.RevenueEst as RevenueEstimateComplete_ToDate
		,	0 as  RevenueEstimateComplete_PriorYear
		,   0 as  RevenueEstimateComplete_PriorMonth    
		,	0 as  ActualHours
		,	0 as  ActualCostToDate
		,	0 as  ActualCostPriorYear
		,	0 as  ActualCostPriorMonth
		,	0 as  OrigEstHours
		,	PC.CostEst as  OrigEstCost
		,	0 as  CurrEstHours
		,	PC.CostEst as  CurrEstCost
		,	0 as  ProjHours
		,	0 as  ProjCost
		,	0 as  ForecastHours
		,	0 as  ForecastCost
		,	0 as  TotalCmtdCost
		,	0 as  RemainCmtdCost
		,	0 as  RecvdNotInvcdCost
		,	0 as ProjCostToDate
		,	0 as CurrEstCostToDate
		,	0 as ProjCostPriorYear
		,	0 as CurrEstCostPriorYear
		,	0 as ProjCostPriorMonth
		,	0 as CurrEstCostPriorMonth
		,	0 as CostOverridePriorYear
		,	0 as CostOverridePriorMonth
		,	0 as CostOverrideToDate
		,	PC.CostEst as CostEstimateComplete_ToDate	
		,	0 as CostEstimateComplete_PriorYear		
		,	0 as CostEstimateComplete_PriorMonth		    
		
FROM PCPotentialWork PC
LEFT OUTER JOIN JCJM ON
	 JCJM.PotentialProjectID = PC.KeyID
WHERE PC.JCCo=@Company and JCJM.PotentialProjectID is null --null in JCJM means still only in PC


UNION ALL

/*Return Contracts with pending status (ContractStatus = 0)
  Considered Pending if StartMonth is past the Through Month*/
  
SELECT JCCM.JCCo, JCCM.Contract, 'Pending' as PendingStatus
		, NULL as Dept /*sort at end of all Depts in DeptPMSort (see JCWIPData CTE)*/
		, NULL as PM  /*PM null for Pending Projects. Will be sorted at end of report in PMSort field*/
		,   JCCM.OrigContractAmt
		,	JCCM.ContractAmt
		,	0 as BilledAmtToDate
		,	0 as BilledAmtPriorYear
		,	0 as BilledAmtPriorMonth
		,	0 as ReceivedAmt
		,	0 as CurrentRetainAmt
		,	0 as  BilledTax
		,   0 as ProjDollarsToDate
		,   0 as ContractAmtToDate
		,   0 as ProjDollarsPriorYear
		,   0 as ContractAmtPriorYear
		,   0 as ProjDollarsPriorMonth
		,   0 as ContractAmtPriorMonth
		,   0 as RevenueOverridePriorYear
		,   0 as RevenueOverridePriorMonth
		,   0 as RevenueOverrideToDate
		,	JCCM.ContractAmt as RevenueEstimateComplete_ToDate
		,	0 as  RevenueEstimateComplete_PriorYear
		,   0 as  RevenueEstimateComplete_PriorMonth    
		,	0 as  ActualHours
		,	0 as  ActualCostToDate
		,	0 as  ActualCostPriorYear
		,	0 as  ActualCostPriorMonth
		,	0 as  OrigEstHours
		,	j.OrigEstCost
		,	0 as  CurrEstHours
		,	j.OrigEstCost as CurrEstCost
		,	0 as  ProjHours
		,	0 as  ProjCost
		,	0 as  ForecastHours
		,	0 as  ForecastCost
		,	0 as  TotalCmtdCost
		,	0 as  RemainCmtdCost
		,	0 as  RecvdNotInvcdCost
		,	0 as ProjCostToDate
		,	0 as CurrEstCostToDate
		,	0 as ProjCostPriorYear
		,	0 as CurrEstCostPriorYear
		,	0 as ProjCostPriorMonth
		,	0 as CurrEstCostPriorMonth
		,	0 as CostOverridePriorYear
		,	0 as CostOverridePriorMonth
		,	0 as CostOverrideToDate
		,	j.OrigEstCost as CostEstimateComplete_ToDate	
		,	0 as CostEstimateComplete_PriorYear		
		,	0 as CostEstimateComplete_PriorMonth
FROM JCCM
JOIN JCJobContract j on j.JCCo=JCCM.JCCo and j.Contract=JCCM.Contract
WHERE JCCM.JCCo = @Company and (JCCM.ContractStatus = 0 or JCCM.StartMonth > @ThroughMonth)

 
 ),
 



/****
  JCWIPData CTE:
   Purpose is to combine cost and revenue by Department and Contract from 
   the JobCostRevenueByContract CTE.
  
  Also returns/calculates the following information
  Earned Revenue:  If Est. Cost at Completion >= Est. Rev at Completion
					 then Est Rev at Completion + Actal Cost - Est Cost at Completion
				   else (ActualCost/Est Cost at Completion)	 * Est Rev at Completion
  ContractSort:  Numeric value based on @SortContractOption parameter.
				 If 'C' then Contract Number order ascending
				 If 'A' then Contract Amount order descending
				 If 'M' then Start Month order ascending
				 If 'G' then Estimated Gross Profit descending		
				 
 SmallContractYN:  If summarizing small contracts on one line and Contract Amount < Threshold
 
 DeptPMSort:  Field storing either the Department Number or Project Manager or '' based on
			  @DeptProjMgrSort.
 
 OpenClosedStatus:  1 = Open, 2 = Closed based on JCCM.MonthClosed.
  				 		   
*****/				   

JCWIPData

as

(Select 
	a.JCCo
,	a.Contract
,	max(isnull(JCCM.Description,PC.Description)) as ContractDescription

/*IF projects are not pending set to 1=Open or 2=Closed.  
 Considered open if JCCM.ContractStatus is soft (2) or hard (3) closed and MonthClosed is past the ThroughMonth*/
,	(CASE WHEN max(a.PendingStatus) ='Interfaced' THEN
				(case when max(JCCM.ContractStatus) >= 2 and max(ISNULL(JCCM.MonthClosed,'12/1/2050')) > @ThroughMonth
						then '1'
					when max(JCCM.ContractStatus) = 1 
						then '1'
					when max(JCCM.ContractStatus) >= 2 and max(ISNULL(JCCM.MonthClosed,'12/1/2050')) <= @ThroughMonth	
						then '2'
				  end)
			WHEN max(a.PendingStatus) ='Pending' --set to higher value for sorting at end of report
					then 'zzzPending'
		    WHEN max(a.PendingStatus) ='Potential' --set to higher value for sorting at end of report.
					then 'zzzPotential'
		 END) as OpenClosedStatus	 	
				 	

,	max(JCCM.StartMonth) as StartMonth
,	a.Department
,	a.ProjectMgr

,	case when @DeptProjMgrSort = 'D' and max(a.PendingStatus) = 'Interfaced' 
				 then a.Department
		 when @DeptProjMgrSort='P' and max(a.PendingStatus) = 'Interfaced'
				 then max(JCMP.Name)
		 when max(a.PendingStatus) ='Pending' 
				 then 'zzzPending'				 
		 when max(a.PendingStatus) = 'Potential'
				 then 'zzzPotential'				 
		 else ''
    end as DeptPMSort

,  case when @DeptProjMgrSort = 'D' and max(a.PendingStatus) = 'Interfaced' then max(JCDM.Description)
		 when @DeptProjMgrSort='P' and max(a.PendingStatus) = 'Interfaced' then max(JCMP.Name)
		 when max(a.PendingStatus) = 'Pending' then 'Pending Projects'
		 when max(a.PendingStatus) = 'Potential' then 'Potential Projects'
	else ''
    end as DeptPMSortDescription  
    
,	Case when @SortContractOption='C'	
				then row_number() over (order by a.Contract asc) 
			 when @SortContractOption='A'
				then row_number() over (order by sum(a.ContractAmt) desc) 
			 when @SortContractOption='M'
				then row_number() over (order by max(JCCM.StartMonth) asc) 
			 when @SortContractOption='G'
				then row_number () over (order by sum(a.RevenueEstimateComplete_ToDate - a.CostEstimateComplete_ToDate) desc) 									
		End
		as ContractSort	    
		
,	Case when (@SummarizeSmallContract = 'Y' and @SummarizeCloseContract='N' 
				and sum(a.ContractAmt)<@SmallContractThreshold)
				then 'Y'
		 when (@SummarizeSmallContract = 'Y' and @SummarizeCloseContract='Y' and 	
			   max(isnull(JCCM.MonthClosed,'12/1/2050')) > @ThroughMonth /*Open Small Contract*/
			   and sum(a.ContractAmt)<@SmallContractThreshold)
			   then 'Y'
		 else 'N'
	End as SmallContractYN  /*Indicator for small contracts. Closed small contracts
							  summarized into closed contracts if @SummarizeCloseContract='Y' 
							*/
,	sum(a.OrigContractAmt) as OrigContractAmt
,	sum(a.ContractAmt) as ContractAmt
,	sum(a.BilledAmtToDate) as BilledAmtToDate
,	sum(a.BilledAmtPriorYear) as BilledAmtPriorYear
,	sum(a.BilledAmtPriorMonth) as BilledAmtPriorMonth
,	sum(a.ReceivedAmt) as ReceivedAmt
,	sum(a.CurrentRetainAmt) as CurrentRetainAmt
,	sum(a.BilledTax) as BilledTax
,	sum(a.ProjDollarsToDate) as ProjDollarsToDate
,	sum(a.ActualHours) as ActualHours
,	sum(a.ActualCostToDate) as ActualCostToDate
,	sum(a.ActualCostPriorYear) as ActualCostPriorYear
,	sum(a.ActualCostPriorMonth) as ActualCostPriorMonth
,	sum(a.OrigEstHours) as OrigEstHours
,	sum(a.OrigEstCost) as OrigEstCost
,	sum(a.CurrEstHours) as CurrEstHours
,	sum(a.CurrEstCost) as CurrEstCost
,	sum(a.ProjHours) as ProjHours
,	sum(a.ProjCost) as ProjCost
,	sum(a.ForecastHours) as ForecastHours
,	sum(a.ForecastCost) as ForecastCost
,	sum(a.TotalCmtdCost) as TotalCmtdCost
,	sum(a.RemainCmtdCost) as RemainCmtdCost
,	sum(a.RecvdNotInvcdCost) as RecvdNotInvcdCost
,	sum(a.RevenueEstimateComplete_ToDate) as RevenueEstimateComplete_ToDate
,	sum(a.CostEstimateComplete_ToDate) as CostEstimateComplete_ToDate
,	sum(a.RevenueEstimateComplete_PriorYear) as RevenueEstimateComplete_PriorYear
,	sum(a.CostEstimateComplete_PriorYear) as CostEstimateComplete_PriorYear
,	sum(a.RevenueEstimateComplete_PriorMonth) as RevenueEstimateComplete_PriorMonth
,	sum(a.CostEstimateComplete_PriorMonth) as CostEstimateComplete_PriorMonth
	
,	case when sum(a.RevenueEstimateComplete_ToDate) - sum(a.CostEstimateComplete_ToDate) <= 0
			then sum(a.RevenueEstimateComplete_ToDate) + sum(a.ActualCostToDate) - sum(a.CostEstimateComplete_ToDate)
		 when sum(a.CostEstimateComplete_ToDate)<>0
			then (sum(a.ActualCostToDate) / sum(a.CostEstimateComplete_ToDate))*sum(a.RevenueEstimateComplete_ToDate)
	end as EarnedRevenue_ToDate	 	
	
,	case when sum(a.RevenueEstimateComplete_PriorYear) - sum(a.CostEstimateComplete_PriorYear) <= 0
			then sum(a.RevenueEstimateComplete_PriorYear) + sum(a.ActualCostPriorYear) - sum(a.CostEstimateComplete_PriorYear)
		 when sum(a.CostEstimateComplete_PriorYear)<>0
			then (sum(a.ActualCostPriorYear) / sum(a.CostEstimateComplete_PriorYear))*sum(a.RevenueEstimateComplete_PriorYear)
	end as EarnedRevenue_PriorYear	 	

,	case when sum(a.RevenueEstimateComplete_PriorMonth) - sum(a.CostEstimateComplete_PriorMonth) <= 0
			then sum(a.RevenueEstimateComplete_PriorMonth) + sum(a.ActualCostPriorMonth) - sum(a.CostEstimateComplete_PriorMonth)
		 when sum(a.CostEstimateComplete_PriorMonth)<>0
			then (sum(a.ActualCostPriorMonth) / sum(a.CostEstimateComplete_PriorMonth))*sum(a.RevenueEstimateComplete_PriorMonth)
	end as EarnedRevenue_PriorMonth


From JobCostRevenueByContract a
LEFT JOIN JCCM 
	ON  JCCM.JCCo = a.JCCo
	AND JCCM.Contract = a.Contract
LEFT JOIN JCDM
	ON  JCDM.JCCo = a.JCCo
	AND JCDM.Department = a.Department
LEFT JOIN JCMP
	ON  JCMP.JCCo = a.JCCo
	AND JCMP.ProjectMgr = a.ProjectMgr
LEFT JOIN PCPotentialWork PC
	ON	PC.JCCo = a.JCCo
	AND	PC.PotentialProject = a.Contract
	
WHERE a.PendingStatus = (case when @IncludePotential='N' then 'Interfaced' else a.PendingStatus end)
Group By a.JCCo
	  ,	 a.Contract
	  ,  a.Department
	  ,  a.ProjectMgr
	  
),

--select * From JCWIPData

/**
 JCWIPDataFinal CTE:
 
 CTE prepares data for the final SQL statement that returns data to the report.
 Returns one data set by Contract and a second one for subtotals by
 Department or Project Manager / Open Closed Status / Small Contracts
 **/
 
 

JCWIPDataFinal

as

/**
First Statement in JCWIPDataFinal.  One row per Department/Contract.
 Restricted to Open contracts if summarizing closed contracts on one line.
 Also returns only small contracts (if not already included in closed line summary)
 **/

(Select 
	
		1  as RowType /*Used for Sorting in report*/
	,	JCWIPData.Contract
	,	JCWIPData.ContractDescription
	,	JCWIPData.StartMonth
	,	JCWIPData.OpenClosedStatus
	,	JCWIPData.DeptPMSort	 
	,	JCWIPData.DeptPMSortDescription	 
	/*,	Case when @SortContractOption='C'	
				then row_number() over (order by JCWIPData.Contract asc) 
			 when @SortContractOption='A'
				then row_number() over (order by JCWIPData.ContractAmt desc) 
			 when @SortContractOption='M'
				then row_number() over (order by JCWIPData.StartMonth asc) 
			 when @SortContractOption='G'
				then row_number () over (order by (JCWIPData.RevenueEstimateComplete_ToDate - JCWIPData.CostEstimateComplete_ToDate) desc) 									
		End
		as ContractSort	*/
	,	JCWIPData.ContractSort	
	,	'N' as SubTotalYN
	--,	ContractSort
	,	SmallContractYN
	,	JCWIPData.OrigContractAmt
	,	JCWIPData.ContractAmt
	,	JCWIPData.BilledAmtToDate
	,	JCWIPData.BilledAmtPriorYear
	,	JCWIPData.BilledAmtPriorMonth
	,	JCWIPData.ReceivedAmt
	,	JCWIPData.CurrentRetainAmt
	,	JCWIPData.BilledTax
	,	JCWIPData.ProjDollarsToDate
	,	JCWIPData.ActualHours 
	,	JCWIPData.ActualCostToDate
	,	JCWIPData.ActualCostPriorYear
	,	JCWIPData.ActualCostPriorMonth
	,	JCWIPData.OrigEstHours
	,	JCWIPData.OrigEstCost
	,	JCWIPData.CurrEstHours
	,	JCWIPData.CurrEstCost
	,	JCWIPData.ProjHours
	,	JCWIPData.ProjCost
	,	JCWIPData.ForecastHours
	,	JCWIPData.ForecastCost
	,	JCWIPData.TotalCmtdCost
	,	JCWIPData.RemainCmtdCost
	,	JCWIPData.RecvdNotInvcdCost
	,	JCWIPData.RevenueEstimateComplete_ToDate
	,	JCWIPData.CostEstimateComplete_ToDate
	,	JCWIPData.RevenueEstimateComplete_PriorYear
	,	JCWIPData.CostEstimateComplete_PriorYear
	,	JCWIPData.RevenueEstimateComplete_PriorMonth
	,	JCWIPData.CostEstimateComplete_PriorMonth
	,	JCWIPData.EarnedRevenue_ToDate
	,	JCWIPData.EarnedRevenue_PriorYear
	,	JCWIPData.EarnedRevenue_PriorMonth
	,	(case when BilledAmtToDate > EarnedRevenue_ToDate 
					then BilledAmtToDate - EarnedRevenue_ToDate
			end) as BillingExcessOfCost
	,	(case when BilledAmtToDate < EarnedRevenue_ToDate 
					then BilledAmtToDate - EarnedRevenue_ToDate
			end) as CostExcessOfBilling
	
From JCWIPData
where JCWIPData.OpenClosedStatus 
<> (case when @SummarizeCloseContract='Y' then '2' else '255' end)
and SmallContractYN = 'N'

union all

/**
 Select statement returns Subtotals by:
    Department or Project Manager / Status (Open or Closed) / Small Contracts
**/ 

Select 
		case when SmallContractYN='Y' then 2
			 else 3
		end	  as RowType	/*Row Type = 2 for small contracts, 3 for subtotals*/
	,	NULL as Contract
	,	NULL as ContractDescription
	,	NULL as StartMonth
	,	JCWIPData.OpenClosedStatus
	,	JCWIPData.DeptPMSort	 
	,	max(JCWIPData.DeptPMSortDescription) as DeptPMSortDescription
	,	0 as ContractSort
	,	'Y' as SubTotalYN
	,	SmallContractYN
	,	sum(OrigContractAmt)
	,	sum(ContractAmt)
	,	sum(BilledAmtToDate)
	,	sum(BilledAmtPriorYear)
	,	sum(BilledAmtPriorMonth)
	,	sum(ReceivedAmt)
	,	sum(CurrentRetainAmt)
	,	sum(BilledTax)
	,	sum(ProjDollarsToDate)
	,	sum(ActualHours) 
	,	sum(ActualCostToDate)
	,	sum(ActualCostPriorYear)
	,	sum(ActualCostPriorMonth)
	,	sum(OrigEstHours)
	,	sum(OrigEstCost)
	,	sum(CurrEstHours)
	,	sum(CurrEstCost) 
	,	sum(ProjHours)
	,	sum(ProjCost)
	,	sum(ForecastHours)
	,	sum(ForecastCost)
	,	sum(TotalCmtdCost)
	,	sum(RemainCmtdCost)
	,	sum(RecvdNotInvcdCost)
	,	sum(RevenueEstimateComplete_ToDate)
	,	sum(CostEstimateComplete_ToDate)
	,	sum(RevenueEstimateComplete_PriorYear)
	,	sum(CostEstimateComplete_PriorYear)
	,	sum(RevenueEstimateComplete_PriorMonth)
	,	sum(CostEstimateComplete_PriorMonth)
	,	sum(EarnedRevenue_ToDate)
	,	sum(EarnedRevenue_PriorYear)
	,	sum(EarnedRevenue_PriorMonth)
	,	sum(case when BilledAmtToDate > EarnedRevenue_ToDate 
					then BilledAmtToDate - EarnedRevenue_ToDate
			end) as BillingExcessOfCost
	,	sum(case when BilledAmtToDate < EarnedRevenue_ToDate 
					then BilledAmtToDate - EarnedRevenue_ToDate
			end) as CostExcessOfBilling
						
	
From JCWIPData


Group By	DeptPMSort
		 ,	OpenClosedStatus
		 ,	SmallContractYN


With rollup	--Used to create extra subtotal rows for DeptPMSort, OpenClosedStatus, SmallContractYN

)

/****
 Final Select:  Returns data to report.
 Contract:  Set to Contract (if RowType = 1), zzzSmallContract (if RowType = 2)
			zzzzzzzz for subtotal rows
			
*****/			

Select 
	  @CompanyName as CompanyName
	, JCWIPDataFinal.RowType
	, case	when RowType = 1 
				then JCWIPDataFinal.Contract 
			when RowType = 2
				then 'zzzSmallContract'
			else 
				'zzzzzzzzzz'
	   end as Contract 
								
	,	JCWIPDataFinal.ContractDescription
	
	,	JCWIPDataFinal.DeptPMSort
	
	, JCWIPDataFinal.OpenClosedStatus
					 
	, JCWIPDataFinal.DeptPMSortDescription	 
	
	,	case when SmallContractYN='N' then JCWIPDataFinal.ContractSort else 0 end as ContractSort
	,	SmallContractYN
	,	SubTotalYN
	,	j.ColumnNumber		
	,	JCWIPDataFinal.OrigContractAmt
	,	JCWIPDataFinal.ContractAmt
	,	JCWIPDataFinal.BilledAmtToDate
	,	JCWIPDataFinal.BilledAmtPriorYear
	,	JCWIPDataFinal.BilledAmtPriorMonth
	,	JCWIPDataFinal.ReceivedAmt
	,	JCWIPDataFinal.CurrentRetainAmt
	,	JCWIPDataFinal.BilledTax
	,	JCWIPDataFinal.ProjDollarsToDate
	,	JCWIPDataFinal.ActualHours 
	,	JCWIPDataFinal.ActualCostToDate
	,	JCWIPDataFinal.ActualCostPriorYear
	,	JCWIPDataFinal.ActualCostPriorMonth
	,	JCWIPDataFinal.OrigEstHours
	,	JCWIPDataFinal.OrigEstCost
	,	JCWIPDataFinal.CurrEstHours
	,	JCWIPDataFinal.CurrEstCost
	,	JCWIPDataFinal.ProjHours
	,	JCWIPDataFinal.ProjCost
	,	JCWIPDataFinal.ForecastHours
	,	JCWIPDataFinal.ForecastCost
	,	JCWIPDataFinal.TotalCmtdCost
	,	JCWIPDataFinal.RemainCmtdCost
	,	JCWIPDataFinal.RecvdNotInvcdCost
	,	JCWIPDataFinal.RevenueEstimateComplete_ToDate
	,	JCWIPDataFinal.CostEstimateComplete_ToDate
	,	JCWIPDataFinal.RevenueEstimateComplete_PriorYear
	,	JCWIPDataFinal.CostEstimateComplete_PriorYear
	,	JCWIPDataFinal.RevenueEstimateComplete_PriorMonth
	,	JCWIPDataFinal.CostEstimateComplete_PriorMonth
	,	JCWIPDataFinal.EarnedRevenue_ToDate
	,	JCWIPDataFinal.EarnedRevenue_PriorYear
	,	JCWIPDataFinal.EarnedRevenue_PriorMonth
	,	JCWIPDataFinal.BillingExcessOfCost
	,	JCWIPDataFinal.CostExcessOfBilling
	
From JCWIPDataFinal
CROSS JOIN @JCWIPRows j
 where (DeptPMSort is not null and (Case when OpenClosedStatus is not null then SmallContractYN end) is not null)

	  
	  /*where statement excludes extra subtotal not needed for report
	    (removes subtotal of non-small contracts (SmallContractYN='N')
         that were rolled up in the JCWIPDataFinal CTE)*/ 

union all

Select 
	  @CompanyName as CompanyName
	, 3 as RowType
	, NULL as Contract 
								
	, NULL as ContractDescription
	
	, 'zzzGrandTotal' as DeptPMSort
	
	, NULL as OpenClosedStatus  /*Set OpenClosedStatus to zzzDeptSubTotal so that Dept subtotals sort after Open/Close subtotals*/
		
		
	/*,	JCWIPDataFinal.Contract
	,	JCWIPDataFinal.ContractDescription
	,	JCWIPDataFinal.DeptPMSort	
	,	JCWIPDataFinal.OpenClosedStatus*/
	
					 
	,	NULL as DeptPMSortDescription	 
	
	,	0 as ContractSort
	,	NULL as SmallContractYN
	,	NULL asSubTotalYN
	,	j.ColumnNumber		
	,	sum(JCWIPDataFinal.OrigContractAmt) 
	,	sum(JCWIPDataFinal.ContractAmt) 
	,	sum(JCWIPDataFinal.BilledAmtToDate) 
	,	sum(JCWIPDataFinal.BilledAmtPriorYear) 
	,	sum(JCWIPDataFinal.BilledAmtPriorMonth)
	,	sum(JCWIPDataFinal.ReceivedAmt) 
	,	sum(JCWIPDataFinal.CurrentRetainAmt) 
	,	sum(JCWIPDataFinal.BilledTax) 
	,	sum(JCWIPDataFinal.ProjDollarsToDate) 
	,	sum(JCWIPDataFinal.ActualHours) 
	,	sum(JCWIPDataFinal.ActualCostToDate)
	,	sum(JCWIPDataFinal.ActualCostPriorYear)
	,	sum(JCWIPDataFinal.ActualCostPriorMonth)
	,	sum(JCWIPDataFinal.OrigEstHours)
	,	sum(JCWIPDataFinal.OrigEstCost)
	,	sum(JCWIPDataFinal.CurrEstHours)
	,	sum(JCWIPDataFinal.CurrEstCost)
	,	sum(JCWIPDataFinal.ProjHours)
	,	sum(JCWIPDataFinal.ProjCost)
	,	sum(JCWIPDataFinal.ForecastHours)
	,	sum(JCWIPDataFinal.ForecastCost)
	,	sum(JCWIPDataFinal.TotalCmtdCost)
	,	sum(JCWIPDataFinal.RemainCmtdCost)
	,	sum(JCWIPDataFinal.RecvdNotInvcdCost)
	,	sum(JCWIPDataFinal.RevenueEstimateComplete_ToDate)
	,	sum(JCWIPDataFinal.CostEstimateComplete_ToDate)
	,	sum(JCWIPDataFinal.RevenueEstimateComplete_PriorYear)
	,	sum(JCWIPDataFinal.CostEstimateComplete_PriorYear)
	,	sum(JCWIPDataFinal.RevenueEstimateComplete_PriorMonth)
	,	sum(JCWIPDataFinal.CostEstimateComplete_PriorMonth)
	,	sum(JCWIPDataFinal.EarnedRevenue_ToDate)
	,	sum(JCWIPDataFinal.EarnedRevenue_PriorYear)
	,	sum(JCWIPDataFinal.EarnedRevenue_PriorMonth)
	,	sum(JCWIPDataFinal.BillingExcessOfCost)
	,	sum(JCWIPDataFinal.CostExcessOfBilling)
	
From JCWIPDataFinal
CROSS JOIN @JCWIPRows j
where OpenClosedStatus is null and SmallContractYN is null and DeptPMSort not in ('zzzPending','zzzPotential')
group by j.ColumnNumber


union all

/*Select Statement returns DeptPMSort and Status header rows for the report.  
Only selects from subtotal type rows (RowType 3)*/

Select 

		@CompanyName as CompanyName
	,	0 as RowType	
	,	NULL as Contract
	,	NULL as ContractDescription
	,	JCWIPDataFinal.DeptPMSort	
	,	JCWIPDataFinal.OpenClosedStatus
	,	max(JCWIPDataFinal.DeptPMSortDescription)
	,	0 as ContractSort	
	,	'N' as SmallContractYN
	,	'N' as SubTotalYN
	,	1 as ColumnNumber
	,	0 as OrigContractAmt
	,	0 as ContractAmt
	,	0 as BilledAmtToDate
	,	0 as BilledAmtPriorYear
	,	0 as BilledAmtPriorMonth
	,	0 as ReceivedAmt
	,	0 as CurrentRetainAmt
	,	0 as BilledTax
	,	0 as ProjDollarsToDate
	,	0 as ActualHours
	,	0 as ActualCostToDate
	,	0 as ActualCostPriorYear
	,	0 as ActualCostPriorMonth
	,	0 as OrigEstHours
	,	0 as OrigEstCost
	,	0 as CurrEstHours
	,	0 as CurrEstCost
	,	0 as ProjHours
	,	0 as ProjCost
	,	0 as ForecastHours
	,	0 as ForecastCost
	,	0 as TotalCmtdCost
	,	0 as RemainCmtdCost
	,	0 as RecvdNotInvcdCost
	,	0 as RevenueEstimateComplete_ToDate
	,	0 as CostEstimateComplete_ToDate
	,	0 as RevenueEstimateComplete_PriorYear
	,	0 as CostEstimateComplete_PriorYear
	,	0 as RevenueEstimateComplete_PriorMonth
	,	0 as CostEstimateComplete_PriorMonth
	,	0 as EarnedRevenue_ToDate
	,	0 as EarnedRevenue_PriorYear
	,	0 as EarnedRevenue_PriorMonth
	,	0 as BillingExcessOfCost
	,	0 as CostExcessOfBilling
	
From JCWIPDataFinal
where RowType = 3
	  --and (DeptPMSort is not null and (Case when OpenClosedStatus is not null then SmallContractYN end) is not null)
	  and Contract is null 
	  and isnull(OpenClosedStatus,0) /*Exclude Closed Contract Header row if summarize closed contract on one line*/
		  <> (case when @SummarizeCloseContract='Y' then '2' else '255' end)
	  and DeptPMSort is not null 
group by JCWIPDataFinal.DeptPMSort, JCWIPDataFinal.OpenClosedStatus	  

















GO
GRANT EXECUTE ON  [dbo].[vrptJCWIP] TO [public]
GO
