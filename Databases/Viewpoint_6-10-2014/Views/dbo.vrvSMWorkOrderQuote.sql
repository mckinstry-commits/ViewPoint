SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*==================================================================================          
    
Author:       
Scott Alvey    
    
Create date:       
05/20/2013  
    
Usage:
Drives the SM Work Order Quote report. 
    
Things to keep in mind:
Nothing much really. Adding to the union will be a pain, just ask Puerto Rico. 
All the SMRequired views have a Seq column, except for Required Tasks, which uses
the Tasks column as Seq. 
    
Related reports: 
   
Revision History          
Date  Author   Issue      Description
  
==================================================================================*/ 

CREATE view [dbo].[vrvSMWorkOrderQuote] as

WITH

/*=================================================================================                      
CTE:
CTE_SMRequired
                     
Usage:
This just unions all the SM Required views together, gets the necessary fields,
and keeps the column titles unique.
         
==================================================================================*/ 

CTE_SMRequired

AS

(
	SELECT --Labor
		2 as SortOrder, 
		r.SMCo as SMRequiredSMCo,
		r.EntitySeq,
		isnull(r.Seq,0) as Seq,

		--Labor
		r.Craft,
		cm.Description as CraftDescription,
		r.Class,
		cc.Description as ClassDescription,
		r.Qty as LaborQty,
		r.CostRate as LaborCostRate,
		r.Notes as LaborNotes,

		--Equipment
		null as EMCo,
		null as Category,
		null as CategoryDescription,
		null as EquipQty,
		null as RevCode,
		null as RevCodeDescription,
		null as TimeUM,
		null as RevQty,
		null as EquipCostRate,
		null as EquipNotes,

		--Misc
		null as StandardItem,
		null as MiscDescription,
		null as SMCostType,
		null as SMCostTypeDescription,
		null as MiscQty,
		null as MiscCostRate,
		null as MiscCostTotal,
		null as MiscNotes,

		--Material
		null as SMPartType,
		null as PartTypeDescription,
		null as Material,
		null as MaterialDescription,
		null as MatlQty,
		null as UM,
		null as CostECM,
		null as MatlCostRate,
		null as MatlCostTotal,
		null as MatlNotes,

		--Tasks
		null as SMStandardTask,
		null as StandardTaskDescription,
		null as Name,
		null as TaskDescription,
		null as ServiceItem,
		null as ServiceItemDescription,
		null as ItemClass,
		null as ItemType,
		null as Manufacturer,
		null as Model,
		null as SerialNumber,
		null as TaskNotes
	FROM
		SMRequiredLabor r
	LEFT OUTER JOIN
		PRCM cm ON
			r.PRCo = cm.PRCo
			AND r.Craft = cm.Craft
	LEFT OUTER JOIN
		PRCC cc ON
			r.PRCo = cc.PRCo
			AND r.Craft = cc.Craft
			AND r.Class = cc.Class

	UNION ALL

	SELECT --Equipment
		1 as SortOrder,
		r.SMCo as SMRequiredSMCo,
		r.EntitySeq,
		isnull(r.Seq,0) as Seq,

		--Labor
		null as Craft,
		null as CraftDescription,
		null as Class,
		null as ClassDescription,
		null as LaborQty,
		null as LaborCostRate,
		null as LaborNotes,

		--Equipment
		r.EMCo,
		r.Category,
		c.Description as CategoryDescription,
		r.EquipQty,
		r.RevCode,
		rc.Description as RevCodeDescription,
		rc.TimeUM,
		r.RevQty,
		r.CostRate as EquipCostRate,
		r.Notes as EquipNotes,

		--Misc
		null as StandardItem,
		null as MiscDescription,
		null as SMCostType,
		null as CostTypeDescription,
		null as MiscQty,
		null as MiscCostRate,
		null as MiscCostTotal,
		null as MiscNotes,

		--Material
		null as SMPartType,
		null as PartTypeDescription,
		null as Material,
		null as MaterialDescription,
		null as MatlQty,
		null as UM,
		null as CostECM,
		null as MatlCostRate,
		null as MatlCostTotal,
		null as MatlNotes,

		--Tasks
		null as SMStandardTask,
		null as StandardTaskDescription,
		null as Name,
		null as TaskDescription,
		null as ServiceItem,
		null as ServiceItemDescription,
		null as ItemClass,
		null as ItemType,
		null as Manufacturer,
		null as Model,
		null as SerialNumber,
		null as TaskNotes
	FROM
		SMRequiredEquipment	r
	JOIN
		EMCM c on
			r.EMCo = c.EMCo
			AND r.Category = c.Category		
	JOIN
		EMRC rc on
			r.EMGroup = rc.EMGroup
			AND r.RevCode = rc.RevCode	

	UNION ALL

	SELECT --Misc
		3 as SortOrder,
		r.SMCo as SMRequiredSMCo,
		r.EntitySeq,
		isnull(r.Seq,0) as Seq,

		--Labor
		null as Craft,
		null as CraftDescription,
		null as Class,
		null as ClassDescription,
		null as LaborQty,
		null as LaborCostRate,
		null as LaborNotes,

		--Equipment
		null as EMCo,
		null as Category,
		null as CategoryDescription,
		null as EquipQty,
		null as RevCode,
		null as RevCodeDescription,
		null as TimeUM,
		null as RevQty,
		null as EquipCostRate,
		null as EquipNotes,

		--Misc
		r.StandardItem,
		r.Description as MiscDescription,
		r.SMCostType,
		c.Description as CostTypeDescription,
		r.Quantity as MiscQty,
		r.CostRate as MiscCostRate,
		r.CostTotal as MiscCostTotal,
		r.Notes as MiscNotes,

		--Material
		null as SMPartType,
		null as PartTypeDescription,
		null as Material,
		null as MaterialDescription,
		null as MatlQty,
		null as UM,
		null as CostECM,
		null as MatlCostRate,
		null as MatlCostTotal,
		null as MatlNotes,

		--Tasks
		null as SMStandardTask,
		null as StandardTaskDescription,
		null as Name,
		null as TaskDescription,
		null as ServiceItem,
		null as ServiceItemDescription,
		null as ItemClass,
		null as ItemType,
		null as Manufacturer,
		null as Model,
		null as SerialNumber,
		null as TaskNotes
	FROM
		SMRequiredMisc	r
	LEFT OUTER JOIN
		SMCostType c ON
			r.SMCo = c.SMCo
			AND r.SMCostType = c.SMCostType

	UNION ALL

	SELECT --Material
		4 as SortOrder,
		r.SMCo as SMRequiredSMCo,
		r.EntitySeq,
		isnull(r.Seq,0) as Seq,

		--Labor
		null as Craft,
		null as CraftDescription,
		null as Class,
		null as ClassDescription,
		null as LaborQty,
		null as LaborCostRate,
		null as LaborNotes,

		--Equipment
		null as EMCo,
		null as Category,
		null as CategoryDescription,
		null as EquipQty,
		null as RevCode,
		null as RevCodeDescription,
		null as TimeUM,
		null as RevQty,
		null as EquipCostRate,
		null as EquipNotes,

		--Misc
		null as StandardItem,
		null as MiscDescription,
		null as SMCostType,
		null as SMCostTypeDescription,
		null as MiscQty,
		null as MiscCostRate,
		null as MiscCostTotal,
		null as MiscNotes,

		--Material
		r.SMPartType,
		p.Description as PartTypeDescription,
		r.Material,
		m.Description as MaterialDescription,
		r.MatlQty,
		r.UM,
		r.CostECM,
		r.CostRate as MatlCostRate,
		r.CostTotal as MatlCostTotal,
		r.Notes as MatlNotes,

		--Tasks
		null as SMStandardTask,
		null as StandardTaskDescription,
		null as Name,
		null as TaskDescription,
		null as ServiceItem,
		null as ServiceItemDescription,
		null as ItemClass,
		null as ItemType,
		null as Manufacturer,
		null as Model,
		null as SerialNumber,
		null as TaskNotes
	FROM
		SMRequiredMaterial	r
	JOIN
		HQMT m ON
			r.MatlGroup = m.MatlGroup
			AND r.Material = m.Material
	LEFT OUTER JOIN
		SMPartType p ON
			r.SMCo = p.SMCo
			AND r.SMPartType = p.SMPartType

	UNION ALL

	SELECT --Tasks
		5 as SortOrder,
		r.SMCo as SMRequiredSMCo,
		r.EntitySeq,
		isnull(r.Task,0) as Seq,

		--Labor
		null as Craft,
		null as CraftDescription,
		null as Class,
		null as ClassDescription,
		null as LaborQty,
		null as LaborCostRate,
		null as LaborNotes,

		--Equipment
		null as EMCo,
		null as Category,
		null as CategoryDescription,
		null as EquipQty,
		null as RevCode,
		null as RevCodeDescription,
		null as TimeUM,
		null as RevQty,
		null as CostRate,
		null as EquipNotes,

		--Misc
		null as StandardItem,
		null as MiscDescription,
		null as SMCostType,
		null as SMCostTypeDescription,
		null as MiscQty,
		null as CostRate,
		null as CostTotal,
		null as MiscNotes,

		--Material
		null as SMPartType,
		null as PartTypeDescription,
		null as Material,
		null as MaterialDescription,
		null as MatlQty,
		null as UM,
		null as CostECM,
		null as CostRate,
		null as CostTotal,
		null as MatlNotes,

		--Tasks
		r.SMStandardTask,
		s.Description as StandardTaskDescription,
		r.Name,
		r.Description as TaskDescription,
		r.ServiceItem,
		r.Description as ServiceItemDescription,
		r.Class as ItemClass,
		r.Type as ItemType,
		r.Manufacturer,
		r.Model,
		r.SerialNumber,
		r.Notes as TaskNotes
	FROM
		SMRequiredTasks	r
	LEFT OUTER JOIN
		SMStandardTask s ON
			r.SMCo = s.SMCo
			AND r.SMStandardTask = s.SMStandardTask
	LEFT OUTER JOIN
		SMServiceItems i ON
			r.SMCo = i.SMCo
			AND r.ServiceSite = i.ServiceSite
			AND r.ServiceItem = i.ServiceItem
)

