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
  @InvoiceNumber	varchar(10)
, @WorkOrder		int = NULL
)	
RETURNS TABLE
AS
 /* 
	Project:	MCK SM Invoice Excel VSTO
	Purpose:	Get Invoice WO header detail
	Created:	09.18.2018
	Author:	Leo Gurdian

	HISTORY:
	
	07.16.2019 LG - TFS 4828 - Bug Fix: unable to pull detail due to missing scope 1
	06.25.2019 LG - FIRE PayTerms pull from ARCM - TFS 4780
	04.09.2019 LG - Add CustGroup, PayTerms
	12.19.2018 LG - Add BillToCustomer
	11.15.2018 LG - Instead of WorkCompleted PO, pull Customer PO from WO Scope
	11.12.2018 LG - Add WO filter
	09.18.2018 LG - Get Invoice WO header detail
*/
RETURN
(
/* TEST WORK ORDER 
Declare @InvoiceNumber	varchar(10)	= '  10080916'
Declare @WorkOrder		int			= 9531469
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
	, CASE WHEN smdiv.udGLDept IN ('0250', '0251') THEN CAST(bill.PayTerms AS VARCHAR(30)) -- FIRE specific
		WHEN I.SMCo = 1 THEN 'DUE UPON RECEIPT' -- Rest of Company 1
		ELSE CAST(bill.PayTerms AS VARCHAR(30))
	  END				AS PayTerms
	, bill.CustGroup	AS CustGroup
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
					AND S.Scope  = ISNULL(D.Scope, (SELECT MIN(Scope) FROM dbo.SMWorkOrderScope s WHERE s.WorkOrder = @WorkOrder)) -- TFS 4828 when missing scope, get next available
			INNER JOIN	dbo.SMWorkOrder WO
				ON WO.SMCo = S.SMCo
						AND WO.WorkOrder = S.WorkOrder
			INNER JOIN dbo.SMServiceSite SS 
				ON  SS.SMCo		 = WO.SMCo
				AND SS.ServiceSite = WO.ServiceSite
			-- GET DEPT
			INNER JOIN dbo.SMDivision AS div
				ON		 div.SMCo = I.SMCo
					AND div.ServiceCenter = S.ServiceCenter
					AND div.Division = S.Division
			INNER JOIN dbo.SMDepartment AS smdiv
				ON		 smdiv.SMCo = I.SMCo
					AND smdiv.Department = div.Department
			-- END GET DEPT 
			INNER JOIN dbo.SMCustomerInfo bill --ARCM
				ON  I.CustGroup = bill.CustGroup
				AND I.BillToARCustomer = bill.Customer
			LEFT OUTER JOIN dbo.SMWorkCompleted WC 
				ON		WC.WorkOrder	 = D.WorkOrder
					AND WC.WorkCompleted = D.WorkCompleted
		OUTER APPLY dbo.vfSMGetInvoiceWorkOrders (I.SMCo, I.SMInvoiceID, I.Invoice) SMInvoiceWorkOrders
	Where (RTRIM(LTRIM(ISNULL(I.InvoiceNumber,'')))) = (RTRIM(LTRIM(ISNULL(@InvoiceNumber,''))))
			AND D.WorkOrder = @WorkOrder
)

GO

Grant SELECT ON dbo.mckfnGetWOinvoiceHeader TO [MCKINSTRY\Viewpoint Users]

/*

Select * From dbo.mckfnGetWOinvoiceHeader(246109, 1478218) - INV 8040206 PO 130248020


Select * From dbo.mckfnGetWOinvoiceHeader(246098, 10057364 )

Select * From dbo.mckfnGetWOinvoiceHeader('1257015', 8003588 )

Select * From dbo.mckfnGetWOinvoiceHeader('0474415', 9026058 )

Select * From dbo.mckfnGetWOinvoiceHeader('10061146', 8043427 )

Select * From dbo.mckfnGetWOinvoiceHeader('10057408', 8042573 )

*/