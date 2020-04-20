SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
        
Create Procedure [dbo].[vrptSMAgreementBillingInvoice]         
(            
	@SMDeliveryReportID bigint    
)         
              
/*=================================================================================                      
                
Author:                   
Scott Alvey                           
                
Create date:                   
06/27/2012                  
                
Usage:   
This proc is being used to drive the related SM Agreement Periodic Billing report.
The report itself will be called from a form instead of typical report launcher so
we just need the SMDeliveryReportID, the key ID for the goruping of invoices.

Fun time coming up with view alias names!     
                
Things to keep in mind regarding this report and proc:
So there are really two key things to keep in mind when coding for agreement billing:
1 - Each agreement has its own billing schedule (when do I send bills and for how much)
2 - Service in an agreement, when flagged as periodic, can have their own separate billing
	schedule from the parent agreement
3 - The logic to determine was bills are previous and what have yet to be billed based on the
	invoice date of the bill we are looking at is:
		Previous - is all invoices with an Invoiced Date less than the Invoiced Date of a given
			Invoice (the Invoice Date of the Invoice(s) related to the @SMDeliveryReportID value)
		Future - (remaining to be billed) is all scheduled invoices that do not have an
			SMInvoiceID value (that value is given once the invoice is actually invoiced)
This means that a scheduled bill could either be for multiple services or for a single service.
We can see what the bill is for in SMAgreementBillingScheduleExt.Service. If it is null then we
know this bill is for multiple services, otherwise, it is for a single service. I did not
want to create a report with subreports, hiding and showing based on this Service field so I 
introduced the first CTE to deal with the scenario (please find notes regarding that CTE in 
the CTE itself). 

So the final select does the bulk of the work. It gets the Invoice Header
items like Customer and Service provider info, Invoice info like invoiced date, amount, billing
X of Y value, due date, and other related things. The first CTE you see gets the service details
so we can show the paying customer just what services we are billing for. 

Each section of code below will have more specific details about what each one does.
    
Parameters: 
@SMDeliveryReportID - key id of the invoice group being processed             
                
Related reports:   
SM Agreement Billing (Rpt ID: 1222)  
             
Revision History                      
Date  Author   Issue      Description                
              
==================================================================================*/                   
              
AS

WITH

/*=================================================================================                      
CTE:
CTE_ServicesIncludedInAgreement
                     
Usage: 
This CTE is used in the final select to link in Agreement Service details  
          
Things to keep in mind regarding this report and proc:
Since an billing invoice can be for a range of services or a single service, both
in a parent agreement, we need to be able to show the details for both situations.
If the biliing invoice is for a single service, so a service that flagged as Periodic
and Billed Separately = 'Y', then SMAgreementBillingScheduleExt will a have non null value
in its Service field. Otherwide that Service field will be null. We can use this 
functionality in the where clause to allow the CTE to eithe bring back a single detail
record (for single service billing invoices) or all the appropriate detail records (for
mulitple service billing invoices). 

In the where statement we firstly on want records that are either flagged as included
in the agreement or as periodic. By doing an inner join on SMAgreementBillingScheduleExt
and filtering out null SMInvoiceID records we know we only get records that are directly
related to an invoice. Finally we now need to make a decision on what type of records we
are returing, single or multiple services. If the Agrement Service record is periodic billed
separately we return the Service (Seq Number in the form), otherwise, we return 0 
and compare the results the isnull wrapped SMAgreementBillingScheduleExt.Service value. This way
we don't end up trying to do a where null = null comparison, which is ignored.

Views:
SMAgreementService as smas
	to get services related to an agreement
SMServiceSite as smss
	to service site details (Description)
SMAgreementBillingScheduleExt as smabse
	to be able to link the agreement services and related details to an invoice
==================================================================================*/ 

CTE_ServicesIncludedInAgreement

AS

(
	SELECT
		CASE WHEN smas.PricingMethod = 'I' 
			THEN 'Included'
			ELSE 'Periodic'
		END AS PricingFlag
		, smas.SMCo
		, smas.Agreement
		, smas.Revision
		, smas.Service AS AgreementService
		, smas.Description AS ServiceDescription
		, smas.Notes
		, smas.ServiceSite
		, smss.Description AS ServiceSiteDescription
		, smabse.SMInvoiceID
		, smabse.Service AS BillingService
	From 
		SMAgreementService smas
	INNER JOIN
		SMServiceSite smss ON
			smas.SMCo = smss.SMCo
			AND smas.ServiceSite = smss.ServiceSite
	INNER JOIN
		SMAgreementBillingScheduleExt smabse ON
			smabse.SMCo = smas.SMCo
			AND smabse.Agreement = smas.Agreement
			AND smabse.Revision = smas.Revision 
	WHERE
		PricingMethod IN ('P', 'I')
		AND SMInvoiceID IS NOT NULL
		AND 
			(
				CASE WHEN smas.PricingMethod = 'P' AND smas.BilledSeparately = 'Y'
					THEN smas.Service
					ELSE 0
				END
			) = ISNULL(smabse.Service,0)
		
), 

