SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Vaterlaus
-- Create date: 08/11/11
-- Description:	Delete a specific session or all sessions for a company if there
--              are no invoices in the session.
-- Modified:	5/30/13 - TFS-44858 Modified to support SM Invoice
-- =============================================
CREATE PROCEDURE dbo.vspSMSessionCleanup
	@SMSessionID int, @msg varchar(255) = NULL OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	--Backup work completed records are no longer needed
	DELETE vSMWorkCompletedDetail
	FROM dbo.vSMInvoiceSession
		INNER JOIN dbo.vSMInvoice ON vSMInvoiceSession.SMInvoiceID = vSMInvoice.SMInvoiceID
		INNER JOIN dbo.vSMInvoiceDetail ON vSMInvoice.SMCo = vSMInvoiceDetail.SMCo AND vSMInvoice.Invoice = vSMInvoiceDetail.Invoice
		INNER JOIN dbo.vSMWorkCompletedDetail ON vSMInvoiceDetail.SMCo = vSMWorkCompletedDetail.SMCo AND vSMInvoiceDetail.WorkOrder = vSMWorkCompletedDetail.WorkOrder AND vSMInvoiceDetail.WorkCompleted = vSMWorkCompletedDetail.WorkCompleted
	WHERE vSMInvoiceSession.SMSessionID = @SMSessionID AND vSMWorkCompletedDetail.IsSession = 1

	--Invoice sessions can be deleted as long as the invoices that are in the session were processed
	DELETE vSMInvoiceSession
	FROM dbo.vSMInvoiceSession
		INNER JOIN dbo.vSMInvoice ON vSMInvoiceSession.SMInvoiceID = vSMInvoice.SMInvoiceID
	WHERE vSMInvoiceSession.SMSessionID = @SMSessionID AND vSMInvoice.Invoiced = 1

	--As long as no invoices are associated with the session then
	--the session can be deleted.
	IF NOT EXISTS
	(
		SELECT 1
		FROM dbo.vSMInvoiceSession
		WHERE SMSessionID = @SMSessionID
	)
	BEGIN
		DELETE dbo.vSMSession
		WHERE SMSessionID = @SMSessionID
	END
END
GO
GRANT EXECUTE ON  [dbo].[vspSMSessionCleanup] TO [public]
GO
