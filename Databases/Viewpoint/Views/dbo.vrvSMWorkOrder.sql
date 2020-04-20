SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  view [dbo].[vrvSMWorkOrder]
as

/***********************************************************************    
Author: 
Huy Huynh
   
Create date: 
11/02/2011  
    
Usage:
This View contains all information the SM Work Order Report needs to display. 
It unions the SM WorkCompleted and SMTrip together and ties them to SMWorkOrder.   

Parameters:  
N/A

Related reports: 
SM Work Order (ID#: 1111)    
    
Revision History    
Date  Author  Issue     Description
3/8/2012	ScottAlvey	CL-146033 / V1-D-04463: Customers have the ability to create 
work complete lines that do have a billable dollar amount but are flagged as no charge. 
SM Profit reports do not know if a line is no charge or not and includes the billable dollar 
amount as truly billed, incorrectly inflating billed dollar values. This view needs to be 
modified to be able know the difference between a no-charge line and chargeable line.
All fields modified/added for this issue are marked with the CL number.

6/18/2012	ScottAlvey	CL-N/A	  / V1-B-09834: Add job information to SM Work Order rpt.
7/26/2012	ScottAlvey	CL-N/A    / V1-B-10482: Report not picking up Job Work Order
	added the CTE to help with this. It uses the veiw that is able to determine the true
	customer and custgroup by looking at SMServiceSite for Customer Service Sites or JCCM
	for Job Service Sites. 
08/31/2012	huyh		CL-N/A	  / V1-B-08659: Added Margin and Profit
	customer details and billing information

***********************************************************************/    
    

WITH

cteWorkOrderCustomer

as

(
	Select
		count(s.ServiceSite) as ServiceSiteCount
		, s.TrueCustomer as ServiceSiteCustomer
		, s.TrueCustGroup as ServiceSiteCustomerGroup
	From
		vrvSMServiceSiteCustomer s 
	Group by
		s.TrueCustomer
		, s.TrueCustGroup
		
),

cteSMWorkOrder   

AS 

