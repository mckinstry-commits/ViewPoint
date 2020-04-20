SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[vrvSMInvoicesByInvoiceNumber]

/*==================================================================================        
  
Author:     
	Darin Howard   
  
Create date:     
	10/19/11      
  
Usage:  
	Selects one row per SM Invoice and Work Order summarizing InvoiceAmount, TaxAmount, Total, and Paid   
	From SM Work Completed.  Paid comes from receipts posted in AR.   
  
Things to keep in mind regarding this report and proc:   
	Report does a left outer join to work completed (WC) to related records, but there  
	may not be any due the ability to create invoices through the SM Agreement Billings  
	Due process. Where statement logic behind where statement is:  
		 if I am an invoice created from the Billings Due process then I may not have   
		 any work completed records associated with me so any fields coming from the  
		 SMWorkCompleted view will be null. At this point in time it has not been decided  
		 if an Agreement Billings Due invoice will have related work completed invoices or not  
		 but the isnull check is there just in case. We can determine where the record is  
		 coming from via the SMInvoiceType record. W = Work Complete, A = Agreement Billing  
		 If I do have a related work complete record then look that vaue as it will always  
		 be defined as 'Y' (yes do not charge this line) or 'N' (charge this line)  
	   
  
Related reports:     
	SM Invoice List report(ID#: 1190)        
  
Revision History        
	Date  Author   Issue      Description  
	10/20/11 Darin Howard CL-????? / V1-????? Added PaidInFull Status  
	10/21/11 Darin Howard CL-????? / V1-????? Added InvoiceAllWO  
	04/06/12 Scott Alvey  CL-????? / V1-B-03270 New ability to add invoices  
		from the Agreement Billings Due form means this view has to now know how to deal  
		with SMInvoice records that do not have related SM Work Completed records. Join   
		section was originally from SMWorkCompleted w with a join to SMInvoice i. Now it  
		starts from SMInvoice i and does a left outer to SMWorkCompleted w. I also modified  
		the where statement to take into consideration that there may or may not be a   
		non null value for w.NoCharge. See above where statement logic to get an idea  
		how it works.  
	04/25/12 Scott Alvey  CL-????? / V1-B-0777 Changes to how AR Invoices are initiated  
		Due to the fact that customers can now create invoices directly from a billing schedule  
		defined in the Agreement section this view needed to modified to pick up billing amounts  
		from this new area. Prior to this change the view looked purely to SMWorkCompleted for  
		billed dollar amounts to total up on their related common invoice. But now that   
		agreements can fire off invoices, invoices that probably will not have any underlying  
		work completed lines this view needs to some how pick up those agreement invoices and  
		their billing amounts. Keep in mind that since these records will not have related  
		work completed lines the only way the report will see these new agreement only lines  
		will be if the report is ran against the customer parameter. For this change I introduced  
		the final Outer Aplly section (aliased as InvoiceTotals) and then used them to build  
		the Amount, TaxAmount, and TotalAmount fields. I have left the original code in place   
		for reference. Finally the where statement had to have a check added to it to see if 
		the Agreement Invoice was voided or not. If the Invoice is work complete related then
		when an invoice is voided those work complete records are removed from its related view
		as well. This means for w.NoCharge in the where statement (the one that is not wrapped in
		an isnull statement) will return null and null <> 'N'. Same logic was replicated for
		Agreement Inovices. If the VoidedBy field from SMInvoice has a value that means the 
		Invoice has been voided. Null means it has not been voided. So we check for a value in 
		VoidedBy and if there is something we return 'V' meaning void. Otherwise we return 'A'
		(or something that is just not 'V') and then compare the returned value (V or A) to V.
		If the values IS NOT 'V' then it is not voided. No report side chagnes are necessary.
	08/22/12 Scott Alvey CL-????? / V1-D-08723 Billable amounts not being set to $0 on fully covered work
		Added SMWorkCompleted.Coverage is null to the InvoiceTotals OuterApply section. If a 
		coverage value exists then the dollars for that line should be ignored.
	09/14/12 Scott Alvey CL-????? / V1-D-05749 Report is missing data. The related SM Invoice List
		was not showing voided agreement invoices nor was it always showing the correct status of
		some of the invoices. Modified the view to look to SMInvoiceList (instead of SMInvoice) to
		get the status of the Invoice. The case statement just below is there to only trim 'Pending
		Invoice' as the space on the repor is only expecting a single word and not two. Also modified
		the view to look to SMWorkCompleted.Coverage <> 'C' instead of null as this was more 
		appropriate. Final, I commented out all of the where clause as it was preventing both Voided
		and WC records with No Charge flagged as yes. We want voided records to show and even though
		it seems pointless to create an invoice for no charge, it is doable and needs to be 
		supported by the report as well.
	12/19/12 Scott Alvey CL-147620 / V1-D-06357 Report is not filtering printed status properly. This
		was because the i.DeliveredDate as PrintedDate was not wrapped in an isnull. The report was not
		seeing this field properly because of this.

==================================================================================*/      
  