/*=================================================================================                      
CTE:
CTE_InvoicesWithInvoicedDates
                     
Usage: 
This CTE is used in the final select to link in Previous Billed amounts  
          
Things to keep in mind regarding this report and proc:
SMAgreementBillingScheduleExt does include the dates the invoice was actually invoiced
so we need to link in SMInvoiceSession to get this date. In the final select we can
use this date when we say 'give me all invoices that occured previous to the invoice
I am currently looking at (the invoice the report is returning data on)'. Any invoiced
date less then the current invoice date is considered 'Previously Billed' regardless
of the Billing Sequence (Billing field in SMAgreementBillingScheduleExt) order.

Views:
SMAgreementBillingScheduleExt as smabse
	to be able to link the agreement services and related details to an invoice in
	the final call
SMInvoiceSession as smis
	to give us the InvoiceDate values
==================================================================================*/ 

CTE_InvoicesWithInvoicedDates

as

(
	SELECT
		smabse.SMCo
		, smabse.Agreement
		, smabse.Revision
		, smabse.Service
		, smis.SMInvoiceID
		, smis.InvoiceDate
		, smabse.BillingAmount
		, smabse.TaxAmount
	FROM
		SMAgreementBillingScheduleExt smabse
	INNER JOIN
		SMInvoiceSession smis on
			smis.SMInvoiceID = smabse.SMInvoiceID
)

/*=================================================================================                      
Final Select
                     
Usage: 
Combines the CTEs, functions, and what not to all the details needed for the report
          
Things to keep in mind regarding this report and proc:
Other then getting the report data, this final select links to two table functions
to (vf_rptSMAgreementBillingsSeq and vf_rptSMAgreementBillingsCount) to get an understanding
of what bill we are on and how many are left (Bilings 2 of 5, or something like that). 
The final select also does some cross applys to SMAgreementBillingScheduleExt to figure out
dollar amounts that have already been billed and dollar amount that will be billed in the future.
We can do this based on the SMAgreementBillingScheduleExt.Billing value and just grab all before
and all after, nothing equal. The inition join to SMAgreementBillingScheduleExt (not the cross applys)
give us the current billing dollar amount. All the scenarios combined equal the total 
sum of the agreement. The CTE_LastWCDateInInvoice figures out if the current bill is the first 
or not and if it is the first gets the work complete date between the start of the agreement
(EffectiveDate) and the Invoiced Date. Otherwise it compares the work completed date
to the last billed date and the current Invoiced Date.

A Note regarding SMAgreementBillingScheduleExt.BillingType:
S = Scheduled - so a previously scheduled bill defined in the Agreement
A = Adjustment - an ad-hoc bill created when needed. 

For A records there is not previous and future bill data so the report will see
this and change text accordingly.

Views, CTEs, and Functions:
SMDeliveryGroupInvoice as smdgi
	to wrap up all requested invoices in a single reportgroup ID
SMInvoiceSession as smis
	to SMInvoiceID and related customer details
HQCO as hqco
	service provider name and mailing info
ARCM as arcm
	customer name
HQPT as payterms
	pay term details
SMAgreementBillingScheduleExt as smabse
	agreement number and if the invoice is for a single service or multiple services 
SMAgreement as smag
	agrement details
SMAgreementService as smags
	to get billing instance (X of Y) via functions
CTE_ServicesIncludedInAgreement as siia 
	what services are included in the invoice
CTE_InvoicesWithInvoicedDates as prevbilled
	what invoices are considered previous to the invoice we are looking at
SMAgreementInvoiceList as previnvdate
	what was the date of the most previous invoice, to help get work completed through date

outer apply on SMAgreementBillingScheduleExt as prevbilled
	to get sum of previously billed dollar amount
outer apply on SMAgreementBillingScheduleExt as futurebill
	to get sum of dollar amounts yet to be billed
outer apply on SMAgreementBillingScheduleExt as fullbill
	to get sum of either agreement total value or periodic billed separate total value

==================================================================================*/ 

