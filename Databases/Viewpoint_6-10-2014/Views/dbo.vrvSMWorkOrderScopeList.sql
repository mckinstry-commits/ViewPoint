SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  view [dbo].[vrvSMWorkOrderScopeList]
as

/***********************************************************************    
Author: 
Huy Huynh
   
Create date: 
10/17/2011  
    
Usage:
This view lists all SM Work Orders and their related SM Work Orders Scopes 
and sums up the Totals from dbo.vrvSMWorkOrderTotalsByLineType

Parameters:  
N/A

Related reports: 
SM Work Order List (ID#: 1187)    
    
Revision History    
Date  Author  Issue     Description
3/8/2012	ScottAlvey	CL-146033 / V1-D-04463: Customers have the ability to create 
	work complete lines that do have a billable dollar amount but are flagged as no charge. 
	SM Profit reports do not know if a line is no charge or not and includes the billable dollar 
	amount as truly billed, incorrectly inflating billed dollar values. This view needs to be 
	modified to be able know the difference between a no-charge line and chargeable line.
	All fields modified/added for this issue are marked with the CL number.
04/12/2012	ScottAlvey	CL-????? / V1-B-08702: SM - Edit Taxes on SM Invoice
	the vfSMWorkCompletedStatus was removed from the code base and needed to be 
	removed from this view as well. We can now get the status the function returned
	directly from SMWorkCompleted
08/27/2012	ScottAlvey	CL-????? / V1-D-05745 Related report is not showing Job Work Orders
	Even though this view does left outer joins to customer and service site information 
	the related report filters on some columns these joins bring back. So if the joins
	fail to return data even though the view as a whole returns lines related to that
	data, the report will filter that data out. In the case of Job related work orders
	the data surrounding Customer and ServiceSite was returning null data as the view
	was looking to SMCustomer and SMService site for that data. Job Customer has to look
	at JCCM, but first pass through JCJM to get the related JCCM record. A job
	service site has to do the same. I added the one CTE below to help the view 
	determine where to get the customer work orderinfomormation from. I also linked in
	vrvSMServiceSiteCustomer to get the true customer of the service site.
06/24/2013 DanK 53373 Added logic to include Flat Price Scope amounts. 
***********************************************************************/  

WITH

/*=================================================================================                      
CTE:
cte_WorkOrderCustomer

Added for V1-D-05745 change
                     
Usage: 
This CTE is used in the final sele t to get customer information regardless if the 
customer is SMCustomer based or JCCM based
          
Things to keep in mind regarding this report and proc:
To get an SMCustomer related customer for a customer work order is just linking 
SMWorkOrder to SMCustomer. But to get a customer records related to a job work order
we first have to through JCJM, them JCCM, and finall link in ARCM to the Contract.
In regards to the Active status of a customer, SMCustomer only cares about (A)ctive or 
(I)nactive, while ARCM expands on this in the form of Active, Inactive, and On-(H)old.
It has been decided to treat Active and On-Hold as the same in the context of this
report. 

Views:
SMWorkOrder
SMCustomer
ARCM linked to SMCustomer
JCJM
JCCM
ARCM linked to JCCM
==================================================================================*/ 

cte_WorkOrderCustomer

as

(
	SELECT
		smwo.SMCo
		, smwo.WorkOrder
		, smwo.JCCo
		, smwo.Job
		, c.Contract
		, (
			CASE WHEN smwo.Customer IS NULL 
				THEN 'J' --Job Type WO
				ELSE 'C' --Customer Type WO
			END
		  ) AS WorkOrderType
		, car.CustGroup AS carCustGroup
		, car.Customer AS carCustomer
		, jar.CustGroup AS jarCustGroup
		, jar.Customer AS jarCustomer
		, ISNULL(car.CustGroup, jar.CustGroup) AS CustGroup
		, ISNULL(car.Customer, jar.Customer) AS Customer
		, (
			CASE when smwo.Customer is not null 
				THEN smc.Active	
				ELSE 
					(
						CASE WHEN jar.Status in ('A', 'H')
							THEN 'Y'
							ELSE 'N'
						END
					)
			END
		  ) as Active
	FROM
		SMWorkOrder smwo
	LEFT OUTER JOIN
		SMCustomer smc ON 
			smwo.SMCo = smc.SMCo
			AND smwo.CustGroup = smc.CustGroup
			AND smwo.Customer = smc.Customer
	LEFT OUTER JOIN 
		ARCM car ON 
			smc.CustGroup = car.CustGroup 
			AND smc.Customer = car.Customer
	LEFT OUTER JOIN
		JCJM j ON 
			smwo.JCCo = j.JCCo
			AND smwo.Job = j.Job
	LEFT OUTER JOIN
		JCCM c ON 
			j.JCCo = c.JCCo
			AND j.Contract = c.Contract
	LEFT OUTER JOIN
		ARCM jar ON
			c.CustGroup = jar.CustGroup 
			AND c.Customer = jar.Customer		
), 