/*=================================================================================                      
Final Select
                     
Things to keep in mind: 
Entity Seq from SMEntity is key here, it is used to link up all the SM Required views
(coming from the CTE and its related unions)

==================================================================================*/ 

SELECT 
	--Quote Header Info
	woq.SMCo,
	woq.WorkOrderQuote,
	woq.Description as QuoteDescription,
	woq.RequestedBy,
	woq.RequestedPhone,
	woq.RequestedDate,
	woq.Status as QuoteStatus,
	woq.DateApproved,
	woq.DateCanceled,
	woq.Notes as WorkOrderQuoteNotes,
	woq.UniqueAttchID as WorkOrderQuoteUniqueAttchID,
	

	--Quote Scope Info
	woqs.WorkOrderQuoteScope,
	sme.EntitySeq as WorkOrderQuoteScopeEntitySeq,
	woqs.WorkScope as WorkOrderQuoteWorkScope,
	sco.Description as WorkScopeDescription,
	woqs.Description as WorkOrderQuoteScopeDescription,
	woqs.PriceMethod as WorkOrderQuoteScopePriceMethod,
	woqs.Price as WorkOrderQuoteScopePrice,
	woqs.TaxRate as WorkOrderQuoteScopeTaxRate,
	GetTaxableAmount.TaxableAmount as WorkOrderQuoteScopeTaxableAmout,
	woqs.NotToExceed as WorkOrderQuoteScopeNotToExceed,
	woqs.CustomerPO as WorkOrderQuoteScopeCustomerPO,
	woqs.Notes as WorkOrderQuoteScopeNotes,
	woqs.UniqueAttchID as WorkOrderQuoteScopeUniqueAttchID,

	--Customer Info
	woq.CustGroup,
	woq.Customer,
	isnull(woq.CustomerName, cust.Name) as CustomerName,
	isnull(woq.CustomerAddress1, cust.Address) as CustomerAddress1,
	isnull(woq.CustomerAddress2, cust.Address2) as CustomerAddress2,
	isnull(woq.CustomerCity, cust.City) as CustomerCity,
	isnull(woq.CustomerState, cust.State) as CustomerState,
	isnull(woq.CustomerZip, cust.Zip) as CustomerZip,
	isnull(woq.CustomerCountry, cust.Country) as CustomerCountry,
	woq.CustomerContactName,
	woq.CustomerContactPhone,

	--Service Site Info
	woq.ServiceSite,
	isnull(woq.ServiceSiteDescription, serv.Description) as ServiceSiteDescription,
	isnull(woq.ServiceSiteAddress1, serv.Address1) as ServiceSiteAddress1,
	isnull(woq.ServiceSiteAddress2, serv.Address2) as ServiceSiteAddress2,
	isnull(woq.ServiceSiteCity, serv.City) as ServiceSiteCity,
	isnull(woq.ServiceSiteState, serv.State) as ServiceSiteState,
	isnull(woq.ServiceSiteZip, serv.Zip) as ServiceSiteZip,
	isnull(woq.ServiceSiteCountry, serv.Country) as ServiceSiteCountry,

	--Service Center Info
	woq.ServiceCenter,
	cent.Description as ServiceCenterDescription,
	cent.Address as ServiceCenterAddress,
	cent.Address2 as ServiceCenterAddress2,
	cent.City as ServiceCenterCity,
	cent.State as ServiceCenterState,
	cent.Zip as ServiceCenterZip,
	cent.Country as ServiceCenterCountry,

	--Related SMRequired tabs
	r.*
