SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[vrvSMWorkOrderProfitReports]
AS 

/***********************************************************************      
Author:   
Scott Alvey  
     
Create date:   
11/27/2012   
      
Usage:
Before this view the three WO profit reports (Profitability Detail, Drilldown, and Summary)
were each using their own code to get at the data. Rather then have the upkeep overhead of
three different code sets for three reports that essentially look at the same data, but in 
different ways, this view was created to support all three reports. 

There is nothing really fancy here, just getting work completed records and then related data
from PR (to get technician), AR (to see if something has been billed or not), and then some 
realted maint. tables for things like SM Cost Types, Line Types, and such. 

Adding the FP lines was a bit of hack, especially when pulling from SMLT as when writing this there
is no Line Type 6 = Subcontract. May need to revisit this down the road.
  
Parameters:
NA  
  
Related reports:  
SM Work Order Profitability Detail (ID: 1183)
SM Work Order Profitability Drilldown (ID: 1200)
SM Work Order Profitability Summary (ID: 1184)
      
Revision History      
Date  Author  Issue     Description  

04/25/2013	JVH	TFS-44860: SM - Edit Taxes on SM Invoice
The vSMWorkCompletedARTL is going to be dropped so any refrences to it were replaced
with SMInvoiceListDetail

06/18/2103 ScottAlvey TFS-53307 - Add flat price lines
  
***********************************************************************/    

WITH CTE_WorkCompFlatPriceLines AS

/***********************************************************************      
Usage:
Flat price lines may or may not have related work completed lines. They are also considered
fully billed when the related work order is invoiced AND there concept of line type is
different when compared the work completed line type. The CTE below tries to merge WC and FP
records into a single view in a way that would allow the returned records to all be treated
as work completed lines. The case statement in the FP side of the union attempts to 
translate FP cost types into WC line types

Some of the related reports filter on Date. Since Date is coming from WC lines the second
part of the union hard codes a value of '01/01/1950' so that running those reports wide
open on the date value will still pick up FP lines. FP lines do not have a specific date
natively. Filtering on date may cause the FP lines to drop off as the users is probably 
looking for specific WC lines.

Because FP can billed split across invoices we need to look at the total BILLABLE amount for each 
FP scope, figure out what has been BILLED and come up with a percentage. We then apply that
percentage to the FP portion of the union to get the billed amount.
  
***********************************************************************/    