-- rolling up some of our values to make final calculations in the final select statement
cte_GetWORollups
AS 
(
	SELECT		/* WorkOrder */
				wo.SMCo, 
                wo.WorkOrder, 
                wost.[Status]					AS WorkOrderStatus, 
                wo.[Description]				AS WorkOrderDescription,
				wo.EnteredDateTime,
				wo.EnteredBy,
				(SELECT SUM(ISNULL(ActualCost,0)) 
					FROM SMWorkCompleted
					WHERE SMCo = wo.SMCo 
							AND WorkOrder = wo.WorkOrder) 
				AS WOActualCost,
				(SELECT SUM(ISNULL(ProjCost,0)) 
					FROM SMWorkCompleted
					WHERE SMCo = wo.SMCo 
							AND WorkOrder = wo.WorkOrder) 
				AS WOProjectedCost,	
--start 146033 mod
				(SELECT SUM(ISNULL((case when SMWorkCompleted.NoCharge = 'N' then SMWorkCompleted.PriceTotal else 0 end),0))  --added no charge check
					FROM SMWorkCompleted
					JOIN SMServiceSite 
						on SMWorkCompleted.SMCo = SMServiceSite.SMCo and SMWorkCompleted.ServiceSite = SMServiceSite.ServiceSite
					WHERE SMWorkCompleted.SMCo = wo.SMCo 
							AND SMWorkCompleted.WorkOrder = wo.WorkOrder 
							AND (SMWorkCompleted.Status = 'Billed' or SMServiceSite.Type = 'Job')) + SUM(ISNULL(PrevFPBilling.PrevAmount,0))
				AS WOSale,
				(SELECT MAX(NoCharge) 
					FROM SMWorkCompleted
					JOIN SMServiceSite 
						on SMWorkCompleted.SMCo = SMServiceSite.SMCo and SMWorkCompleted.ServiceSite = SMServiceSite.ServiceSite
					WHERE SMWorkCompleted.SMCo = wo.SMCo 
							AND SMWorkCompleted.WorkOrder = wo.WorkOrder 
							AND (SMWorkCompleted.Status = 'Billed' or SMServiceSite.Type = 'Job')) 
				AS WONoChargeFlag, -- new field for 146033
--end 146033 mod
				wo.LeadTechnician,
                p.LastName + ', ' + p.FirstName AS LeadTechnicianName,
				wo.ServiceCenter,
				wo.Notes						AS WorkOrderNotes,
				/* Count the scopes a work order has */
				(SELECT Count(Scope) 
					FROM SMWorkOrderScope
					WHERE SMWorkOrderScope.SMCo = wo.SMCo
						AND SMWorkOrderScope.WorkOrder = wo.WorkOrder
				)								
												AS CountScopesInWorkOrder,

				/* Customer */
				ar.Customer, 
				cu.Active						AS CustomerActive,
                ar.Name, 
                ar.[Address],
                ar.Address2,
				ar.City, 
				ar.[State], 
				ar.Zip,
				ar.Country,
				ar.Contact,
				ar.Phone,
				/* Count the sites a customer has*/
				(SELECT COUNT(ServiceSite) 
					FROM vrvSMServiceSiteCustomer SMServiceSite
					WHERE SMServiceSite.SMCo = wo.SMCo
						AND SMServiceSite.TrueCustomer = ar.Customer -- True Customer is SMServiceSite.Customer or JCCM.Customer
				)
												AS CountSitesForCustomer,
				
				/* ServiceSite */
                ss.ServiceSite, 
                ss.[Description]                AS ServiceSiteDescription, 
                ss.Address1						AS ServiceSiteAddress,
                ss.Address2						AS ServiceSiteAddress2,
				ss.City							AS ServiceSiteCity,
				ss.[State]						AS ServiceSiteState,		
				ss.Zip							AS ServiceSiteZip,
				ss.Country						AS ServiceSiteCountry,
                /* Appending contacts into a field (comma-separated values) */
                STUFF((SELECT ', ' + HQContact.FirstName + ' ' + 
                                     HQContact.LastName 
                              FROM   SMServiceSite 
                                     LEFT OUTER JOIN SMServiceSiteContact 
                                       ON SMServiceSite.SMCo = SMServiceSiteContact.SMCo 
                                          AND SMServiceSite.ServiceSite = SMServiceSiteContact.ServiceSite 
                                     LEFT OUTER JOIN HQContact 
                                       ON SMServiceSiteContact.ContactGroup = HQContact.ContactGroup 
                                          AND SMServiceSiteContact.ContactSeq = HQContact.ContactSeq 
                              WHERE  SMServiceSite.SMCo = wo.SMCo 
                                     AND SMServiceSite.ServiceSite = wo.ServiceSite 
                              ORDER  BY LastName 
                              FOR XML PATH('')), 1, 1, '') 
												AS ServiceSiteContact, 
                ss.Phone						AS ServiceSitePhone,
                ss.Active						AS SMServiceSiteActive,

				/* Scope */
				wosc.Scope, 
				wosc.Division					AS ScopeDivision,
				wosc.[Description]              AS ScopeDescription,
				wosc.DueEndDate					AS ScopeDate,
				wosc.IsComplete					AS ScopeIsComplete,
				wosc.Notes						AS ScopeNotes,
				
				/* Service Item */
                si.ServiceItem,
                si.Class						AS ServiceItemClass,
                si.[Type]						AS ServiceItemType
				
                
         FROM   SMWorkOrder wo 
                LEFT OUTER JOIN SMWorkOrderStatus wost 
                  ON wo.SMCo = wost.SMCo 
                     AND wo.WorkOrder = wost.WorkOrder 
                LEFT OUTER JOIN SMWorkOrderScope wosc 
                  ON wo.SMCo = wosc.SMCo 
                     AND wo.WorkOrder = wosc.WorkOrder 

				-- aggregate the Flat Price amounts for the work order. 
				OUTER APPLY (	SELECT		SUM(PB.Amount) AS PrevAmount
								FROM		vrvSMPreviousFlatPriceBillingsByInvoice PB
								WHERE		PB.SMCo			= wosc.SMCo
										AND PB.WorkOrder	= wosc.WorkOrder) PrevFPBilling

                LEFT OUTER JOIN SMTechnician st 
                  ON wo.SMCo = st.SMCo 
                     AND wo.LeadTechnician = st.Technician 
                LEFT OUTER JOIN PREH p 
                  ON p.PRCo = st.PRCo 
                     AND p.Employee = st.Employee 
                INNER JOIN cte_WorkOrderCustomer cu --was SMCustomer cu Added for V1-D-05745 change
                  ON wo.SMCo = cu.SMCo 
                     AND wo.WorkOrder = cu.WorkOrder
                LEFT OUTER JOIN ARCM ar 
                  ON ar.CustGroup = cu.CustGroup 
                     AND ar.Customer = cu.Customer 
                LEFT OUTER JOIN vrvSMServiceSiteCustomer ss --was SMServiceSite ss Added for V1-D-05745 change
                  ON wo.SMCo = ss.SMCo 
                     AND wo.ServiceSite = ss.ServiceSite
				LEFT OUTER JOIN SMServiceItems si
				  ON wo.SMCo = si.SMCo
				  AND wo.ServiceSite = si.ServiceSite
				  AND wosc.ServiceItem = si.ServiceItem
					 
	GROUP BY	wo.SMCo,
				wo.WorkOrder,
				wost.[Status],
				wo.[Description],
				wo.EnteredDateTime,
				wo.EnteredBy,
				wo.LeadTechnician,
				p.FirstName,
				p.LastName,
				wo.Notes,
				ar.Customer,
				ar.Name,
				ar.[Address],
				ar.Address2,
				ar.City,
				ar.[State],
				ar.Zip,
				ar.Country,
				ar.Contact,
				ar.Phone,
				ss.ServiceSite, 
				ss.[Description],
				ss.Address1,		
				ss.Address2,		
				ss.City,			
				ss.[State],		
				ss.Zip,
				ss.Country,
				wo.ServiceSite,
				ss.Phone,			
				wosc.Scope, 
				wosc.[Description],
				wosc.DueEndDate,	
				wosc.IsComplete,		
				wosc.Notes,			
				cu.Customer,
				cu.Active,			
				wo.ServiceCenter,
				wosc.Division,		
				ss.Active,			
				si.ServiceItem,
				si.Class,			
				si.[Type]			
)					

