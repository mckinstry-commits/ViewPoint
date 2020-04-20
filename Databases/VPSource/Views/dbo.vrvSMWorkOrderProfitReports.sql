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
  
Parameters:
NA  
  
Related reports:  
SM Work Order Profitability Detail (ID: 1183)
SM Work Order Profitability Drilldown (ID: 1200)
SM Work Order Profitability Summary (ID: 1184)
      
Revision History      
Date  Author  Issue     Description  
  
***********************************************************************/    

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
	, smwc.NoCharge  
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
	, smwc.CostQuantity  
	, smwc.POCo
	, smwc.PO
	, smwc.PONumber
	, smwc.POItem
	, smwc.POItemLine
	, (case when isnull(smwc.ActualCost,0) = 0 then smwc.ProjCost else smwc.ActualCost end) as ActProjCost
	, (case when isnull(smwc.ActualCost,0) = 0 and isnull(smwc.ProjCost,0) <> 0 then 'P' else 'A' end) as ActProjFlag 
	-----  
	, smwca.ARTrans  
	-----  
	, smct.Description as CostTypeDescription  
	-----  
	, smlt.LineType  
	, smlt.Description as LineTypeDescription  
	-----  
	, smwos.Status  
	-----  
	, smwosc.Scope as WorkOrderScope  
	, smwosc.WorkScope  
	, smwosc.Description as WorkOrderScopeDescription  
	, smwosc.CallType  
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
	SMWorkCompleted smwc ON   
		smwo.SMCo = smwc.SMCo   
		AND smwo.WorkOrder = smwc.WorkOrder  
LEFT OUTER JOIN  
	SMCostType smct ON  
		smwc.SMCo = smct.SMCo  
		and smwc.SMCostType = smct.SMCostType  
LEFT OUTER JOIN   
	HQCO hq ON   
		smwo.SMCo = hq.HQCo   
INNER JOIN   
	SMLineType smlt ON   
		smwc.Type = smlt.LineType   
LEFT OUTER JOIN   
	SMWorkOrderStatus smwos ON   
		smwc.SMCo = smwos.SMCo   
		AND smwc.WorkOrder = smwos.WorkOrder   
LEFT OUTER JOIN   
	SMWorkOrderScope smwosc ON   
		smwc.SMCo = smwosc.SMCo   
		AND smwc.WorkOrder = smwosc.WorkOrder   
		AND smwc.Scope = smwosc.Scope   
LEFT OUTER JOIN   
	SMTechnician smt ON   
		smwc.SMCo = smt.SMCo   
		AND smwc.Technician = smt.Technician   
LEFT OUTER JOIN   
	SMWorkCompletedARTL smwca ON   
		smwc.SMWorkCompletedARTLID = smwca.SMWorkCompletedARTLID   
LEFT OUTER JOIN   
	PREH pr ON   
		smt.PRCo = pr.PRCo   
		AND smt.Employee = pr.Employee   
LEFT OUTER JOIN   
	SMCustomer smc ON   
		sssc.TrueCustGroup = smc.CustGroup   
		AND sssc.TrueCustomer = smc.Customer   
		and sssc.SMCo = smc.SMCo  
LEFT OUTER JOIN   
	ARCM ar ON   
		smc.CustGroup = ar.CustGroup   
		AND smc.Customer = ar.Customer  
GO
GRANT SELECT ON  [dbo].[vrvSMWorkOrderProfitReports] TO [public]
GRANT INSERT ON  [dbo].[vrvSMWorkOrderProfitReports] TO [public]
GRANT DELETE ON  [dbo].[vrvSMWorkOrderProfitReports] TO [public]
GRANT UPDATE ON  [dbo].[vrvSMWorkOrderProfitReports] TO [public]
GO
