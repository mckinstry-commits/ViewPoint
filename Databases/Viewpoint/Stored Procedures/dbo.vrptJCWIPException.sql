SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vrptJCWIPException]

(@Company tinyint, @BegCont varchar(10), @EndCont varchar(10), @BegDept varchar(10), @EndDept varchar(10), @Mth smalldatetime,
 @Status char(1),  @BegMthClosed smalldatetime, @EndMthClosed smalldatetime)

as

SELECT 
	Company
,	Name
,	ReportValues.Contract
,	JCCM.Description
,	ReportValues.Department
,	JCCM.ContractStatus
,	Sum(OriginalContract)		AS OriginalContract
,	Sum(ContractAmount)			AS ContractAmount
,	Sum(BilledAmount)			AS BilledAmount
,	Sum(ProjectedRevenue)		AS ProjectedRevenue
,	Sum(ActualCost)				AS ActualCost
,	Sum(CurrentEstimatedCost)	AS CurrentEstimatedCost
,	Sum(OriginalEstimatedCost)	AS OriginalEstimatedCost
,	Sum(ProjectedCost)			AS ProjectedCost
,	Sum(OriginalContract) - 
	sum(OriginalEstimatedCost)	AS OriginalContractProfit
,	Sum(OriginalContract) - 
	sum(ActualCost)				AS CurrentContractProfit
,	Sum(BilledAmount) - 
	sum(ActualCost)				AS ProfitBillingCost
,	Sum(ProjectedRevenue) - 
	sum(ProjectedCost)			AS ProjectedProfit
,	Sum (EstCostAtCompletionItem)	AS EstimatedCostAtCompletionItem
,	Sum (EstCostAtCompletionCT)	AS EstCostAtCompletionCT
,	Case When (Sum (EstCostAtCompletionItem) <> 0) Then (Sum(ActualCost)/Sum (EstCostAtCompletionItem))  Else 0 end as PercentCompleteItem
,   Case When (Sum (EstCostAtCompletionCT) <> 0) Then (Sum(ActualCost)/Sum (EstCostAtCompletionCT)) Else 0 end as PercentCompleteCT
,	Case When ((Sum(ProjectedRevenue) - Sum (EstCostAtCompletionItem))<= 0) 
			Then Sum(ProjectedRevenue) + Sum(ActualCost) -	Sum (EstCostAtCompletionItem)
			ELSE Case When (Sum (EstCostAtCompletionItem) <> 0) Then Sum(ActualCost)/Sum (EstCostAtCompletionItem) * Sum(ProjectedRevenue) Else 0 End
		End	 as EarnedRevenueItem
		
,	Case When ((Sum(ProjectedRevenue) - Sum (EstCostAtCompletionCT))<= 0) 
			Then Sum(ProjectedRevenue) + Sum(ActualCost) -	Sum (EstCostAtCompletionCT)
			ELSE Case When (Sum (EstCostAtCompletionCT) <> 0) Then Sum(ActualCost)/Sum (EstCostAtCompletionCT) * Sum(ProjectedRevenue) Else 0 End
		End	 as EarnedRevenueCT




FROM 
	(
SELECT 
		vrvJCCostRevenueExcept.JCCo AS Company
	,	vrvJCCostRevenueExcept.Contract
	,	vrvJCCostRevenueExcept.Item
	,	JCCI.Department as Department
	,	Sum(vrvJCCostRevenueExcept.OrigContractAmt) AS OriginalContract
	,	Sum(vrvJCCostRevenueExcept.ContractAmt) AS ContractAmount
	,	Sum(vrvJCCostRevenueExcept.BilledAmt) AS BilledAmount
	,	Sum(vrvJCCostRevenueExcept.ProjDollars) AS ProjectDollars
	,	Case When sum(ProjDollars) <> 0 Then
			Sum(ProjDollars)  Else
			Sum(vrvJCCostRevenueExcept.ContractAmt) End AS ProjectedRevenue                            
	,	Sum(ActualCost) AS ActualCost
	,	Sum(CurrEstCost) AS CurrentEstimatedCost
	,	Sum(OrigEstCost) AS OriginalEstimatedCost
	,	Sum(ProjCost) AS ProjectedCost
	,	Sum(Case When ProjMthItem <= @Mth Then ProjCost Else CurrEstCost End) as EstCostAtCompletionItem
	,	Sum(Case When ProjMthCT < @Mth Then ProjCost Else CurrEstCost End) as EstCostAtCompletionCT
	FROM 
		vrvJCCostRevenueExcept
Left Outer Join JCCI
ON vrvJCCostRevenueExcept.JCCo = JCCI.JCCo and vrvJCCostRevenueExcept.Contract = JCCI.Contract  and vrvJCCostRevenueExcept.Item = JCCI.Item


	WHERE 
			vrvJCCostRevenueExcept.JCCo = @Company
		AND vrvJCCostRevenueExcept.Contract >= @BegCont AND vrvJCCostRevenueExcept.Contract <=@EndCont
		AND vrvJCCostRevenueExcept.Mth <= @Mth
		AND JCCI.Department>= @BegDept and JCCI.Department <= @EndDept

	GROUP BY	vrvJCCostRevenueExcept.JCCo, vrvJCCostRevenueExcept.Contract, vrvJCCostRevenueExcept.Item, JCCI.Department


	) ReportValues
		INNER JOIN 
	HQCO 
		ON Company = HQCo 
		INNER JOIN 
	JCCM
		ON  JCCM.JCCo = ReportValues.Company
		AND JCCM.Contract = ReportValues.Contract

where 
/**Open and Soft Closed**/
 (
 (case when @Status in ('O','S') and JCCM.MonthClosed is not null 
		then JCCM.MonthClosed else '12/1/2050' end) > @Mth  /**If MonthClosed is null then set to 12/1/2050**/
   or
   
 (case when @Status = 'S' 
		then JCCM.ContractStatus end) = 2  /**Soft Closed = ContractStatus 2**/
 )
and
/**Restrict to Status 3 for closed contracts where MonthClosed is between @BegMthClosed and @EndMthClosed**/
ContractStatus = (case when @Status='C' 
						then 3 else JCCM.ContractStatus end)
and
(case when @Status='C' 
		then JCCM.MonthClosed else '12/1/2050' end) >= @BegMthClosed
and 
(case when @Status='C' 
		then JCCM.MonthClosed else '1/1/1950' end) <= @EndMthClosed
GROUP BY 
	Company
,	Name
,	ReportValues.Contract
,	JCCM.Description
,	ReportValues.Department
,	JCCM.ContractStatus
GO
GRANT EXECUTE ON  [dbo].[vrptJCWIPException] TO [public]
GO
