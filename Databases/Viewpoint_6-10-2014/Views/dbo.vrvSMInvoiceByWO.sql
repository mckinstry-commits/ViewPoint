SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
CREATE VIEW [dbo].[vrvSMInvoiceByWO]  
  

/***********************************************************************      
Author:   
Darin Howard  
     
Create date:   
10/17/2011    
      
Usage:  
View selects AR invoices related to SM Work Orders. Returns one line per SMCo, WorkOrder,   
Invoice, and InvoiceDate. PaymentStatus column can either be Open, Paid in Full or Partially Paid  
  
Parameters:    
N/A  
  
Related reports:   
SM Work Order List (ID#: 1187)      
      
Revision History      
Date  Author  Issue     Description  
3/8/2012 ScottAlvey CL-146033 / V1-D-04463: Customers have the ability to create   
work complete lines that do have a billable dollar amount but are flagged as no charge.   
SM Profit reports do not know if a line is no charge or not and includes the billable dollar   
amount as truly billed, incorrectly inflating billed dollar values. This view needs to be   
modified to be able know the difference between a no-charge line and chargeable line.  
All fields modified/added for this issue are marked with the CL number. 

04/12/2012	ScottAlvey	CL-????? / V1-B-08702: SM - Edit Taxes on SM Invoice
All the AR fields were removed from SMWorkCompleted and put into SMWorkCompletedARTL
This view originally just joined SMWorkCompleted to ARTH via those fields but now
has to join in SMWorkCompletedARTL to get them, and then from that view join
in ARTH. Added the join to the SMWorkCompletedARTL view and then chagned
the ARTH linking to link to that view instead of SMWorkCompleted

04/25/2013	JVH	TFS-44860: SM - Edit Taxes on SM Invoice
The vSMWorkCompletedARTL is going to be dropped so any refrences to it were replaced
with SMInvoiceListDetail

06/04/2013 ScottAlvey TFS-44858 - Change AR Batch creation and posting for SM Invoices
SMInvoiceID has been removed from use and since the related report does not use the field
for any purpose, it is just being removed from this view.

06/25/2013 DanK		TFS-53373: SM Work Order list modify report to pick up FP lines
Complete overhaul to use SMInvoice tables. These tables did not exist at the 
initial creation time of the report. They more simply facilitate aggregation of the 
invoices and their related amounts. 
***********************************************************************/       
    
AS    

SELECT		DL.SMCo						AS 'SMCo', 
			DL.WorkOrder				AS 'WorkOrder',
			DL.InvoiceNumber			AS 'Invoice',
			MAX(DL.InvoiceDate)			AS 'InvoiceDate',
			MAX(DL.CustGroup)			AS 'CustGroup', 
			MAX(DL.Customer)			AS 'Customer', 
			MAX(ARCM.Name)				AS 'CustomerName',
			SUM(CASE
					WHEN NoCharge = 'N'
						THEN DL.Amount
					ELSE 0
				END )					AS 'InvoiceAmount',
			MAX(DL.NoCharge)			AS 'NoChargeFlag', 
			CASE 
				WHEN MAX(L.InvoiceStatus) <> 'Voided'
					THEN	CASE     
								WHEN MAX(ARPayment.ApplyTrans) IS NULL 
									THEN	'Open'    
								WHEN MAX(ARPayment.PayFullDate) IS NOT NULL 
									THEN	'Paid in Full'    
									 ELSE	'Partially Paid'    
							END							
					ELSE	'Voided'
			END							AS 'PaymentStatus'
FROM		SMInvoiceListDetailLine DL

LEFT JOIN	SMInvoiceList L
		ON	L.SMCo = DL.SMCo
		AND L.Invoice = DL.Invoice

INNER JOIN	ARTH
		ON	ARTH.ARCo			= DL.ARCo 
		AND	ARTH.Mth			= DL.ARMth
		AND ARTH.ARTrans		= DL.ARTrans

LEFT JOIN	ARCM
		ON	ARCM.CustGroup		= DL.CustGroup
		AND ARCM.Customer		= DL.Customer

LEFT OUTER JOIN    
	(
		SELECT  
			l.ARCo
			, l.ApplyMth
			, l.ApplyTrans
			, max(h.PayFullDate) as PayFullDate    
		FROM 
			ARTL l    
		INNER JOIN    
			ARTH h ON  
				h.ARCo = l.ARCo    
				AND h.Mth = l.Mth    
				AND h.ARTrans = l.ARTrans    
		GROUP BY     
			l.ARCo,    
			l.ApplyMth,    
			l.ApplyTrans    
	) ARPayment ON  
		ARPayment.ARCo = ARTH.ARCo    
		AND ARPayment.ApplyMth = ARTH.Mth    
		AND ARPayment.ApplyTrans = ARTH.ARTrans

GROUP BY	DL.SMCo, 
			DL.WorkOrder, 
			DL.InvoiceNumber      
GO
GRANT SELECT ON  [dbo].[vrvSMInvoiceByWO] TO [public]
GRANT INSERT ON  [dbo].[vrvSMInvoiceByWO] TO [public]
GRANT DELETE ON  [dbo].[vrvSMInvoiceByWO] TO [public]
GRANT UPDATE ON  [dbo].[vrvSMInvoiceByWO] TO [public]
GRANT SELECT ON  [dbo].[vrvSMInvoiceByWO] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvSMInvoiceByWO] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvSMInvoiceByWO] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvSMInvoiceByWO] TO [Viewpoint]
GO
