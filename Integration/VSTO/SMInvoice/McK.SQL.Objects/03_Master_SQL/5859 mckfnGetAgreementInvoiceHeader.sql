USE Viewpoint
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_NAME='mckfnGetAgreementInvoiceHeader' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='FUNCTION' )
Begin
	Print 'DROP FUNCTION dbo.mckfnGetAgreementInvoiceHeader'
	DROP FUNCTION dbo.mckfnGetAgreementInvoiceHeader
End
GO

Print 'CREATE FUNCTION dbo.mckfnGetAgreementInvoiceHeader'
GO


CREATE FUNCTION [dbo].mckfnGetAgreementInvoiceHeader
(
  @BillToCustomer	bCustomer
, @InvoiceNumber	varchar(10)
, @Agreement		varchar(15) 
)	
RETURNS TABLE
AS
 /* 
	Purpose:	Get Agreement Invoice header detail 
	Created:	10.03.18
	Author:	Leo Gurdian

	HISTORY:
	
	01.07.19 LG - TFS 5859 - Agreement error converting udAGStatus: Conversion failed when converting the *** value '****' to data type ****. 
	09.26.19 LG - TFS 5476 - Agreement now has correct Contract Value when more than 1 active revision exists
								  - Agreement not returning data fixed
	08.20.19 LG - TFS 4797 add Division for UI template logic
	07.25.19 LG - TFS 4833 Pay Terms now reflect SM Invoice Review Pay Terms
	06.26.19 LG - TFS 4668 add PayTerms from ARCM
	06.24.19 LG - TFS 4771 let ContractValue be SMAgreement.AgreementPrice not wip.RevenueWIPAmount
					- add multidivion field with window function 
	06.18.19 LG - TFS 4003 If Agreement is Multi-Division, Remove the Insert Box except the PO #
	05.10.19 LG - rewrite 
					- PreviouslyBilled = wip.JTDBilled - wip.MTDBilling - TFS 4313
					- Through Date = Month of the Invoice Date rather than the current billing period month
	05.03.19 LG	- join mckWipArchiveAG4 to get Balance and Previously Billed
	04.19.19 LG - Removed WOs, minimized joins
	10.03.18 LG - Get agreement detail
*/
RETURN
(
/* TEST AGREEMENT 
Declare @BillToCustomer bCustomer	= 205240
Declare @InvoiceNumber	varchar(10)	= '10106350'
Declare @Agreement		varchar(15) = '10924'
*/
SELECT 
  il.SMCo					AS SMCo
, il.InvoiceType			AS InvoiceType
, il.InvoiceNumber		AS InvoiceNumber
, il.InvoiceDate			AS InvoiceDate
, HQPT.Description		AS PayTerms
, CASE WHEN DENSE_RANK() OVER(PARTITION BY A1.Agreement ORDER by B2.Division) = 1 THEN 'N' ELSE 'Y' END AS MultiDivision
, B2.Division
, A1.Agreement				AS Agreement
, A1.CustomerPO			AS CustomerPO
, A1.AgreementPrice		AS ContractValue
, ISNULL(wip.JTDBilled,0) - ISNULL(wip.MTDBilling,0)			AS PreviouslyBilled
--, (wip.RevenueWIPAmount - (wip.JTDBilled - wip.MTDBilling)) - BasePrice	AS Balance
, A1.Customer				AS BillToCustomer
, smss.Description		AS ServiceSiteDescription
, smss.Address1			AS ServiceSiteAddress
, smss.Address2			AS ServiceSiteAddress2
, smss.City					AS ServiceSiteCity
, smss.State				AS ServiceSiteState
, smss.Zip					AS ServiceSiteZip
, bill.Name					AS MailingName
, bill.Address				AS MailingAddress1
, bill.Address2			AS MailingAddress2
, bill.City					AS MailingCity
, bill.State				AS MailingState
, bill.Country				AS MailingCountry
, bill.Zip					AS MailingPostalCode
FROM dbo.vSMCO co 	
INNER JOIN dbo.SMInvoice il ON
	co.SMCo = il.SMCo
INNER JOIN dbo.SMCustomerInfo bill 
	ON		 il.CustGroup = bill.CustGroup
		AND il.BillToARCustomer = bill.Customer
INNER JOIN dbo.SMInvoiceDetail id   
	ON il.SMCo = id.SMCo
		AND il.Invoice = id.Invoice
INNER JOIN dbo.SMInvoiceLine L
	ON		 il.SMCo = L.SMCo
		AND il.Invoice = L.Invoice
		AND id.InvoiceDetail = L.InvoiceDetail
		AND L.Invoice IS NOT NULL 
LEFT OUTER JOIN dbo.mckWipArchiveAG4 wip ON	    
	wip.JCCo = co.JCCo AND 
	wip.Agreement = id.Agreement AND 
	wip.ThroughMonth = (SELECT DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()),1))	
INNER JOIN	dbo.mckSMAgreementExtended A1 ON 
	il.CustGroup = il.CustGroup AND 
	il.Customer = il.Customer AND 
	id.Agreement = id.Agreement
INNER JOIN dbo.SMAgreementService B1
	ON A1.SMCo = B1.SMCo
			AND A1.Agreement = B1.Agreement
			AND A1.Revision = B1.Revision
INNER JOIN dbo.SMDivision B2
	ON B1.SMCo = B2.SMCo
		AND B1.ServiceCenter = B2.ServiceCenter
INNER JOIN dbo.SMServiceSite smss ON  
	B1.SMCo = smss.SMCo AND 
	B1.ServiceSite = smss.ServiceSite
LEFT OUTER JOIN dbo.HQPT HQPT
						ON HQPT.PayTerms = il.PayTerms -- for HQPT.Description TFS 4833 
WHERE RTRIM(LTRIM(ISNULL(il.InvoiceNumber,' '))) = RTRIM(LTRIM(ISNULL(@InvoiceNumber, ' ')))
	AND A1.Agreement = @Agreement
	AND A1.Customer = @BillToCustomer 
	AND (A1.udAGStatus = '1' OR A1.udAGStatus = 'R') -- (1-Open, R-Review) -- TFS 5859 - conversion error fix
)

GO

Grant SELECT ON dbo.mckfnGetAgreementInvoiceHeader TO [MCKINSTRY\Viewpoint Users]

/*

Select * From dbo.mckfnGetAgreementInvoiceHeader(216685, '  10053250', 6, '12307-001-770')
Select * From dbo.mckfnGetAgreementInvoiceHeader(211503, '10068280', '10006', '211503')
Select * From dbo.mckfnGetAgreementInvoiceHeader(207321, '10073778', '10156', null)
Select * From dbo.mckfnGetAgreementInvoiceHeader(248643, '10073777', '10703', 200258)

/*  MULTI-DIVISION SPREAD  */

Select * From dbo.mckfnGetAgreementInvoiceHeader(214393, '10080839', '10690', 214393) 

SELECT * FROM dbo.mckWipArchiveAG4 wip 
WHERE wip.Agreement = 10690
AND wip.ThroughMonth =  (SELECT DATEFROMPARTS(YEAR('2019-05-16'), MONTH('2019-05-16'),1))

Select * From dbo.mckfnGetAgreementInvoiceHeader(200166, '10084457', '10909', 248469)
Select * From dbo.mckfnGetAgreementInvoiceHeader(248534, '10073882', '10506', 248530)

Select * From dbo.mckfnGetAgreementInvoiceHeader(215211, '10073773', '10674', 215211)
*/