(
	SELECT
		s.SMCo
		, s.WorkOrder
		, s.Scope
		, c.Agreement
		, c.Revision
		, c.WorkCompleted	
		, c.Description
		, c.SMCostType  
		, c.Coverage  
		, (case when s.PriceMethod = 'N' then 'Y' else c.NoCharge end) as NoCharge
		, c.NonBillable
		, c.Type  
		, c.Scope as WorkCompletedScope  
		, c.Technician  
		, c.Date  
		, c.MonthToPostCost  
		, c.Quantity  
		, c.UM  
		, c.ProjCost  
		, c.ActualCost  
		, c.CostRate  
		, c.PriceRate  
		, c.PriceTotal 
		, 0 as FPBilledTotal 
		, c.CostQuantity  
		, c.POCo
		, c.PO
		, c.PONumber
		, c.POItem
		, c.POItemLine
		, (case when isnull(c.ActualCost,0) = 0 then c.ProjCost else c.ActualCost end) as ActProjCost
		, (case when isnull(c.ActualCost,0) = 0 and isnull(c.ProjCost,0) <> 0 then 'P' else 'A' end) as ActProjFlag 
	FROM
		SMWorkOrderScope s
	JOIN
		SMWorkCompleted c
			on s.SMCo = c.SMCo
			and s.WorkOrder = c.WorkOrder
			and s.Scope = c.Scope
			and c.IsSession = 0
			
	UNION ALL
	
	SELECT
		s.SMCo
		, s.WorkOrder
		, s.Scope
		, s.Agreement
		, s.Revision
		, 0 as WorkCompleted  
		, 'Flat Price Line' as Description  
		, f.CostType as SMCostType  
		, null as Coverage  
		, 'N' as NoCharge
		, 'N' as NonBillable
		, case f.CostTypeCategory
			when 'L' then 2
			when 'E' then 1
			when 'M' then 4
			when 'O' then 3
			when 'S' then 6
			else 0
		  end as CostTypeCategory
		, null as WorkCompletedScope  
		, null as Technician  
		, '01/01/1950' as Date  
		, null as MonthToPostCost  
		, null as Quantity  
		, null as UM  
		, null as ProjCost  
		, null as ActualCost  
		, null as CostRate  
		, null as PriceRate  
		, f.Amount as PriceTotal  
		, (f.Amount * (case when FPScopeTotal.FPTAmount <> 0 then FPBillingsTotal.FPBAmount / FPScopeTotal.FPTAmount else 0 end)) as FPBilledTotal
		, null as CostQuantity  
		, null as POCo
		, null as PO
		, null as PONumber
		, null as POItem
		, null as POItemLine
		, null as ActProjCost
		, null as ActProjFlag 
	FROM
		SMWorkOrderScope s
	JOIN
		SMEntity e on
			s.SMCo = e.SMCo
			and s.WorkOrder = e.WorkOrder
			and s.Scope = e.WorkOrderScope
	JOIN
		SMFlatPriceRevenueSplit f on
			e.SMCo = f.SMCo
			and e.EntitySeq = f.EntitySeq
	OUTER APPLY
		(
			SELECT
				SUM(fpt.Amount) as FPTAmount
			FROM
				SMFlatPriceRevenueSplit fpt --Flat Price totals
			WHERE
				f.SMCo = fpt.SMCo
				AND f.EntitySeq = fpt.EntitySeq
		) FPScopeTotal
	OUTER APPLY
		(
			SELECT
				SUM(fpb.Amount) as FPBAmount
			FROM
				vrvSMPreviousFlatPriceBillingsByInvoice fpb --Flat Price billings
			WHERE
				s.SMCo = fpb.SMCo
				AND s.WorkOrder = fpb.WorkOrder
				AND s.Scope = fpb.Scope
		) FPBillingsTotal
	WHERE 
		s.PriceMethod = 'F'
)		

SELECT    
	hq.HQCo  
	, hq.Name as CompanyName  
	-----  
	, ar.Name as CustomerName  
	-----  
	, smwo.SMCo  
	, smwo.WorkOrder  
	, smwo.Description as WorkOrderDescription  
	, smwo.ServiceSite  
	, smwo.ServiceCenter  
	, smwo.EnteredDateTime  
	-----  
	, sssc.Type as ServiceSiteType  
	, sssc.TrueDescription as ServiceSiteDescription  
	, sssc.TrueCustomer as ServiceSiteCustomer  
	-----  
	, smwc.WorkCompleted  
	, smwc.Description as WorkCompletedDescription  
	, smwc.SMCostType  
	, smwc.Coverage  
	, (case when smwosc.PriceMethod = 'N' then 'Y' else smwc.NoCharge end) as NoCharge
	, (case when smwosc.PriceMethod = 'N' then 'Y' else smwc.NonBillable end) as NonBillable
	, smwc.Type  
	, smwc.Scope as WorkCompletedScope  
	, smwc.Technician  
	, smwc.Date  
	, smwc.MonthToPostCost  
	, smwc.Quantity  
	, smwc.UM  
	, smwc.ProjCost  
	, smwc.ActualCost  
	, smwc.CostRate  
	, smwc.PriceRate  
	, smwc.PriceTotal  
	, smwc.FPBilledTotal
	, smwc.CostQuantity  
	, smwc.POCo
	, smwc.PO
	, smwc.PONumber
	, smwc.POItem
	, smwc.POItemLine
	, smwc.ActProjCost
	, smwc.ActProjFlag 
	, smwc.Agreement
	, smwc.Revision
	-----  
	, isnull(smildl_TM.ARTrans, smildl_FP.ARTrans) as ARTrans
	-----  
	, smct.Description as CostTypeDescription  
	-----  
	, isnull(smlt.LineType, smwc.Type) as LineType  
	, (case when smlt.LineType is null and smwc.Type = 6 then 'Subcontract' else smlt.Description end) as LineTypeDescription  
	-----  
	, smwos.Status  
	-----  
	, smwosc.Scope as WorkOrderScope  
	, smwosc.WorkScope  
	, smwosc.Description as WorkOrderScopeDescription  
	, smwosc.CallType  
	, smwosc.PriceMethod
	-----  
	, pr.LastName  
	, pr.FirstName