(  

	-- SMWorkCompleted  
	SELECT 
		CASE WHEN wc.[Type] IS NULL 
			THEN 'WorkHeader'   
			ELSE 'WorkCompleted'  
		END AS RecordType  

	,wo.SMCo  
	,wo.WorkOrder  
	,wo.[Description] AS WorkOrderDescription  
	,wo.ServiceSite  
	,wo.ServiceCenter  
	,wo.LeadTechnician  
	,pwot.FirstName + ' ' + pwot.LastName AS LeadTechnicianName  
	,wost.[Status] AS WorkOrderStatus  
	,wo.RequestedBy  
	,wo.RequestedDate  

	,h.Name AS CompanyName  
	,h.[Address] AS CompanyAddress  
	,h.Address2 AS CompanyAddress2  
	,h.City AS CompanyCity  
	,h.[State] AS CompanyState  
	,h.Zip AS CompanyZip  
	,h.Phone AS CompanyPhone  
	,h.Country AS CompanyCountry  

	,isnull(ac.CustGroup,jobcust.CustGroup) AS CustomerGroup  
	,isnull(ac.Customer,jobcust.Customer) AS Customer  
	,isnull(ac.Name,jobcust.Name) AS CustomerName  
	,isnull(ac.[Address],jobcust.[Address]) AS CustomerAddress  
	,isnull(ac.Address2,jobcust.Address2) AS CustomerAddress2  
	,isnull(ac.City,jobcust.City) AS CustomerCity  
	,isnull(ac.[State],jobcust.[State]) AS CustomerState  
	,isnull(ac.Zip,jobcust.Zip) AS CustomerZip  
	,isnull(ac.Country,jobcust.Country) AS CustomerCountry  
	,isnull(ac.Contact,jobcust.Contact) AS CustomerContact  
	,isnull(ac.Phone,jobcust.Phone) AS CustomerPhone  
	,isnull(ac.Fax,jobcust.Fax) AS CustomerFax  
	,isnull(ac.EMail,jobcust.EMail) AS CustomerEMail  
	,sc.BillToARCustomer AS CustomerBillToARCustomer  

	,billToac.CustGroup AS ToBillCustomerGroup  
	,billToac.Customer AS ToBillCustomer  
	,billToac.Name AS ToBillCustomerName  
	,billToac.[Address] AS ToBillCustomerAddress  
	,billToac.Address2 AS ToBillCustomerAddress2  
	,billToac.City AS ToBillCustomerCity  
	,billToac.[State] AS ToBillCustomerState  
	,billToac.Zip AS ToBillCustomerZip  
	,billToac.Country AS ToBillCustomerCountry  
	,billToac.Contact AS ToBillCustomerContact  
	,billToac.Phone AS ToBillCustomerPhone  
	,billToac.Fax AS ToBillCustomerFax  
	,billToac.EMail AS ToBillCustomerEMail  

	/* Count the sites a customer has*/  
	,
		(
			SELECT 
				ServiceSiteCount   
			FROM 
				cteWorkOrderCustomer c  
			WHERE 
				c.ServiceSiteCustomerGroup = wo.CustGroup  
				AND c.ServiceSiteCustomer = isnull(wo.Customer, jobcust.Customer)
		)  
		AS CountSitesForCustomer  

	,ss.SMServiceSiteID AS ServiceSiteID  
	,ss.Address1 AS ServiceSiteAddress  
	,ss.Address2 AS ServiceSiteAddress2  
	,ss.City AS ServiceSiteCity  
	,ss.[State] AS ServiceSiteState   
	,ss.Zip AS ServiceSiteZip  
	,ss.Country AS ServiceSiteCountry  
	,ss.Phone AS ServiceSitePhone  
	,ss.ContactGroup AS ServiceSiteContactGroup  
	,ss.ContactSeq AS ServiceSiteContactSeq     
	,
		(
			SELECT 
				FirstName + ' ' + LastName  
			FROM 
				HQContact   
			WHERE 
				HQContact.ContactGroup = ss.ContactGroup  
				AND HQContact.ContactSeq = ss.ContactSeq  
		)       
		
		AS ServiceSiteContact  
	,ss.BillToARCustomer  AS ServiceSiteBillToARCustomer    

	,billToss.Customer AS ToBillServiceSiteID  
	,billToss.Name AS ToBillServiceSiteName  
	,billToss.[Address] AS ToBillServiceSiteAddress  
	,billToss.Address2 AS ToBillServiceSiteAddress2  
	,billToss.City AS ToBillServiceSiteCity  
	,billToss.[State] AS ToBillServiceSiteState  
	,billToss.Zip AS ToBillServiceSiteZip  
	,billToss.Country AS ToBillServiceSiteCountry  
	,billToss.Phone AS ToBillServiceSitePhone  
	,billToss.CustGroup AS ToBillServiceSiteCustGroup  
	,billToss.Contact AS ToBillServiceSiteContact  


	,wosc.Scope AS Scope  
	,wosc.WorkScope AS ScopeWorkScope  
	,wosc.Service AS ScopeService
	,wsc.[Description] AS ScopeWorkScopeDescription
	,smas.[Description]	AS ScopeServiceDescription  
	,wosc.[Description] AS ScopeDetail  
	,wosc.Notes AS ScopeNotes  
	,wosc.ServiceItem AS ScopeServiceItem  
	,wosc.IsComplete AS ScopeIsComplete  
	,wosc.CustomerPO AS ScopeCustomerPO  

	,wc.[Type] AS WorkCompletedType  
	,wc.[Date] AS WorkCompletedDate  
	,wc.Technician AS WorkCompletedTechnician  
	,pwct.FirstName + ' ' + pwct.LastName AS WorkCompletedTechnicianName  
	,wc.Equipment AS WorkCompletedEquipment    
	,wc.Part AS WorkCompletedPart  
	,wc.PO as WorkCompletedPO  
	,wc.StandardItem AS WorkCompletedStandardItem  
	,wc.[Description] AS WorkCompletedDescription  
	,wc.UM  AS WorkCompletedUM  
	,ISNULL(wc.Quantity, 0) AS WorkCompletedQuantity  
	,ISNULL(wc.CostQuantity, 0) AS WorkCompletedCostQuantity
	,ISNULL(wc.PriceQuantity, 0) AS WorkCompletedBillableHours    
	,ISNULL(wc.CostRate,0) AS WorkCompletedCostRate  
	,wc.CostECM AS WorkCompletedCostECM  
	,ISNULL(wc.PriceRate,0) AS WorkCompletedPriceRate  
	,wc.PriceECM AS WorkCompletedPriceECM  
	,ISNULL(wc.ActualCost,0) AS WorkCompletedActualCost  
	,ISNULL(wc.ProjCost,0) AS WorkCompletedProjCost  
	--start CL-146033 / V1-D-04463 mod  
	--,ISNULL(wc.PriceTotal,0) AS WorkCompletedPriceTotal  
	,ISNULL((case when NoCharge = 'N' then wc.PriceTotal else 0 end),0) AS WorkCompletedPriceTotal  
	,wc.NoCharge AS WorkCompletedNoChargeFlag -- new field for CL-146033 / V1-D-04463  
	-- Margin in percentage = ActualCost / PriceTotal * 100 - 100  
	--, CASE WHEN ISNULL(wc.ActualCost,0) <> 0   
	--		THEN ISNULL(wc.PriceTotal,0) / wc.ActualCost * 100 - 100  
	--		ELSE 0  
	--	END AS WorkCompletedMargin  
	--, CASE  
	--	WHEN ISNULL(wc.ActualCost,0) <> 0   
	--		THEN ISNULL((case when NoCharge = 'N' then wc.PriceTotal else 0 end),0) / wc.ActualCost * 100 - 100  
	--		ELSE 0  
	--	END AS WorkCompletedMarginOLD
	--end CL-146033 / V1-D-04463 mod  
	, CASE
		WHEN wc.NoCharge = 'Y' OR wc.PriceTotal IS NULL OR wc.PriceTotal = 0 THEN 
			-100
		ELSE 
			(wc.PriceTotal - wc.ActualCost) / wc.PriceTotal * 100
	END	AS WorkCompletedMargin  
	, CASE 
		WHEN wc.ActualCost = 0 THEN 
			NULL     
		ELSE ( 
				(
					CASE 
						WHEN (wc.NoCharge = 'Y') THEN  
							0 
						ELSE 
							wc.PriceTotal 
					END
				) - wc.ActualCost 
			  ) / wc.ActualCost * 100 
	END AS WorkCompletedProfit
	
	
	,NULL AS TripSMTripID  
	,NULL AS TripStatus  
	,NULL AS TripTechnician  
	,NULL AS TripTechnicianName  
	,NULL AS TripScheduledDate  
	,NULL AS TripDescription  
	,NULL AS TripEstimatedDuration
	
	--start V1-B-09834 mod - all new fields    
	,wo.JCCo AS JobCostCompanyID  
	,wo.Job AS JobCostJobNumber  
	,job.Description AS JobCostJobDescription   
	,wosc.Phase AS JobCostPhaseID  
	,phase.Description AS JobCostPhaseDescription  
	,wc.JCCostType AS JCCostTypeID  
	-- end V1-B-09834 mod

	FROM 
		SMWorkOrder wo  
	INNER JOIN 
		HQCO h ON 
			h.HQCo = wo.SMCo  
	INNER JOIN 
		SMWorkOrderStatus wost ON 
			wo.SMCo = wost.SMCo   
			and wo.WorkOrder = wost.WorkOrder   
	LEFT OUTER JOIN 
		SMWorkOrderScope wosc ON 
			wo.SMCo = wosc.SMCo   
			and wo.WorkOrder = wosc.WorkOrder  
	LEFT OUTER JOIN 
		SMWorkScope wsc ON 
			wosc.SMCo = wsc.SMCo   
			and wosc.WorkScope = wsc.WorkScope  
	LEFT OUTER JOIN 
		SMWorkCompleted wc ON 
			wosc.SMCo = wc.SMCo  
			and wosc.WorkOrder = wc.WorkOrder  
			and wosc.Scope = wc.Scope  
	LEFT OUTER JOIN 
		SMCustomer sc ON 
			sc.SMCo = wo.SMCo  
			and sc.CustGroup = wo.CustGroup  
			and sc.Customer = wo.Customer  
	LEFT OUTER JOIN 
		ARCM ac ON 
			ac.CustGroup = sc.CustGroup  
			and ac.Customer = sc.Customer   
	LEFT OUTER JOIN 
		ARCM billToac ON 
			billToac.CustGroup = sc.CustGroup  
			and billToac.Customer = sc.BillToARCustomer  
	LEFT OUTER JOIN 
		SMServiceSite ss ON 
			ss.SMCo = wo.SMCo  
			and ss.ServiceSite = wo.ServiceSite    
	LEFT OUTER JOIN 
		ARCM billToss ON 
			billToss.CustGroup = ss.CustGroup  
			and billToss.Customer = ss.BillToARCustomer 
	LEFT OUTER JOIN 
		SMAgreementService smas ON 
			wosc.SMCo = smas.SMCo
			and wosc.Agreement = smas.Agreement
			and wosc.Revision = smas.Revision
			and wosc.Service = smas.Service   
	LEFT OUTER JOIN 
		SMTechnician wcstec ON 
			wc.SMCo = wcstec.SMCo   
			AND wc.Technician = wcstec.Technician   
	LEFT OUTER JOIN 
		PREH pwct ON 
			pwct.PRCo = wcstec.PRCo   
			AND pwct.Employee = wcstec.Employee  
	LEFT OUTER JOIN 
		SMTechnician wostec ON 
			wo.SMCo = wostec.SMCo   
			AND wo.LeadTechnician = wostec.Technician   
	LEFT OUTER JOIN 
		PREH pwot ON 
			pwot.PRCo = wostec.PRCo   
			AND pwot.Employee = wostec.Employee  
	--start V1-B-09834 mod         
	LEFT OUTER JOIN 
		JCJM job on 
			wo.JCCo = job.JCCo  
			AND wo.Job = job.Job  
	LEFT OUTER JOIN 
		JCJP phase on 
			wosc.JCCo = phase.JCCo  
			and wosc.Job = phase.Job  
			and wosc.PhaseGroup = phase.PhaseGroup  
			and wosc.Phase = phase.Phase 
	--end V1-B-09834 mod
	--start V1-B-10482 mod
	LEFT OUTER JOIN
		JCCM contract on
			job.JCCo = contract.JCCo
			and job.Contract = contract.Contract
	LEFT OUTER JOIN
		ARCM jobcust on
			contract.CustGroup = jobcust.CustGroup
			and contract.Customer = jobcust.Customer
	--end V1-B-10482 mod
	UNION ALL  

	-- SMTrips  
	SELECT 
		'WorkTrip' AS RecordType    

		,wo.SMCo  
		,wo.WorkOrder  
		,wo.[Description] AS WorkOrderDescription  
		,wo.ServiceSite  
		,wo.ServiceCenter  
		,wo.LeadTechnician  
		,NULL AS LeadTechnicianName  
		,wost.[Status] AS WorkOrderStatus  
		,wo.RequestedBy  
		,wo.RequestedDate  

		,h.Name AS CompanyName  
		,h.[Address] AS CompanyAddress  
		,h.Address2 AS CompanyAddress2  
		,h.City AS CompanyCity  
		,h.[State] AS CompanyState  
		,h.Zip AS CompanyZip  
		,h.Phone AS CompanyPhone  
		,h.Country AS CompanyCountry  

		,isnull(ac.CustGroup,jobcust.CustGroup) AS CustomerGroup  
		,isnull(ac.Customer,jobcust.Customer) AS Customer  
		,isnull(ac.Name,jobcust.Name) AS CustomerName  
		,isnull(ac.[Address],jobcust.[Address]) AS CustomerAddress  
		,isnull(ac.Address2,jobcust.Address2) AS CustomerAddress2  
		,isnull(ac.City,jobcust.City) AS CustomerCity  
		,isnull(ac.[State],jobcust.[State]) AS CustomerState  
		,isnull(ac.Zip,jobcust.Zip) AS CustomerZip  
		,isnull(ac.Country,jobcust.Country) AS CustomerCountry  
		,isnull(ac.Contact,jobcust.Contact) AS CustomerContact  
		,isnull(ac.Phone,jobcust.Phone) AS CustomerPhone  
		,isnull(ac.Fax,jobcust.Fax) AS CustomerFax  
		,isnull(ac.EMail,jobcust.EMail) AS CustomerEMail  
		,sc.BillToARCustomer AS CustomerBillToARCustomer  

		,billToac.CustGroup AS ToBillCustomerGroup  
		,billToac.Customer AS ToBillCustomer  
		,billToac.Name AS ToBillCustomerName  
		,billToac.[Address] AS ToBillCustomerAddress  
		,billToac.Address2 AS ToBillCustomerAddress2  
		,billToac.City AS ToBillCustomerCity  
		,billToac.[State] AS ToBillCustomerState  
		,billToac.Zip AS ToBillCustomerZip  
		,billToac.Country AS ToBillCustomerCountry  
		,billToac.Contact AS ToBillCustomerContact  
		,billToac.Phone AS ToBillCustomerPhone  
		,billToac.Fax AS ToBillCustomerFax  
		,billToac.EMail AS ToBillCustomerEMail  

		/* Count the sites a customer has*/  
		,
		(
			SELECT 
				ServiceSiteCount   
			FROM 
				cteWorkOrderCustomer c  
			WHERE 
				c.ServiceSiteCustomerGroup = wo.CustGroup  
				AND c.ServiceSiteCustomer = isnull(wo.Customer, jobcust.Customer) 
		)  
		AS CountSitesForCustomer  

		,ss.SMServiceSiteID   AS ServiceSiteID  
		,ss.Address1    AS ServiceSiteAddress  
		,ss.Address2    AS ServiceSiteAddress2  
		,ss.City     AS ServiceSiteCity  
		,ss.[State]     AS ServiceSiteState   
		,ss.Zip      AS ServiceSiteZip  
		,ss.Country     AS ServiceSiteCountry  
		,ss.Phone     AS ServiceSitePhone  
		,ss.ContactGroup   AS ServiceSiteContactGroup  
		,ss.ContactSeq    AS ServiceSiteContactSeq  
		,
		(
			SELECT 
				FirstName + ' ' + LastName  
			FROM 
				HQContact   
			WHERE 
				HQContact.ContactGroup = ss.ContactGroup  
				AND HQContact.ContactSeq = ss.ContactSeq  
		)       
		
		AS ServiceSiteContact  
		,ss.BillToARCustomer  AS ServiceSiteBillToARCustomer  

		,billToss.Customer AS ToBillServiceSiteID  
		,billToss.Name AS ToBillServiceSiteName  
		,billToss.[Address] AS ToBillServiceSiteAddress  
		,billToss.Address2 AS ToBillServiceSiteAddress2  
		,billToss.City AS ToBillServiceSiteCity  
		,billToss.[State] AS ToBillServiceSiteState  
		,billToss.Zip AS ToBillServiceSiteZip  
		,billToss.Country AS ToBillServiceSiteCountry  
		,billToss.Phone AS ToBillServiceSitePhone  
		,billToss.CustGroup AS ToBillServiceSiteCustGroup  
		,billToss.Contact AS ToBillServiceSiteContact  

		,NULL AS Scope  
		,NULL AS ScopeWorkScope
		,NULL AS ScopeService  
		,NULL AS ScopeWorkScopeDescription
		,NULL AS ScopeServiceDescription   
		,NULL AS ScopeDetail  
		,NULL AS ScopeNotes  
		,NULL AS ScopeServiceItem  
		,NULL AS ScopeIsComplete  
		,NULL AS ScopeCustomerPO  

		,NULL AS WorkCompletedType  
		,NULL AS WorkCompletedDate  
		,NULL AS WorkCompletedTechnician  
		,NULL AS WorkCompletedTechnicianName  
		,NULL AS WorkCompletedEquipment    
		,NULL AS WorkCompletedPart
		,NULL AS WorkCompletedPO    
		,NULL AS WorkCompletedStandardItem  
		,NULL AS WorkCompletedDescription  
		,NULL AS WorkCompletedUM  
		,NULL AS WorkCompletedQuantity  
		,NULL AS WorkCompletedCostQuantity
		,NULL AS WorkCompletedBillableHours  
		,NULL AS WorkCompletedCostRate  
		,NULL AS WorkCompletedCostECM  
		,NULL AS WorkCompletedPriceRate  
		,NULL AS WorkCompletedPriceECM  
		,NULL AS WorkCompletedActualCost  
		,NULL AS WorkCompletedProjCost  
		,NULL AS WorkCompletedPriceTotal  
		,NULL AS WorkCompletedNoChargeFlag  
		,NULL AS WorkCompletedMargin  
		,NULL AS WorkCompletedProfit

		,t.SMTripID AS TripSMTripID  
		,t.[Status] AS TripStatus  
		,t.Technician AS TripTechnician  
		,ptt.FirstName + ' ' + ptt.LastName AS TripTechnicianName  
		,t.ScheduledDate AS TripScheduledDate  
		,t.[Description] AS TripDescription  
		,t.EstimatedDuration AS TripEstimatedDuration 
		 
		--start V1-B-09834 mod - all new fields    
		,isnull(wo.JCCo,0) AS JobCostCompanyID  
		,isnull(wo.Job,'') AS JobCostJobNumber  
		,job.Description AS JobCostJobDescription  
		,null AS JobCostPhaseID  
		,null AS JobCostPhaseDescription   
		,null AS JCCostTypeID 
		--end V1-B-09834 mod 
		

	FROM SMWorkOrder wo  
	INNER JOIN 
		HQCO h on 
			h.HQCo = wo.SMCo  
	INNER JOIN 
		SMWorkOrderStatus wost 
			ON wo.SMCo = wost.SMCo   
			and wo.WorkOrder = wost.WorkOrder   

	/* when SMTrip is tie to the Scope-Level 6.50?:  
	left outer join SMWorkOrderScope wosc  
	on wo.SMCo = wosc.SMCo   
	and wo.WorkOrder = wosc.WorkOrder*/  
	
	INNER JOIN 
		SMTrip t ON 
			wo.SMCo = t.SMCo  
			AND wo.WorkOrder = t.WorkOrder  
	/*AND wosc.Scope = t.Scope*/  
	LEFT OUTER JOIN 
		SMCustomer sc ON 
			sc.SMCo = wo.SMCo  
			AND sc.CustGroup = wo.CustGroup  
			AND sc.Customer = wo.Customer  
	LEFT OUTER JOIN 
		ARCM ac ON 
			ac.CustGroup = sc.CustGroup  
			AND ac.Customer = sc.Customer   
	LEFT OUTER JOIN 
		ARCM billToac ON 
			billToac.CustGroup = sc.CustGroup  
			AND billToac.Customer = sc.BillToARCustomer  
	LEFT OUTER JOIN 
		SMServiceSite ss ON 
			ss.SMCo = wo.SMCo  
			and ss.ServiceSite = wo.ServiceSite    
	LEFT OUTER JOIN 
		ARCM billToss ON 
			billToss.CustGroup = ss.CustGroup  
			and billToss.Customer = ss.BillToARCustomer  
	LEFT OUTER JOIN 
		SMTechnician tstec ON 
			t.SMCo = tstec.SMCo   
			AND t.Technician = tstec.Technician   
	LEFT OUTER JOIN 
		PREH ptt ON 
			ptt.PRCo = tstec.PRCo   
			AND ptt.Employee = tstec.Employee  
	--start V1-B-09834 mod          
	LEFT OUTER JOIN 
		JCJM job on 
			wo.JCCo = job.JCCo  
			AND wo.Job = job.Job
	--end V1-B-09834 mod
	--start V1-B-10482 mod 
	LEFT OUTER JOIN
		JCCM contract on
			job.JCCo = contract.JCCo
			and job.Contract = contract.Contract
	LEFT OUTER JOIN
		ARCM jobcust on
			contract.CustGroup = jobcust.CustGroup
			and contract.Customer = jobcust.Customer
	--end V1-B-10482 mod  

)  
	
	SELECT 
		*  
	FROM 
		cteSMWorkOrder  
GO
GRANT SELECT ON  [dbo].[vrvSMWorkOrder] TO [public]
GRANT INSERT ON  [dbo].[vrvSMWorkOrder] TO [public]
GRANT DELETE ON  [dbo].[vrvSMWorkOrder] TO [public]
GRANT UPDATE ON  [dbo].[vrvSMWorkOrder] TO [public]
GO
