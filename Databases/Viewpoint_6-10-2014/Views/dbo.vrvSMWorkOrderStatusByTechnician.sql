SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  view [dbo].[vrvSMWorkOrderStatusByTechnician]
as

/***********************************************************
CREATED BY:  HH 9/30/2011
MODIFIED By: 

USAGE:
This view lists all SM Technicians and their related 
SM Work Orders where they are "Lead Technicians" or have "Trips" 
and "Work Completed" assigned. In addition SM Work Scopes
DueAttention and BillingAttention is included, which means:
 
DueAttention = A Work Order Scope is due
BillingAttention = The amount of "WorkCompleted" is ready to 
be billed.

Report usage:
SM Work Order Status by Technician Drilldown (ID: 1185)

Revision History    
Date  Author  Issue     Description
04/12/2012	ScottAlvey	CL-????? / V1-B-08702: SM - Edit Taxes on SM Invoice
the vfSMWorkCompletedStatus was removed from the code base and needed to be 
removed from this view as well. We can now get the status the function returned
directly from SMWorkCompleted

*****************************************************/

WITH SMTechnicianWorkOrder
AS
(
	SELECT DISTINCT a.* FROM (
		SELECT t.SMCo, t.Technician, wo.WorkOrder 
		FROM SMTechnician t 
			INNER JOIN SMWorkOrder wo 
				ON t.SMCo = wo.SMCo AND t.Technician = wo.LeadTechnician
				
		UNION ALL
		
		SELECT t.SMCo, t.Technician, tr.WorkOrder 
		FROM SMTechnician t 
			INNER JOIN SMTrip tr 
				ON t.SMCo = tr.SMCo AND t.Technician = tr.Technician
				
		UNION ALL
		
		SELECT t.SMCo, t.Technician, wc.WorkOrder 
		FROM SMTechnician t 
			INNER JOIN SMWorkCompleted wc
				ON t.SMCo = wc.SMCo AND t.Technician = wc.Technician
	) a
)
SELECT	cte.SMCo 
		, cte.Technician
		, p.LastName + ', ' + p.FirstName AS TechnicianName
		, cte.WorkOrder
		, wost.[Status]
		, CASE
			WHEN cte.Technician = wo.LeadTechnician THEN 1
			ELSE 0
		END AS AssignedAsLeadTechnician
		, (	SELECT COUNT(*) 
			FROM SMTrip tr
			WHERE tr.SMCo = cte.SMCo 
					AND tr.Technician = cte.Technician
					AND tr.WorkOrder = cte.WorkOrder 
			) AS WorkOrderTripsAttended
		, (	SELECT COUNT(*) 
			FROM SMWorkCompleted wc
			WHERE wc.SMCo = cte.SMCo 
					AND wc.Technician = cte.Technician
					AND wc.WorkOrder = cte.WorkOrder 
					AND wc.Scope = wosc.Scope
			) AS WorkCompletedAssigned
		, cu.Customer
		, ar.Name AS CustomerName
		, wosc.Scope
		, wo.[Description] AS WorkOrderDescription
		, wosc.[Description] AS WorkScopeDescription
		, wo.[Description] + '   Scope: ' + wosc.[Description] AS [Description]
		, wo.ServiceSite
		, wo.ServiceCenter
		, wosc.CallType
		, wosc.WorkScope
		, CASE
			WHEN wosc.IsComplete = 'N' AND wosc.DueEndDate < GetDate() THEN 1
			ELSE 0 
		END AS DueAttention
		, (	SELECT COUNT(*) 
			FROM SMWorkCompleted wc
			WHERE wc.SMCo = cte.SMCo 
					AND wc.WorkOrder = cte.WorkOrder 
					AND wc.Technician = cte.Technician
					AND wc.Scope = wosc.Scope
					AND wc.Status = 'New'
			) AS BillingAttention
		, wo.EnteredDateTime AS WorkOrderEnteredDate
		, (	SELECT MAX([Date]) 
			FROM SMWorkCompleted wc
			WHERE wc.SMCo = cte.SMCo 
					AND wc.WorkOrder = cte.WorkOrder 
					AND wc.Scope = wosc.Scope 
					AND wc.[Type] = 2
			) AS WorkCompletedLastLaborDate
FROM SMTechnicianWorkOrder cte
	LEFT OUTER JOIN SMWorkOrder wo
		ON cte.SMCo = wo.SMCo AND cte.WorkOrder = wo.WorkOrder
	LEFT OUTER JOIN SMWorkOrderScope wosc
		ON cte.SMCo = wosc.SMCo AND cte.WorkOrder = wosc.WorkOrder
	LEFT OUTER JOIN SMWorkOrderStatus wost
		ON cte.SMCo = wost.SMCo AND cte.WorkOrder = wost.WorkOrder
	LEFT OUTER JOIN SMCustomer cu
		ON cte.SMCo = cu.SMCo AND wo.CustGroup = cu.CustGroup AND wo.Customer = cu.Customer
	LEFT OUTER JOIN ARCM ar
		ON ar.CustGroup = cu.CustGroup AND ar.Customer = cu.Customer
	LEFT OUTER JOIN SMTechnician st
		ON cte.SMCo = st.SMCo AND cte.Technician = st.Technician
	LEFT OUTER JOIN PREH p
		ON p.PRCo = st.PRCo AND p.Employee = st.Employee		



GO
GRANT SELECT ON  [dbo].[vrvSMWorkOrderStatusByTechnician] TO [public]
GRANT INSERT ON  [dbo].[vrvSMWorkOrderStatusByTechnician] TO [public]
GRANT DELETE ON  [dbo].[vrvSMWorkOrderStatusByTechnician] TO [public]
GRANT UPDATE ON  [dbo].[vrvSMWorkOrderStatusByTechnician] TO [public]
GRANT SELECT ON  [dbo].[vrvSMWorkOrderStatusByTechnician] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvSMWorkOrderStatusByTechnician] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvSMWorkOrderStatusByTechnician] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvSMWorkOrderStatusByTechnician] TO [Viewpoint]
GO
