SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 4/15/11
-- Description:	Creates backups of all the work completed records that are a part of a session
-- Modified:    4/17/13  JVH TFS-44860 Modified for invoice detail changes
-- =============================================
CREATE PROCEDURE [dbo].[vspSMSessionBackupWorkCompleted]
	@SMSessionID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--Update SMWorkComplete records IsBackup so that it will copy/overwrite all backup detail records
	--We only backup the records that don't currently have backups
	UPDATE dbo.SMWorkCompleted
	SET IsSession = 1
	WHERE 
		EXISTS
		(
			SELECT 1 
			FROM dbo.vSMInvoiceSession
				INNER JOIN dbo.vSMInvoice ON vSMInvoiceSession.SMInvoiceID = vSMInvoice.SMInvoiceID
				INNER JOIN dbo.vSMInvoiceDetail ON vSMInvoice.SMCo = vSMInvoiceDetail.SMCo AND vSMInvoice.Invoice = vSMInvoiceDetail.Invoice
				LEFT JOIN dbo.vSMWorkCompletedDetail ON vSMInvoiceDetail.SMCo = vSMWorkCompletedDetail.SMCo AND vSMInvoiceDetail.WorkOrder = vSMWorkCompletedDetail.WorkOrder AND vSMInvoiceDetail.WorkCompleted = vSMWorkCompletedDetail.WorkCompleted AND vSMWorkCompletedDetail.IsSession = 1
			WHERE vSMInvoiceSession.SMSessionID = @SMSessionID AND SMWorkCompleted.SMCo = vSMInvoiceDetail.SMCo AND SMWorkCompleted.WorkOrder = vSMInvoiceDetail.WorkOrder AND SMWorkCompleted.WorkCompleted = vSMInvoiceDetail.WorkCompleted AND vSMWorkCompletedDetail.SMWorkCompletedID IS NULL
		)

	RETURN 0
END



GO
GRANT EXECUTE ON  [dbo].[vspSMSessionBackupWorkCompleted] TO [public]
GO
