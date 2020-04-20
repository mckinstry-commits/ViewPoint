SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
--		Author:	Lane Gresham
-- Create Date: 09/20/11
-- Description:	Query to get list of items to populate SM Invoice Delivery Search
--	  Modified: 10/12/11 LDG - Added Invoice Status
--				10/21/11 LDG - Added Join to SMInvoiceSession
--				04/19/12 ECV - Added visibility to Agreement Invoices
--		 Notes:
--				InvoiceStatus
--					I = Invoiced
--					P = Pending Invoice
--
--				PrintStatus
--					N = Not Printed
--					P = Printed
--					A = All
-- =============================================
CREATE FUNCTION [dbo].[vfSMInvoiceDeliverySearch]
(
	@SMCo AS bCompany, 
	@CustGroup AS bGroup,
	@InvoiceStatus AS char(1) = NULL,
	@PrintStatus AS char(1) = NULL,
	@BillToCustomer AS bCustomer = NULL,
	@InvoiceNumber AS varchar(10) = NULL,
	@InvoiceStartDate AS bDate = NULL,
	@InvoiceEndDate AS bDate = NULL,
	@PrintStartDate AS bDate = NULL,
	@PrintEndDate AS bDate = NULL
)
RETURNS TABLE
AS
RETURN
(
		SELECT 'N' AS GridSelect,
			   SMInvoiceList.SMInvoiceID AS GridInvoiceID, 
			   SMInvoiceList.InvoiceNumber AS GridInvoiceNumber, 
			   SMInvoiceList.InvoiceDate AS GridInvoiceDate, 
			   SMInvoiceList.Customer AS GridCustomer, 
			   SMCustomerInfo.Name AS GridCustomerName,
			   SMInvoiceList.BillToARCustomer AS GridBillTo, 
			   ARCM.Name AS GridBillToName,
			   SMInvoiceList.TotalAmount GridInvoiceAmt,
			   SMInvoiceList.DeliveredDate AS GridLastPrinted, 
			   SMInvoiceList.DeliveredBy AS GridPrintedBy,
			   SMInvoiceList.InvoiceType AS GridInvoiceType
		FROM dbo.SMInvoiceList
			LEFT JOIN ARCM ON SMInvoiceList.CustGroup = ARCM.CustGroup AND SMInvoiceList.BillToARCustomer = ARCM.Customer
			LEFT JOIN SMCustomerInfo ON SMInvoiceList.SMCo = SMCustomerInfo.SMCo AND SMInvoiceList.CustGroup = SMCustomerInfo.CustGroup AND SMInvoiceList.Customer = SMCustomerInfo.Customer
			LEFT JOIN SMInvoiceSession ON SMInvoiceList.SMInvoiceID = SMInvoiceSession.SMInvoiceID
		WHERE SMInvoiceList.SMCo = @SMCo
			AND SMInvoiceList.VoidDate IS NULL --Exclude voided invoices
			AND (SMInvoiceList.Prebilling = 0 OR SMInvoiceList.Prebilling IS NULL)
			AND SMInvoiceList.CustGroup = @CustGroup
			AND SMInvoiceList.Invoiced = CASE @InvoiceStatus WHEN 'I' THEN 1 ELSE 0 END
			AND
			(
				(@PrintStatus = 'A') OR
				(@PrintStatus = 'N' AND SMInvoiceList.DeliveredDate IS NULL) OR
				(@PrintStatus = 'P' AND SMInvoiceList.DeliveredDate IS NOT NULL)
			) AND
			(
				@InvoiceNumber IS NULL OR
				SMInvoiceList.InvoiceNumber = @InvoiceNumber
			) AND
			(
				@InvoiceStartDate IS NULL OR
				SMInvoiceList.InvoiceDate >= @InvoiceStartDate
			) AND
			(
				@InvoiceEndDate IS NULL OR
				SMInvoiceList.InvoiceDate <= @InvoiceEndDate
			) AND
			(
				@BillToCustomer IS NULL OR
				SMInvoiceList.BillToARCustomer = @BillToCustomer
			) AND
			(
				@PrintStartDate IS NULL OR
				SMInvoiceList.DeliveredDate >= @PrintStartDate
			) AND
			(
				@PrintEndDate IS NULL OR
				SMInvoiceList.DeliveredDate <= @PrintEndDate
			)
)
GO
GRANT SELECT ON  [dbo].[vfSMInvoiceDeliverySearch] TO [public]
GO
