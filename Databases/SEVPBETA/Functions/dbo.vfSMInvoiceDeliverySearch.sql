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
			   SMInvoice.SMInvoiceID AS GridInvoiceID, 
			   SMInvoice.Invoice AS GridInvoiceNumber, 
			   SMInvoice.InvoiceDate AS GridInvoiceDate, 
			   SMInvoice.Customer AS GridCustomer, 
			   SMCustomerInfo.Name AS GridCustomerName,
			   SMInvoice.BillToARCustomer AS GridBillTo, 
			   ARCM.Name AS GridBillToName,
			   CASE WHEN SMInvoice.InvoiceType='W' THEN ISNULL(SMWorkCompleted.TotalBilled,0) + ISNULL(SMWorkCompleted.TotalTaxed,0) 
					WHEN SMInvoice.InvoiceType='A' THEN SMAgreementBillingSchedule.BillingAmount
					ELSE 0 END
			   AS GridInvoiceAmt,
			   SMInvoice.DeliveredDate AS GridLastPrinted, 
			   SMInvoice.DeliveredBy AS GridPrintedBy,
			   SMInvoiceSession.SMSessionID AS GridSMSessionID,
			   SMInvoice.InvoiceType AS GridInvoiceType
		FROM dbo.SMInvoice
			OUTER APPLY (
				SELECT
					ISNULL(SUM(CASE WHEN ISNULL(SMWorkCompleted.NoCharge,'N') = 'N' THEN SMWorkCompleted.PriceTotal ELSE 0 END), 0.00) AS TotalBilled, --0 AS TotalTaxed
					ISNULL(SUM(CASE WHEN ISNULL(SMWorkCompleted.NoCharge,'N') = 'N' THEN SMWorkCompleted.TaxAmount ELSE 0 END),0.00) as TotalTaxed
				FROM dbo.SMWorkCompleted
				WHERE SMWorkCompleted.SMInvoiceID = SMInvoice.SMInvoiceID
			) SMWorkCompleted
			LEFT JOIN SMAgreementBillingSchedule ON SMAgreementBillingSchedule.SMCo = SMInvoice.SMCo AND SMAgreementBillingSchedule.SMInvoiceID = SMInvoice.SMInvoiceID
			LEFT JOIN ARCM ON SMInvoice.CustGroup = ARCM.CustGroup AND SMInvoice.BillToARCustomer = ARCM.Customer
			LEFT JOIN SMCustomerInfo ON SMInvoice.SMCo = SMCustomerInfo.SMCo AND SMInvoice.CustGroup = SMCustomerInfo.CustGroup AND SMInvoice.Customer = SMCustomerInfo.Customer
			LEFT JOIN SMInvoiceSession ON SMInvoice.SMInvoiceID = SMInvoiceSession.SMInvoiceID
			-- Session may be in a transation when the invoice is loaded therefore we use NOLOCK to read the recored without being locked
			LEFT JOIN SMSession WITH (NOLOCK) ON SMSession.SMSessionID = SMInvoiceSession.SMSessionID
		WHERE SMInvoice.SMCo = @SMCo
		AND SMInvoice.VoidDate IS NULL --Exclude voided invoices
		AND (SMSession.Prebilling = 0 OR SMSession.Prebilling IS NULL)
		AND SMInvoice.CustGroup = @CustGroup 
		AND 
		(
			   (@PrintStatus = 'N' AND SMInvoice.DeliveredDate IS NULL)
			OR (@PrintStatus = 'P' AND SMInvoice.DeliveredDate IS NOT NULL)
			OR (@PrintStatus = 'A')
		)
		AND SMInvoice.Invoice = ISNULL(@InvoiceNumber, SMInvoice.Invoice) 
		AND (@InvoiceStartDate IS NULL OR SMInvoice.InvoiceDate >= @InvoiceStartDate)
		AND (@InvoiceEndDate IS NULL OR SMInvoice.InvoiceDate <= @InvoiceEndDate)
		AND SMInvoice.BillToARCustomer = ISNULL(@BillToCustomer, SMInvoice.BillToARCustomer) 
		AND (@PrintStartDate IS NULL OR SMInvoice.DeliveredDate >= @PrintStartDate)
		AND (@PrintEndDate IS NULL OR SMInvoice.DeliveredDate <= @PrintEndDate)
		AND SMInvoice.Invoiced = CASE @InvoiceStatus WHEN 'I' THEN 1 ELSE 0 END
)
GO
GRANT SELECT ON  [dbo].[vfSMInvoiceDeliverySearch] TO [public]
GO