AS      
  
SELECT     
	i.SMCo    
	, i.Invoice    
	, i.Invoiced as [Status]    
	, (  
		case when i.InvoiceStatus = 'Pending Invoice'
				then 'Pending' 
				else i.InvoiceStatus  
		end  
	  ) as StatusDescription     
	, i.Customer as Customer    
	, ARCM.Name as CustomerName    
	, i.BillToARCustomer as BillToCustomer    
	, ARCMBillTo.Name as BillToCustomerName    
	, w.ServiceSite    
	, i.InvoiceDate    
	, isnull(i.ARPostedMth,'1/1/1950') as PostMonth    
	, isnull(i.DueDate,'1/1/1950') as DueDate    
	, isnull(i.DeliveredDate,'1/1/1950') as PrintedDate    
	, (  
		case when i.DeliveredDate is null    
			then 'Not Printed'    
			else 'Printed'    
		end   
	  ) as PrintedStatus    
	, w.WorkOrder           
	--, sum(w.PriceTotal) as Amount --Invoice amounts at the Work Order level.    
	--, sum(w.TaxAmount) as TaxAmount    
	--, sum(w.PriceTotal)+sum(isnull(w.TaxAmount,0)) as TotalAmount  
	, sum(ISNULL(InvoiceTotals.TotalBilled, 0)) Amount     
	, sum(ISNULL(InvoiceTotals.TotalTaxed, 0)) TaxAmount    
	, sum(ISNULL(InvoiceTotals.TotalBilled, 0) + ISNULL(InvoiceTotals.TotalTaxed, 0)) TotalAmount     
	, ARReceipts.Paid as PaidOnInvoice --Note:  Paid =receipts applied to entire invoice, not applied by work order    
	, SMInvoice.InvoicedAllWO --Total Invoice amount used when single Work Order selected for report.    
	, SMInvoice.TaxAllWO    
	, ARReceipts.PaidInFullYN  
FROM   
	SMInvoiceList i    
LEFT OUTER JOIN     
	SMWorkCompleted w WITH (NOLOCK) ON   
		w.SMInvoiceID = i.SMInvoiceID    
INNER JOIN    
	ARCM WITH (NOLOCK) ON    
		ARCM.CustGroup = i.CustGroup    
		AND ARCM.Customer = i.Customer    
INNER JOIN    
	ARCM ARCMBillTo WITH (NOLOCK) ON    
		ARCMBillTo.CustGroup = i.CustGroup    
		AND ARCMBillTo.Customer = i.BillToARCustomer     

