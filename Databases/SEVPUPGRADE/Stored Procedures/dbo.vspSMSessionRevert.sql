SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 4/15/11
-- Description:	Reverts all the records for a given session.
-- Modified:    09/20/2011 EricV - Create temporary link in SMMyTimesheetLink to allow delete of posted labor records.
-- =============================================
CREATE PROCEDURE [dbo].[vspSMSessionRevert]
	@SMSessionID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--First retrieve all work completed records that have backups for the given session.
	--If we are only reverting records that are part of actual invoices then we narrow the list down.
	DECLARE @WorkCompletedToRevert TABLE (SMWorkCompletedID bigint)

	--Grab all the wc records currently part of the existing invoice
	INSERT @WorkCompletedToRevert
	SELECT SMWorkCompletedID
	FROM dbo.SMWorkCompleted
		INNER JOIN dbo.SMInvoice ON SMWorkCompleted.SMInvoiceID = SMInvoice.SMInvoiceID
	WHERE SMSessionID = @SMSessionID AND SMInvoice.Invoiced = 1

	--Grab all the wc records that used to be part of the existing invoice
	INSERT @WorkCompletedToRevert
	SELECT SMWorkCompletedID
	FROM dbo.SMWorkCompleted
		INNER JOIN dbo.SMInvoice ON SMWorkCompleted.BackupSMInvoiceID = SMInvoice.SMInvoiceID
	WHERE BackupSMSessionID = @SMSessionID AND SMInvoice.Invoiced = 1

	--Set the update in progress to true for the Payroll related records	
	UPDATE SMMyTimesheetLink
	SET UpdateInProgress = 1
	FROM dbo.SMMyTimesheetLink
		INNER JOIN @WorkCompletedToRevert WorkCompletedToRevert ON SMMyTimesheetLink.SMWorkCompletedID = WorkCompletedToRevert.SMWorkCompletedID

	UPDATE vSMBC
	SET UpdateInProgress = 1
	FROM dbo.vSMBC
		INNER JOIN @WorkCompletedToRevert WorkCompletedToRevert ON vSMBC.SMWorkCompletedID = WorkCompletedToRevert.SMWorkCompletedID

	-- Find the labor records that have already been posted.
	DECLARE @ProcessedLaborRecords TABLE (SMWorkCompletedID bigint)

	INSERT @ProcessedLaborRecords
	SELECT SMWorkCompleted.SMWorkCompletedID
	FROM SMWorkCompleted
	INNER JOIN SMWorkCompletedLabor ON SMWorkCompletedLabor.SMWorkCompletedID=SMWorkCompleted.SMWorkCompletedID
	INNER JOIN @WorkCompletedToRevert WorkCompletedToRevert ON SMWorkCompleted.SMWorkCompletedID = WorkCompletedToRevert.SMWorkCompletedID
	LEFT JOIN vSMMyTimesheetLink ON vSMMyTimesheetLink.SMWorkCompletedID = SMWorkCompleted.SMWorkCompletedID
	LEFT JOIN vSMBC ON vSMBC.SMWorkCompletedID = SMWorkCompleted.SMWorkCompletedID
	WHERE SMWorkCompleted.Type=2 
	AND vSMMyTimesheetLink.SMWorkCompletedID IS NULL
	AND vSMBC.SMWorkCompletedID IS NULL
	
	-- Create a temporary link with UpdateInProcess set to 1 so the update trigger will allow them to be updated.
	INSERT vSMMyTimesheetLink (SMCo, PRCo, WorkOrder, Scope, WorkCompleted, SMWorkCompletedID, EntryEmployee, Employee, StartDate, DayNumber, Sheet, Seq, UpdateInProgress)
	SELECT SMWorkCompleted.SMCo, SMTechnician.PRCo, SMWorkCompleted.WorkOrder, SMWorkCompleted.Scope, SMWorkCompleted.WorkCompleted, SMWorkCompleted.SMWorkCompletedID, 
			SMTechnician.Employee, SMTechnician.Employee, SMWorkCompleted.Date, 1, 1, 1, 1
	FROM SMWorkCompleted
	INNER JOIN SMTechnician ON SMTechnician.SMCo=SMWorkCompleted.SMCo AND SMTechnician.Technician=SMWorkCompleted.Technician
	INNER JOIN SMWorkCompletedLabor ON SMWorkCompletedLabor.SMWorkCompletedID=SMWorkCompleted.SMWorkCompletedID
	INNER JOIN @ProcessedLaborRecords ProcessedLaborRecords ON SMWorkCompleted.SMWorkCompletedID = ProcessedLaborRecords.SMWorkCompletedID
	
	--Get rid of the current records
	DELETE SMWorkCompletedDetail
	FROM dbo.SMWorkCompletedDetail
		INNER JOIN @WorkCompletedToRevert WorkCompletedToRevert ON SMWorkCompletedDetail.SMWorkCompletedID = WorkCompletedToRevert.SMWorkCompletedID
	WHERE IsSession = 0

	--Do the actual revert
	UPDATE SMWorkCompletedDetail
	SET IsSession = 0
	FROM dbo.SMWorkCompletedDetail
		INNER JOIN @WorkCompletedToRevert WorkCompletedToRevert ON SMWorkCompletedDetail.SMWorkCompletedID = WorkCompletedToRevert.SMWorkCompletedID

	UPDATE vSMWorkCompleted
	SET CostsCaptured = 1
	FROM dbo.vSMWorkCompleted
		INNER JOIN @WorkCompletedToRevert WorkCompletedToRevert ON vSMWorkCompleted.SMWorkCompletedID = WorkCompletedToRevert.SMWorkCompletedID
	WHERE vSMWorkCompleted.InitialCostsCaptured = 1

	--Backup the records again		
	EXEC dbo.vspSMSessionBackupWorkCompleted @SMSessionID = @SMSessionID
	
	--Set the update in progress to false for the Payroll related records
	UPDATE SMMyTimesheetLink
	SET UpdateInProgress = 0
	FROM dbo.SMMyTimesheetLink
		INNER JOIN @WorkCompletedToRevert WorkCompletedToRevert ON SMMyTimesheetLink.SMWorkCompletedID = WorkCompletedToRevert.SMWorkCompletedID
		
	UPDATE vSMBC
	SET UpdateInProgress = 0
	FROM dbo.vSMBC
		INNER JOIN @WorkCompletedToRevert WorkCompletedToRevert ON vSMBC.SMWorkCompletedID = WorkCompletedToRevert.SMWorkCompletedID

	-- Delete the temporary link.		
	DELETE SMMyTimesheetLink
	FROM SMMyTimesheetLink
	INNER JOIN @ProcessedLaborRecords ProcessedLaborRecords ON SMMyTimesheetLink.SMWorkCompletedID = ProcessedLaborRecords.SMWorkCompletedID
	
END



GO
GRANT EXECUTE ON  [dbo].[vspSMSessionRevert] TO [public]
GO
