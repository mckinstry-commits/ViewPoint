USE Viewpoint
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_NAME = 'mckfnAgreement' and ROUTINE_SCHEMA = 'dbo' and ROUTINE_TYPE = 'FUNCTION' )
Begin
	Print 'DROP FUNCTION dbo.mckfnAgreement'
	DROP FUNCTION dbo.mckfnAgreement
End
GO

Print 'CREATE FUNCTION dbo.mckfnAgreement'
GO


CREATE FUNCTION [dbo].mckfnAgreement
(
  @SMCo				bCompany
, @Agreement		varchar(15)
, @InvoiceNumber	VARCHAR(10) = NULL
)
RETURNS TABLE
AS
 /* 
	Purpose:	Get Agreement invoice detail
	Created:		
	Author:		Leo Gurdian
	HISTORY:
	
	05.09.19 LG add "BILLING" to [BillingPeriod] field description
	04.19.19 LG add CustomerPO
	11.21.18 LG get amounts from SMInvoiceList
	10.01.18 LG Get Agreement data for Invoice
*/
RETURN
(

 /* ACTIVE SERVICE AGREEMENT REPORT */
SELECT TOP(1)
  A.Agreement			AS Agreement	
, A.CustomerPO			AS CustomerPO
, CAST(CAST(MIN(CONVERT(NVARCHAR(20),A.EffectiveDate, 1)) as VARCHAR(20)) + ' - ' + CAST(MAX(CONVERT(NVARCHAR(20),A.ExpirationDate,1))as VARCHAR(20)) as VARCHAR(800)) 
	+ '  PREVENTIVE MAINTENANCE BILLING AS PER AGREEMENT'
	AS BillingPeriod 
--, S.Description		AS Description
, A.AgreementPrice	AS ContractValue
, IL.TotalBilled		AS BasePrice
, IL.TotalTaxed		AS Tax
, IL.TotalAmount		AS TotalDue --, *
FROM dbo.SMInvoice I
		INNER JOIN dbo.SMCustomerInfo NFO 
			ON 	I.SMCo = NFO.SMCo
					AND I.CustGroup		= NFO.CustGroup
					AND I.BillToARCustomer	= NFO.Customer
		INNER MERGE JOIN dbo.SMInvoiceDetail D       
			ON I.SMCo = D.SMCo
					AND I.Invoice = D.Invoice
		INNER JOIN dbo.SMInvoiceList IL on
				D.SMCo = IL.SMCo
			AND D.Invoice = IL.Invoice
		INNER JOIN dbo.SMInvoiceLine L
			ON I.SMCo = L.SMCo
					AND I.Invoice = L.Invoice
					AND L.InvoiceDetail = D.InvoiceDetail 
					AND L.Invoice IS NOT NULL 
		LEFT JOIN dbo.SMAgreementExtended A 
			ON		A.SMCo		= I.SMCo
				AND A.CustGroup = I.CustGroup
				AND A.Customer	= I.BillToARCustomer
				AND A.AgreementStatus	= 'A'
				AND A.RevisionStatus	= 2
				AND A.Agreement			= D.Agreement
		LEFT OUTER JOIN dbo.SMAgreementService S ON 
						A.Agreement = S.Agreement 
					AND A.Revision	= S.Revision 
					AND A.SMCo		= S.SMCo 
WHERE A.SMCo = @SMCo
	AND A.Agreement  = @Agreement
	AND RTRIM(LTRIM(ISNULL(IL.InvoiceNumber,' '))) = RTRIM(LTRIM(ISNULL(@InvoiceNumber, ' ')))
	AND A.RevisionStatus  =  2 -- active
	AND A.AgreementStatus = 'A' -- active 
 Group By  
   A.Agreement
 --, S.Description
 , A.AgreementPrice
 , IL.TotalBilled
 , IL.TotalTaxed
 , IL.TotalAmount
 , A.CustomerPO
 , IL.CustomerPO
 , S.BillingTotalRemaining
)

GO

Grant SELECT ON dbo.mckfnAgreement TO [MCKINSTRY\Viewpoint Users]

/*

Select * From dbo.mckfnAgreement(1, '10690', '10080839' ) -- MULTI-DIVISION SPREAD

*/