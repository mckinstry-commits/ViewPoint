SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
        
Create Procedure [dbo].[vrptSMWorkOrderBillingInvoice]         
(            
	@SMDeliveryReportID bigint    
)         
              
/*=================================================================================                      
                
Author:                   
Scott Alvey                           
                
Create date:                   
06/11/2013             
                
Usage:   
This proc was created after a forced refactor of the SM Invoice Report due to the
addition of Flat Price to SM. Rather than try to make the report even more complicated
I decided it was best to move the logic into a proc. This was done for the 6.7 release.
This proc currently just drives the SM Invoice Report.
                
Things to keep in mind regarding this report and proc:
The biggest this to keep in mind here is that Flat Price (FP) a way different then TM. 
First off while there can be Work Completed (WC) records against an FP scope, they are 
not recorded in the Invoice process. Secondly, the types of dollars (Labor, Equip, etc...) 
are different between FP and WC. So this makes merging them together a bit rough...

To deal with the CTE was introduced to help break out the various dollar types. If you want 
to get scope level dollar amounts, then use the columns from the CTE. If you want to get WC 
level details then use the WorkCompletedPriceTotal column. Since FP does not have any reportable
WC lines, I am treating the WorkCompletedPriceTotal, for FP scopes only, like a single WC line.  
It merges all the various FP types into the column. This column basically says 'if I am 
WC record then my value represents the dollars associated with my line type. Otherwise, 
assuming FP, I am a sum of all the FP types'

Finally, regarding Scopes that are flagged and Non-Billable (Pricing method = 'N'). 
The billing system should automatically omit these, meaning the proc should not even 
see them. But for some reason if the proc does there is a case statement on WorkCompletedNoCharge 
to catch this. If the pricing method = 'N' then override the NoCharge column and make it equal 
to Y, meaning 'Yes there is no charge for this'

    
Parameters: 
@SMDeliveryReportID - key id of the invoice group being processed             
                
Related reports:   
SM Invoice (Rpt ID: 1118)  
             
Revision History                      
Date  Author   Issue      Description    

11/15/13	DKS	TFS-67140	Porting changes made in 6.8 back to 6.7 to fix a customer complaint
								of blank invoice reports            
              
==================================================================================*/       

AS

with CTE_InvoiceTotalsByLineType as
(
	select
		s.SMCo
		, s.WorkOrder
		, s.Scope
		, s.PriceMethod
		, c.Type as WCType
		, null as FPType
		, c.Date
		, c.TaxAmount
		, c.NoCharge
		, c.WorkCompleted
		, c.SMCostType
		, c.PriceTotal as BillableTotal
		, c.PriceRate
		, c.PriceTotal
		, c.Quantity
		, c.CostQuantity
		, c.Description
		, c.UM
		, c.PriceUM
		, c.PONumber
		, i.Invoice
	from
		SMWorkOrderScope s
	inner join
		SMWorkCompleted c on
			s.SMCo = c.SMCo
			and s.WorkOrder = c.WorkOrder
			and s.Scope = c.Scope
			and c.IsSession = 0
	inner join
		SMInvoiceDetail i on
			c.SMCo = i.SMCo
			and c.WorkOrder = i.WorkOrder
			and c.WorkCompleted = i.WorkCompleted			

	union all

	select
		s.SMCo
		, s.WorkOrder
		, s.Scope
		, s.PriceMethod
		, null as WCType
		, f.CostTypeCategory as FPType
		, null as Date
		, l.TaxAmount as TaxAmount
		, 'N' as NoCharge
		, 0 as WorkCompleted
		, f.CostType as SMCostType
		, f.Amount as BillableTotal
		, 0 as PriceRate
		, l.Amount as PriceTotal
		, 0 as Quantity
		, 0 as CostQuantity
		, null as Description
		, null as UM
		, null as PriceUM
		, null as PONumber
		, l.Invoice as Invoice
	from
		SMWorkOrderScope s
	join
		SMInvoiceDetail d on
			s.SMCo = d.SMCo
			and s.WorkOrder = d.WorkOrder
			and s.Scope = d.Scope
	join
		SMInvoiceLine l on 
			d.SMCo = l.SMCo 
			and d.Invoice = l.Invoice 
			and d.InvoiceDetail = l.InvoiceDetail 
	join
		SMEntity e on
			s.SMCo = e.SMCo
			and s.WorkOrder = e.WorkOrder
			and s.Scope = e.WorkOrderScope
	join
		SMFlatPriceRevenueSplit f on
			e.SMCo = f.SMCo
			and e.EntitySeq = f.EntitySeq
			and l.InvoiceDetailSeq = f.Seq			
	where 
		s.PriceMethod = 'F'
),

CTE_SMInvoiceListDetailWithScope as
(
	select
		d.SMInvoiceID
		, d.SMCo
		, d.WorkOrder
		, isnull(d.Scope, c.Scope) as Scope
		, isnull(d.WorkCompleted, c.WorkCompleted) as WorkCompleted
		, d.Invoice
	from	
		SMInvoiceListDetail d
	left outer join
		SMWorkCompleted c on
			d.SMCo = c.SMCo
			and d.WorkOrder = c.WorkOrder
			and d.WorkCompleted = c.WorkCompleted
)

