SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
create VIEW [dbo].[vrvSMInvoiceByWO]  
  

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
***********************************************************************/       
    
AS    
    
SELECT    
 SMWorkCompleted.SMCo
 , SMWorkCompleted.WorkOrder
 , ARTH.Invoice
 , SMWorkCompleted.SMInvoiceID
 , ARTH.TransDate as InvoiceDate
 , MAX(ARTH.CustGroup) as CustGroup
 , MAX(ARTH.Customer) as Customer
 , MAX(ARCM.Name) as CustomerName 
--start 146033 mod  
	--SUM(SMWorkCompleted.PriceTotal) as InvoiceAmount,    
 , SUM
	(
		(
			case when NoCharge = 'N' 
				then 
					SMWorkCompleted.PriceTotal 
				else 
					0 
			end
		)
	) as InvoiceAmount --added no charge check  
 , MAX(SMWorkCompleted.NoCharge) as NoChargeFlag --new field for 146033  
--end 146033 mod  
 , (
	CASE     
		WHEN MAX(ARPayment.ApplyTrans) is null 
			THEN 
				'Open'    
		WHEN MAX(ARPayment.PayFullDate) is not null 
			THEN 
				'Paid in Full'    
			 ELSE 
				'Partially Paid'    
	END
   ) as PaymentStatus        
FROM 
	SMWorkCompleted
INNER JOIN
	SMWorkCompletedARTL on
		SMWorkCompleted.SMWorkCompletedARTLID = SMWorkCompletedARTL.SMWorkCompletedARTLID   
INNER JOIN    
	ARTH ON 
		ARTH.ARCo = SMWorkCompletedARTL.ARCo    
		AND ARTH.Mth = SMWorkCompletedARTL.Mth    
		AND ARTH.ARTrans = SMWorkCompletedARTL.ARTrans      
INNER JOIN    
	ARCM ON  
		ARCM.CustGroup = ARTH.CustGroup    
		AND ARCM.Customer = ARTH.Customer
--Derived table selecting payments applied to AR Invoices    
--ApplyTrans, ApplyLine, etc. for payments will contain the same    
--transaction numbers as the invoice to which it is applied       
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
GROUP BY     
	SMWorkCompleted.SMCo
	, SMWorkCompleted.WorkOrder
	, SMWorkCompleted.SMInvoiceID
	, ARTH.Invoice
	, ARTH.TransDate      
           
GO
GRANT SELECT ON  [dbo].[vrvSMInvoiceByWO] TO [public]
GRANT INSERT ON  [dbo].[vrvSMInvoiceByWO] TO [public]
GRANT DELETE ON  [dbo].[vrvSMInvoiceByWO] TO [public]
GRANT UPDATE ON  [dbo].[vrvSMInvoiceByWO] TO [public]
GO