FROM
	SMWorkOrderQuoteExt woq
INNER JOIN
	SMWorkOrderQuoteScope woqs ON
		woq.SMCo = woqs.SMCo
		AND woq.WorkOrderQuote = woqs.WorkOrderQuote
INNER JOIN
	SMEntity sme ON
		woqs.SMCo = sme.SMCo
		AND woqs.WorkOrderQuote = sme.WorkOrderQuote
		AND woqs.WorkOrderQuoteScope = sme.WorkOrderQuoteScope
LEFT OUTER JOIN
	SMServiceCenter cent ON
		woq.SMCo = cent.SMCo
		AND woq.ServiceCenter = cent.ServiceCenter
LEFT OUTER JOIN
	CTE_SMRequired r ON
		sme.SMCo = r.SMRequiredSMCo
		AND sme.EntitySeq = r.EntitySeq
LEFT OUTER JOIN
	SMWorkScope sco ON
		woqs.SMCo = sco.SMCo
		AND woqs.WorkScope = sco.WorkScope
LEFT OUTER JOIN
	ARCM cust ON
		woq.CustGroup = cust.CustGroup
		AND woq.Customer = cust.Customer
LEFT OUTER JOIN
	SMServiceSite serv ON
		woq.SMCo = serv.SMCo
		AND woq.ServiceSite = serv.ServiceSite
OUTER APPLY
(
	SELECT 
		SUM(SMFlatPriceRevenueSplit.Amount) TaxableAmount
	FROM 
		SMFlatPriceRevenueSplit
	WHERE 
		sme.SMCo = SMFlatPriceRevenueSplit.SMCo 
		AND sme.EntitySeq = SMFlatPriceRevenueSplit.EntitySeq
		AND SMFlatPriceRevenueSplit.Taxable = 'Y' 
) GetTaxableAmount
GO
GRANT SELECT ON  [dbo].[vrvSMWorkOrderQuote] TO [public]
GRANT INSERT ON  [dbo].[vrvSMWorkOrderQuote] TO [public]
GRANT DELETE ON  [dbo].[vrvSMWorkOrderQuote] TO [public]
GRANT UPDATE ON  [dbo].[vrvSMWorkOrderQuote] TO [public]
GRANT SELECT ON  [dbo].[vrvSMWorkOrderQuote] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvSMWorkOrderQuote] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvSMWorkOrderQuote] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvSMWorkOrderQuote] TO [Viewpoint]
GO
