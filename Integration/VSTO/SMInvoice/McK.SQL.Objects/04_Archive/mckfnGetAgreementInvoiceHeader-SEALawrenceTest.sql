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
, @Agreement		varchar(15) = NULL
, @ServiceSite		varchar(20) = NULL
)	
RETURNS TABLE
AS
 /* 
	Purpose:	Get Agreement Invoice header detail 
	Created:	10.03.18
	Author:		Leo Gurdian
	HISTORY:
	
	12.19.2018 LG - Add BillToCustomer
	10.03.2018 LG - Get agreement detail
*/
RETURN
(
/* TEST AGREEMENT
Declare @BillToCustomer bCustomer	= 216685
Declare @InvoiceNumber	varchar(10)	= '  10053250'
Declare @Agreement		varchar(15) = 6
Declare @ServiceSite	varchar(20) = '12307-001-770'
 */

	Select 
	  InvoiceType
	, i.SMCo
	, InvoiceNumber
	, InvoiceDate
	, a.Agreement
	, SMInvoiceWorkOrders.InvoiceWorkOrders AS [WorkOrders]
	, i.CustomerPO
	, w.Customer
	--Service Site Information
	, smss.Description as ServiceSiteDescription
	, smss.Address1 as ServiceSiteAddress
	, smss.Address2 as ServiceSiteAddress2
	, smss.City as ServiceSiteCity
	, smss.State as ServiceSiteState
	, smss.Zip as ServiceSiteZip
	, bill.Customer AS BillToCustomer
	, bill.Name MailingName
	, bill.Address MailingAddress1
	, bill.Address2 MailingAddress2
	, bill.City MailingCity
	, bill.State MailingState
	, bill.Country MailingCountry
	, bill.Zip MailingPostalCode
	From SMInvoiceDetail d
		INNER JOIN SMInvoiceList i on
				d.SMCo = i.SMCo
			AND d.Invoice = i.Invoice
		INNER JOIN dbo.vSMCO ON vSMCO.SMCo = i.SMCo
		INNER JOIN SMCustomer c
			ON	 c.SMCo = i.SMCo
			AND c.Customer = @BillToCustomer 
			AND c.CustGroup = i.CustGroup
		INNER JOIN dbo.ARCM bill
				ON  i.CustGroup = bill.CustGroup
				AND i.BillToARCustomer = bill.Customer
		INNER JOIN SMWorkOrder w 
			ON  i.SMCo = w.SMCo
			AND i.CustGroup = w.CustGroup
			AND i.Customer  = w.Customer
			OUTER APPLY dbo.vfSMGetInvoiceWorkOrders (vSMCO.SMCo, i.SMInvoiceID, i.Invoice) SMInvoiceWorkOrders
		INNER JOIN SMServiceSite smss
			ON  w.SMCo = smss.SMCo
			and w.ServiceSite = smss.ServiceSite
		LEFT JOIN SMAgreementExtended a ON
					a.SMCo = i.SMCo
				AND a.CustGroup = i.CustGroup
				AND a.Customer = i.Customer
				AND a.AgreementStatus = 'A'
				AND a.Agreement = d.Agreement
	Where c.Active = 'Y' 
		AND (RTRIM(LTRIM(ISNULL(i.InvoiceNumber,'')))) = (RTRIM(LTRIM(ISNULL(@InvoiceNumber,''))))
		AND (a.Agreement = @Agreement OR @Agreement IS NULL)
		AND (smss.ServiceSite = @ServiceSite)

)

GO

Grant SELECT ON dbo.mckfnGetAgreementInvoiceHeader TO [MCKINSTRY\Viewpoint Users]

/*

Select * From dbo.mckfnGetAgreementInvoiceHeader(216685, '  10053250', 6, '12307-001-770')

Select * From dbo.mckfnGetAgreementInvoiceHeader(216685, '  10053178', 9, '216685')

*/