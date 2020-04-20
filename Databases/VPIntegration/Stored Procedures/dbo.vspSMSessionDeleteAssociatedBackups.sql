SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 4/15/11
-- Description:	Deletes all the backup records for a given session.
-- =============================================
CREATE PROCEDURE [dbo].[vspSMSessionDeleteAssociatedBackups]
	@SMSessionID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @WorkCompletedBackupsToDelete TABLE (SMWorkCompletedID bigint)

	--First retrieve all work completed records that have backup for the given session.
	INSERT @WorkCompletedBackupsToDelete
	SELECT SMWorkCompletedID
	FROM SMWorkCompleted
	WHERE SMSessionID = @SMSessionID OR BackupSMSessionID = @SMSessionID

	DELETE dbo.SMWorkCompletedDetail
	FROM dbo.SMWorkCompletedDetail
		INNER JOIN @WorkCompletedBackupsToDelete WorkCompletedBackupsToDelete ON SMWorkCompletedDetail.SMWorkCompletedID = WorkCompletedBackupsToDelete.SMWorkCompletedID
	WHERE IsSession = 1
END

GO
GRANT EXECUTE ON  [dbo].[vspSMSessionDeleteAssociatedBackups] TO [public]
GO
