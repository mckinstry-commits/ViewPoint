SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Vaterlaus
-- Create date: 08/24/11
-- Description:	Get a list of invoices with a description that are part of the current session.
-- =============================================
CREATE PROCEDURE dbo.vspSMBillingInvoiceList
		@SMCo tinyint, 
		@SMSessionID int=NULL,
		@msg varchar(255)=NULL OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		
		SELECT SMInvoice.SMInvoiceID, 
		'Bill To: '+dbo.vfToString(ARCM.Name)+
			' - $'+CONVERT(varchar(15), CONVERT(MONEY, SUM(CASE WHEN SMWorkCompleted.NoCharge='Y' THEN 0 ELSE SMWorkCompleted.PriceTotal END)),1) Description
		FROM SMInvoice
		INNER JOIN HQCO ON HQCO.HQCo=SMInvoice.SMCo
		INNER JOIN SMInvoiceSession ON SMInvoiceSession.SMInvoiceID=SMInvoice.SMInvoiceID
		INNER JOIN SMWorkCompleted ON SMInvoice.SMInvoiceID=SMWorkCompleted.SMInvoiceID
		LEFT JOIN ARCM ON HQCO.CustGroup=ARCM.CustGroup AND ARCM.Customer=SMInvoice.BillToARCustomer
		WHERE SMInvoice.SMCo = @SMCo 
			AND SMInvoiceSession.SMSessionID = @SMSessionID
		GROUP BY SMInvoice.BillToARCustomer, ARCM.Name,
			SMInvoice.SMInvoiceID, 
			SMInvoice.Invoice;

		RETURN 0
	END TRY
	BEGIN CATCH
		SET @msg = ERROR_MESSAGE()
		RETURN 1
	END CATCH
END
GO
GRANT EXECUTE ON  [dbo].[vspSMBillingInvoiceList] TO [public]
GO
