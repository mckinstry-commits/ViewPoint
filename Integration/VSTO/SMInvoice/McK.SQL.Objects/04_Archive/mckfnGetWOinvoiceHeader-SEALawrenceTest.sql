USE Viewpoint
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_NAME='mckfnGetWOinvoiceHeader' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='FUNCTION' )
Begin
	Print 'DROP FUNCTION dbo.mckfnGetWOinvoiceHeader'
	DROP FUNCTION dbo.mckfnGetWOinvoiceHeader
End
GO

Print 'CREATE FUNCTION dbo.mckfnGetWOinvoiceHeader'
GO


CREATE FUNCTION [dbo].mckfnGetWOinvoiceHeader
(
  @BillToCustomer	bCustomer
, @InvoiceNumber	varchar(10)
, @WorkOrder		int = NULL
)	
RETURNS TABLE
AS
 /* 
	Purpose:	Get Invoice WO header detail
	Created:	09.18.2018
	Author:		Leo Gurdian

	HISTORY:
	12.19.2018 LG - Add BillToCustomer
	11.15.2018 LG - Instead of WorkCompleted PO, pull Customer PO from WO Scope
	11.12.2018 LG - Add WO filter
	09.18.2018 LG - Get Invoice WO header detail
*/
RETURN
(
/* TEST WORK ORDER 
Declare @BillToCustomer bCustomer	= 216082
Declare @InvoiceNumber	varchar(10)	= '10061146'
Declare @WorkOrder		int			= 8043427
*/
SELECT DISTINCT
	  I.InvoiceType 
	, I.SMCo
	, I.InvoiceNumber
	, I.InvoiceDate
	, SMInvoiceWorkOrders.InvoiceWorkOrders AS [WorkOrders]
	, S.CustomerPO							As [CustomerPO]
	, I.Customer
	----Service Site Information
	, SS.ServiceSite AS ServiceSite
	, SS.Description AS ServiceSiteDescription
	, SS.Address1 AS ServiceSiteAddress
	, SS.Address2 AS ServiceSiteAddress2
	, SS.City		AS ServiceSiteCity
	, SS.State	AS ServiceSiteState
	, SS.Zip		AS ServiceSiteZip
	, bill.Customer AS BillToCustomer
	, bill.Name		AS MailingName
	, bill.Address	AS MailingAddress1
	, bill.Address2 AS MailingAddress2
	, bill.City		AS MailingCity
	, bill.State	AS MailingState
	, bill.Country	AS MailingCountry
	, bill.Zip		AS MailingPostalCode
	From dbo.SMInvoice I
			INNER JOIN dbo.SMInvoiceDetail D    
				ON I.SMCo = D.SMCo
						AND I.Invoice = D.Invoice
			INNER JOIN dbo.SMInvoiceLine L
				ON I.SMCo = L.SMCo
						AND I.Invoice = L.Invoice
						AND D.InvoiceDetail = L.InvoiceDetail
						AND L.Invoice IS NOT NULL 
			INNER JOIN dbo.SMWorkOrderScope S 
				ON I.SMCo = S.SMCo
						AND D.WorkOrder = S.WorkOrder
						AND ISNULL(D.Scope,1) = S.Scope   --Per esther defaul to 1st scope 
						--AND S.Agreement IS NULL
			INNER JOIN	dbo.SMWorkOrder WO
				ON WO.SMCo = S.SMCo
						AND WO.WorkOrder = S.WorkOrder
			INNER JOIN dbo.SMServiceSite SS 
				ON  SS.SMCo		 = WO.SMCo
				AND SS.ServiceSite = WO.ServiceSite
			INNER JOIN dbo.SMCustomerInfo bill --ARCM
				ON  I.CustGroup = bill.CustGroup
				AND I.BillToARCustomer = bill.Customer
			LEFT OUTER JOIN dbo.SMWorkCompleted WC 
				ON		WC.WorkOrder	 = D.WorkOrder
					AND WC.WorkCompleted = D.WorkCompleted
		OUTER APPLY dbo.vfSMGetInvoiceWorkOrders (I.SMCo, I.SMInvoiceID, I.Invoice) SMInvoiceWorkOrders
	Where (RTRIM(LTRIM(ISNULL(I.InvoiceNumber,'')))) = (RTRIM(LTRIM(ISNULL(@InvoiceNumber,''))))
			AND I.Customer  = @BillToCustomer
			AND D.WorkOrder = @WorkOrder
)

GO

Grant SELECT ON dbo.mckfnGetWOinvoiceHeader TO [MCKINSTRY\Viewpoint Users]

/*

Select * From dbo.mckfnGetWOinvoiceHeader(21753,'  10053281')

Select * From dbo.mckfnGetWOinvoiceHeader(213409, 10057267)

Select * From dbo.mckfnGetWOinvoiceHeader(246109, 10057347)

Select * From dbo.mckfnGetWOinvoiceHeader(246098, 9019259)

Select * From dbo.mckfnGetWOinvoiceHeader(200721, 9019259)

Select * From dbo.mckfnGetWOinvoiceHeader(246109, 1478218) - INV 8040206 PO 130248020


Select * From dbo.mckfnGetWOinvoiceHeader(246098, 10057364 )

Select * From dbo.mckfnGetWOinvoiceHeader(221480, '1257015', 8003588 )

Select * From dbo.mckfnGetWOinvoiceHeader(212229, '0474415', 9026058 )

Select * From dbo.mckfnGetWOinvoiceHeader(216082, '10061146', 8043427 )


PROD:

Select * From dbo.mckfnGetWOinvoiceHeader(211507, '10057408', 8042573 )

*/