FROM     
	SMWorkOrder smwo   
INNER JOIN   
	vrvSMServiceSiteCustomer sssc ON   
		smwo.SMCo = sssc.SMCo   
		AND smwo.ServiceSite = sssc.ServiceSite
LEFT OUTER JOIN   
	SMCustomer smc ON   
		sssc.TrueCustGroup = smc.CustGroup   
		AND sssc.TrueCustomer = smc.Customer   
		and sssc.SMCo = smc.SMCo  
LEFT OUTER JOIN   
	ARCM ar ON   
		smc.CustGroup = ar.CustGroup   
		AND smc.Customer = ar.Customer 
LEFT OUTER JOIN   
	HQCO hq ON   
		smwo.SMCo = hq.HQCo   
LEFT OUTER JOIN   
	SMWorkOrderScope smwosc ON   
		smwo.SMCo = smwosc.SMCo   
		AND smwo.WorkOrder = smwosc.WorkOrder     
LEFT OUTER JOIN   
	CTE_WorkCompFlatPriceLines smwc ON   
		smwosc.SMCo = smwc.SMCo   
		AND smwosc.WorkOrder = smwc.WorkOrder  
		AND smwosc.Scope = smwc.Scope
LEFT OUTER JOIN  
	SMCostType smct ON  
		smwc.SMCo = smct.SMCo  
		and smwc.SMCostType = smct.SMCostType  
LEFT OUTER JOIN   
	SMLineType smlt ON   
		smwc.Type = smlt.LineType   
LEFT OUTER JOIN   
	SMWorkOrderStatus smwos ON   
		smwc.SMCo = smwos.SMCo   
		AND smwc.WorkOrder = smwos.WorkOrder   
LEFT OUTER JOIN   
	SMTechnician smt ON   
		smwc.SMCo = smt.SMCo   
		AND smwc.Technician = smt.Technician  
LEFT OUTER JOIN   
	PREH pr ON   
		smt.PRCo = pr.PRCo   
		AND smt.Employee = pr.Employee   
LEFT OUTER JOIN   
	SMInvoiceListDetailLine smildl_TM ON
		smwc.SMCo = smildl_TM.SMCo
		AND smwc.WorkOrder = smildl_TM.WorkOrder
		AND smwc.WorkCompleted = smildl_TM.WorkCompleted
OUTER APPLY
	(
		SELECT
			l.SMCo
			, l.WorkOrder
			, l.Scope
			, min(l.ARTrans) as ARTrans
		FROM
			SMInvoiceListDetailLine l
		WHERE
			l.SMCo = smwc.SMCo
			AND l.WorkOrder = smwc.WorkOrder
			AND l.Scope = smwc.Scope
			AND Scope is not null
			AND WorkCompleted is null
		GROUP BY
			SMCo
			, WorkOrder
			, Scope
	) smildl_FP
GO
GRANT SELECT ON  [dbo].[vrvSMWorkOrderProfitReports] TO [public]
GRANT INSERT ON  [dbo].[vrvSMWorkOrderProfitReports] TO [public]
GRANT DELETE ON  [dbo].[vrvSMWorkOrderProfitReports] TO [public]
GRANT UPDATE ON  [dbo].[vrvSMWorkOrderProfitReports] TO [public]
GRANT SELECT ON  [dbo].[vrvSMWorkOrderProfitReports] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvSMWorkOrderProfitReports] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvSMWorkOrderProfitReports] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvSMWorkOrderProfitReports] TO [Viewpoint]
GO
