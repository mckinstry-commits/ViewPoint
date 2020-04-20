SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 4/15/11
-- Description:	Creates backups of all the work completed records that are a part of a session
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
	WHERE SMSessionID = @SMSessionID AND SessionRecordExists = 0

	RETURN 0
END



GO
GRANT EXECUTE ON  [dbo].[vspSMSessionBackupWorkCompleted] TO [public]
GO