SELECT
	CASE 
		WHEN smabse.Service IS NULL THEN 'AgrInv'
		WHEN smabse.Service IS NOT NULL THEN 'ServInv'
	END AS AgreementInvoiceType
	, smdgi.SMDeliveryReportID as DeliveryReportID
	, smis.SMCo AS CompanyNumber
	, hqco.Name AS CompanyName
	, hqco.Address AS CompanyAddress
	, hqco.Address2 AS CompanyAddress2
	, hqco.City AS CompanyCity
	, hqco.State AS CompanyState
	, hqco.Zip AS CompanyZip
	, hqco.Country AS CompanyCountry
	, hqco.Phone AS CompanyPhone
	, hqco.Fax AS CompanyFax
	, smis.Customer AS CustomerNumber
	, arcm.Name AS CustomerName
	, smis.BillAddress AS BillingAddress
	, smis.BillAddress2 AS BillingAddress2
	, smis.BillCity AS BillingCity
	, smis.BillState AS BillingState
	, smis.BillZip AS BillingZip
	, smis.BillCountry AS BillingCountry
	, smabse.Agreement AS AgreementNumber
	, smabse.Revision as AgreementRevision
	, smag.Description AS AgreementDescription
	, smag.EffectiveDate AS AgreementEffectiveDate
	, ISNULL(smag.ExpirationDate, '01/01/1950') AS AgreementExpirationDate
	, smag.CustomerPO AS AgreementPO
	, smis.SMInvoiceID AS InvoiceKeyID
	, smis.Invoice AS InvoiceNumber
	, smabse.BillingType as InvoiceBillingType
	, smis.InvoiceDate AS InvoiceInvoicedDate
	, smis.DueDate AS InvoiceDueDate
	, smis.DiscDate AS InvoiceDiscountDate
	, smabse.Service AS InvoiceSpecificService
	, smis.PayTerms AS InvoicePayTermsID
	, smis.DescriptionOfWork as InvoiceDescOfWork
	, payterms.Description AS InvoincePayTermsDescription
	, smabse.BillingSequence AS InvoiceAgreementBillingSequence	
	, smabse.BillingCount AS InvoiceAgreementTotalCountOfBills
	, smabse.BillingAmount AS InvoiceCurrentBillingAmount
	, smabse.TaxAmount AS InvoiceCurrentTaxAmount
	, prevbilled.SumPrevAmount AS InvoicePreviouslyBilledAmount
	, futurebill.SumFutAmount AS InvoiceAmountToBeBilled
	, fullbill.SumFullAmount as InvoiceAmountFullBill	
	, siia.PricingFlag AS BillableItemsPricingFlag
	, siia.AgreementService AS BillableItemsServiceSeqNumber
	, siia.ServiceDescription AS BillableItemsServiceSeqDescripion
	, siia.ServiceSite AS BillableItemsServiceSite
	, siia.ServiceSiteDescription AS BillableItemsServiceSiteDescription
	, siia.Notes AS BillableItemsServiceNotes	
From  
	SMDeliveryGroupInvoice smdgi
JOIN
	SMInvoiceSession smis on
		smdgi.SMInvoiceID = smis.SMInvoiceID
JOIN
	HQCO hqco ON
		smis.SMCo = hqco.HQCo
JOIN
	ARCM arcm ON
		smis.CustGroup = arcm.CustGroup
		AND smis.BillToARCustomer = arcm.Customer
LEFT JOIN
	HQPT payterms ON
		smis.PayTerms = payterms.PayTerms
JOIN  
	SMAgreementBillingScheduleExt smabse ON  
		smis.SMInvoiceID = smabse.SMInvoiceID
JOIN
	SMAgreement smag ON
		smabse.SMCo = smag.SMCo
		AND smabse.Agreement = smag.Agreement
		AND smabse.Revision = smag.Revision
LEFT JOIN
	SMAgreementService smags ON
		smags.SMCo=smabse.SMCo  
		AND smags.Agreement=smabse.Agreement  
		AND smags.Revision=smabse.Revision  
		AND smags.Service=smabse.Service
OUTER APPLY
	(
		SELECT
			isnull(SUM(c.BillingAmount),0) 
			+ isnull(SUM(c.TaxAmount),0) AS SumPrevAmount
		From 
			CTE_InvoicesWithInvoicedDates c  
		WHERE
			c.SMCo = smabse.SMCo
			AND c.Agreement = smabse.Agreement
			AND c.Revision = smabse.Revision
			AND dbo.vfIsEqual(c.Service,smabse.Service) = 1
			AND smis.InvoiceDate > c.InvoiceDate
	) prevbilled
OUTER APPLY
	(
		SELECT
			isnull(SUM(s.BillingAmount),0)
			+ isnull(SUM(s.TaxAmount),0) AS SumFutAmount
		From 
			SMAgreementBillingScheduleExt s  
		WHERE
			s.SMCo = smabse.SMCo
			AND s.Agreement = smabse.Agreement
			AND s.Revision = smabse.Revision
			AND dbo.vfIsEqual(s.Service,smabse.Service) = 1
			AND s.SMInvoiceID is null
	) futurebill
OUTER APPLY
	(
		SELECT
			isnull(SUM(s.BillingAmount),0)
			+ isnull(SUM(s.TaxAmount),0) AS SumFullAmount
		From 
			SMAgreementBillingScheduleExt s  
		WHERE
			s.SMCo = smabse.SMCo
			AND s.Agreement = smabse.Agreement
			AND s.Revision = smabse.Revision
			AND dbo.vfIsEqual(s.Service,smabse.Service) = 1
			and s.BillingType <> 'A'
	) fullbill
LEFT JOIN
	CTE_ServicesIncludedInAgreement siia ON
		smabse.SMCo = siia.SMCo
		AND smabse.SMInvoiceID = siia.SMInvoiceID
WHERE  
	smdgi.SMDeliveryReportID = @SMDeliveryReportID
GO
GRANT EXECUTE ON  [dbo].[vrptSMAgreementBillingInvoice] TO [public]
GO