-- Final selection, perform any remaining simple calculations
SELECT		R.SMCo						AS 'SMCo', 
			R.WorkOrder					AS 'WorkOrder', 
			R.WorkOrderStatus			AS 'WorkOrderStatus', 
			R.WorkOrderDescription		AS 'WorkOrderDescription', 
			R.EnteredDateTime			AS 'EnteredDateTime', 
			R.EnteredBy					AS 'EnteredBy', 
			R.WOActualCost				AS 'WOActualCost', 
			R.WOProjectedCost			AS 'WOProjectedCost', 
			R.WOSale					AS 'WOSale', 
			R.WONoChargeFlag			AS 'WONoChargeFlag', 
			-- Margin in percentage = WOActualCost / WOSale * 100 - 100
			CASE 
				WHEN ISNULL(R.WOActualCost,0) = 0 OR ISNULL(R.WOSale,0) = 0
					THEN	0 
					ELSE	((R.WOSale - R.WOActualCost) / R.WOSale) * 100
			END							AS 'MarginInPct', 
			R.LeadTechnician			AS 'LeadTechnician', 
			R.LeadTechnicianName		AS 'LeadTechnicianName', 
			R.ServiceCenter				AS 'ServiceCenter', 
			R.WorkOrderNotes			AS 'WorkOrderNotes', 
			R.CountScopesInWorkOrder	AS 'CountScopesInWorkOrder', 
			R.Customer					AS 'Customer', 
			R.CustomerActive			AS 'CustomerActive', 
			R.Name						AS 'Name', 
			R.Address					AS 'Address', 
			R.Address2					AS 'Address2', 
			R.City						AS 'City', 
			R.State						AS 'State', 
			R.Zip						AS 'Zip', 
			R.Country					AS 'Country', 
			R.Contact					AS 'Contact', 
			R.Phone						AS 'Phone', 
			R.CountSitesForCustomer		AS 'CountSitesForCustomer', 
			R.ServiceSite				AS 'ServiceSite', 
			R.ServiceSiteDescription	AS 'ServiceSiteDescription', 
			R.ServiceSiteAddress		AS 'ServiceSiteAddress', 
			R.ServiceSiteAddress2		AS 'ServiceSiteAddress2', 
			R.ServiceSiteCity			AS 'ServiceSiteCity', 
			R.ServiceSiteState			AS 'ServiceSiteState', 
			R.ServiceSiteZip			AS 'ServiceSiteZip', 
			R.ServiceSiteCountry		AS 'ServiceSiteCountry', 
			R.ServiceSiteContact		AS 'ServiceSiteContact', 
			R.ServiceSitePhone			AS 'ServiceSitePhone', 
			R.SMServiceSiteActive		AS 'SMServiceSiteActive', 
			R.Scope						AS 'Scope', 
			R.ScopeDivision				AS 'ScopeDivision', 
			R.ScopeDescription			AS 'ScopeDescription', 
			R.ScopeDate					AS 'ScopeDate', 
			R.ScopeIsComplete			AS 'ScopeIsComplete', 
			R.ScopeNotes				AS 'ScopeNotes', 
			R.ServiceItem				AS 'ServiceItem', 
			R.ServiceItem				AS 'ServiceItemClass', 
			R.ServiceItemType			AS 'ServiceItemType'

FROM		cte_GetWORollups R
GO
GRANT SELECT ON  [dbo].[vrvSMWorkOrderScopeList] TO [public]
GRANT INSERT ON  [dbo].[vrvSMWorkOrderScopeList] TO [public]
GRANT DELETE ON  [dbo].[vrvSMWorkOrderScopeList] TO [public]
GRANT UPDATE ON  [dbo].[vrvSMWorkOrderScopeList] TO [public]
GRANT SELECT ON  [dbo].[vrvSMWorkOrderScopeList] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvSMWorkOrderScopeList] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvSMWorkOrderScopeList] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvSMWorkOrderScopeList] TO [Viewpoint]
GO
