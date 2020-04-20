SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[vrvSMAgreementPriceTaxTotal]

/***********************************************************************      
Author:   
Scott Alvey
     
Create date:   
07/12/2012 

Originating V1 reference:   
B-09718 - Add Tax Details to SM Agreements
   
Usage: 
There is a good chance that SM Agreement related reports will need both the
original Agreement Price and a sum of all taxable aspects. Rather than
have to repeat this code every time I took a lesson from the Crusades and 
created this view so we can attach it to needy report. 

Development Notes:
Just need to remember that billings can either be on the agreement or on the
service, hence the case statement flag
  
Parameters:
NA
  
Related reports: 
SM Agreement Billing (ID: 1222)  
SM Service Agreement (ID: 1206)      
      
Revision History      
Date  Author  Issue     Description  

***********************************************************************/  

as

Select
	CASE 
		WHEN smabs.Service IS NULL THEN 'AgrInv'
		WHEN smabs.Service IS NOT NULL THEN 'ServInv'
	END AS AgreementInvoiceType
	, smabs.SMCo
	, smabs.Agreement
	, smabs.Revision
	, smabs.Service
	, sum(smabs.BillingAmount) as AgreementPrice
	, sum(smabs.TaxAmount) as AgreementTax
From
	SMAgreementBillingSchedule smabs 
Group By
	smabs.SMCo
	, smabs.Agreement
	, smabs.Revision
	, smabs.Service

GO
GRANT SELECT ON  [dbo].[vrvSMAgreementPriceTaxTotal] TO [public]
GRANT INSERT ON  [dbo].[vrvSMAgreementPriceTaxTotal] TO [public]
GRANT DELETE ON  [dbo].[vrvSMAgreementPriceTaxTotal] TO [public]
GRANT UPDATE ON  [dbo].[vrvSMAgreementPriceTaxTotal] TO [public]
GRANT SELECT ON  [dbo].[vrvSMAgreementPriceTaxTotal] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvSMAgreementPriceTaxTotal] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvSMAgreementPriceTaxTotal] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvSMAgreementPriceTaxTotal] TO [Viewpoint]
GO