select 

	--Invoice Information
	smil.SMCo
	, smil.Invoice
	, smil.InvoiceNumber
	, smil.InvoiceDate
	, smil.DueDate as InvoiceDueDate
	, smil.DiscDate as InvoiceDiscDate
	, smil.DiscRate as InvoiceDiscRate
	, smil.DescriptionOfWork as InvoiceDescriptionofWork
	, smil.InvoiceSummaryLevel
	, smil.BillAddress as InvoiceBillAddress
	, smil.BillAddress2 as InvoiceBillAddress2
	, smil.BillCity as InvoiceBillCity
	, smil.BillState as InvoiceBillState
	, smil.BillZip as InvoiceBillZip
	, smil.SMInvoiceID as InvoiceID

	--Work Order Information
	, smwo.WorkOrder
	, smwo.Description as WorkOrderDescription

	--Work Order Scope Information
	, smwos.Scope as WorkOrderScope
	, smwos.CustomerPO as WorkOrderScopeCustPO
	, smwos.PriceMethod as WorkOrderScopePriceMethod

	--Work Completed Information
	, smwc.WCType as WorkCompletedType
	, smwc.FPType as FlatPriceType
	, smwc.Date as WorkCompletedDate
	, smwc.TaxAmount as WorkCompletedTaxAmt
	, case when smwos.PriceMethod = 'N'
		then 'Y'
		else smwc.NoCharge 
	  end as WorkCompletedNoCharge
	, smwc.WorkCompleted as WorkCompleted
	, smwc.SMCostType as WorkCompletedSMCostType
	, smwc.PriceRate as WorkCompletedPriceRate
	, smwc.PriceTotal as WorkCompletedPriceTotal
	, smwc.Quantity as WorkCompletedQuantity
	, smwc.CostQuantity as WorkCompletedCostQuantity
	, smwc.Description as WorkCompletedDescription
	, smwc.UM as WorkCompletedUM
	, smwc.PriceUM as WorkCompletedPriceUM
	, smwc.PONumber as WorkCompletedPONumber

	--Customer Information
	, bill.Name as BillingName
	, cust.Name as CustomerName
	, cust.Address as CustomerAddress
	, cust.Address2 as CustomerAddress2
	, cust.City as CustomerCity
	, cust.State as CustomerState
	, cust.Zip as CustomerZip

	--Discount Information
	, arco.DiscTax

	--Payterm Information
	, hqpt.Description as PayTermDescription

	--SM Cost Type Information
	, smct.Description as CostTypeDescription
	
	--Service Center Information
	, smsc.Description as ServiceCenterDescription
	, smsc.Address as ServiceCenterAddress
	, smsc.Address2 as ServiceCenterAddress2
	, smsc.City as ServiceCenterCity
	, smsc.State as ServiceCenterState
	, smsc.Zip as ServiceCenterZip

	--Service Site Information
	, smss.Description as ServiceSiteDescription
	, smss.Address1 as ServiceSiteAddress
	, smss.Address2 as ServiceSiteAddress2
	, smss.City as ServiceSiteCity
	, smss.State as ServiceSiteState
	, smss.Zip as ServiceSiteZip

from
	SMDeliveryGroupInvoice smdgi
inner join
	SMInvoiceList smil on
		smdgi.SMInvoiceID = smil.SMInvoiceID
inner join
	CTE_SMInvoiceListDetailWithScope smild on
		smil.SMInvoiceID = smild.SMInvoiceID
inner join
	SMWorkOrder smwo on
		smild.SMCo = smwo.SMCo
		and smild.WorkOrder = smwo.WorkOrder
inner join
	ARCO arco on
		smil.ARCo = arco.ARCo
inner join
	ARCM cust on
		smil.CustGroup = cust.CustGroup
		and smil.Customer = cust.Customer
inner join
	ARCM bill on
		smil.BillToCustGroup = bill.CustGroup
		and smil.BillToARCustomer = bill.Customer
inner join
	SMServiceCenter smsc on
		smwo.SMCo = smsc.SMCo
		and smwo.ServiceCenter = smsc.ServiceCenter
inner join
	SMServiceSite smss on
		smwo.SMCo = smss.SMCo
		and smwo.ServiceSite = smss.ServiceSite
left outer join
	HQPT hqpt on
		smil.PayTerms = hqpt.PayTerms
outer apply
(
	select
		c.*
	from
		CTE_InvoiceTotalsByLineType c
	where
		smild.SMCo = c.SMCo
		and smild.WorkOrder = c.WorkOrder
		and smild.Scope = c.Scope
		and isnull(smild.WorkCompleted,0) = c.WorkCompleted
		and smild.Invoice = c.Invoice
) smwc
left outer join
	SMWorkOrderScope smwos on
		smild.SMCo = smwos.SMCo
		and smild.WorkOrder = smwos.WorkOrder
		and isnull(smild.Scope, smwc.Scope) = smwos.Scope
left outer join
	SMCostType smct on
		smwc.SMCo = smct.SMCo
		and smwc.SMCostType = smct.SMCostType
where
	smdgi.SMDeliveryReportID = @SMDeliveryReportID
GO
GRANT EXECUTE ON  [dbo].[vrptSMWorkOrderBillingInvoice] TO [public]
GO