OUTER APPLY --Get Total Invoiced amount for the SMInvoice.    
	(  
		SELECT   
			sum(
					CASE WHEN ISNULL(i.NoCharge,'N') = 'N' AND isnull(i.Coverage,'') <> 'C' 
						THEN i.PriceTotal 
						ELSE 0 
					END
				) as InvoicedAllWO  
			, sum(
					CASE WHEN ISNULL(i.NoCharge,'N') = 'N' AND isnull(i.Coverage,'') <> 'C'
						THEN i.TaxAmount 
						ELSE 0 
					END
				) as TaxAllWO    
		FROM   
			SMWorkCompleted i WITH (NOLOCK)    
		WHERE   
			i.SMCo = w.SMCo   
			and i.SMInvoiceID = w.SMInvoiceID  
	) SMInvoice    

OUTER APPLY  --get Paid from ARTH for the invoice.  ARPostedMth and ARTrans passed in from outer query to subquery    
	(  
		SELECT   
			sum(a.Paid) as Paid  
			, (  
				case when a.PayFullDate is not null   
					then 'Y'   
					else 'N'   
				end   
			  ) as PaidInFullYN    
		FROM   
			ARTH a    
		WHERE   
			a.ARCo = i.ARCo    
			AND a.Mth = i.ARPostedMth    
			AND a.ARTrans = i.ARTrans    
		Group by   
			a.PayFullDate  
	) ARReceipts   
OUTER APPLY  -- get Billed amounts for either work complete lines or from agreement generated invoices  
	(    
		SELECT    
			SUM(
					CASE WHEN ISNULL(SMWorkCompleted.NoCharge,'N') = 'N' AND isnull(SMWorkCompleted.Coverage,'') <> 'C' 
						THEN SMWorkCompleted.PriceTotal 
						ELSE 0 
					END
				) TotalBilled --0 AS TotalTaxed    
			, SUM(
					CASE WHEN ISNULL(SMWorkCompleted.NoCharge,'N') = 'N' AND isnull(SMWorkCompleted.Coverage,'') <> 'C' 
						THEN SMWorkCompleted.TaxAmount 
						ELSE 0 
					END
				 ) TotalTaxed    
		FROM   
			dbo.SMWorkCompleted    
		WHERE   
			SMWorkCompleted.SMWorkCompletedID = w.SMWorkCompletedID    
		HAVING   
			i.InvoiceType = 'W' --HAVING is required here because sums will always return at least 1 row unless using a having 
			   
		UNION ALL 
		   
		SELECT   
			BillingAmount  
			, TaxAmount 
		FROM   
			SMAgreementBillingSchedule    
		WHERE   
			i.InvoiceType = 'A'   
			AND SMAgreementBillingSchedule.SMInvoiceID = i.SMInvoiceID    
	) InvoiceTotals        

--WHERE w.NoCharge='N'  
--WHERE   
--	(  
--		case when i.InvoiceType = 'A'  
--			then isnull(w.NoCharge,'N')  
--			else w.NoCharge  
--		end  
--	) = 'N'    
--and (
--		case when i.VoidedBy is not null
--			then 'V'
--			else 'A'
--		end
--	) <> 'V'
GROUP BY    
	i.SMCo    
	, i.Invoice
	, i.Invoiced
	, i.InvoiceStatus 
	, i.Customer     
	, ARCM.Name     
	, i.BillToARCustomer     
	, ARCMBillTo.Name     
	, w.ServiceSite    
	, i.InvoiceDate    
	, i.ARPostedMth    
	, i.DueDate    
	, i.DeliveredDate    
	, ARReceipts.Paid    
	, w.WorkOrder    
	, ARReceipts.PaidInFullYN    
	, SMInvoice.InvoicedAllWO     
	, SMInvoice.TaxAllWO    
	, w.NoCharge  
GO
GRANT SELECT ON  [dbo].[vrvSMInvoicesByInvoiceNumber] TO [public]
GRANT INSERT ON  [dbo].[vrvSMInvoicesByInvoiceNumber] TO [public]
GRANT DELETE ON  [dbo].[vrvSMInvoicesByInvoiceNumber] TO [public]
GRANT UPDATE ON  [dbo].[vrvSMInvoicesByInvoiceNumber] TO [public]
GO
