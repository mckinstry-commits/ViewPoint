SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 6/24/09
-- Description:	Deletes the detail record from vPRMyTimesheetDetail
-- =============================================
CREATE PROCEDURE [dbo].[vpspPRMyTimeSheetEntryDelete]
	(@Original_Key_PRCo bCompany, @Original_Key_EntryEmployee bEmployee, @Original_Key_StartDate bDate, @Original_Key_Sheet SMALLINT, @Original_Key_Seq_Seq SMALLINT, @RecordCanBeDeleted BIT = 0)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF @RecordCanBeDeleted = 0 AND dbo.vpIsMyTimeSheetInStatus(@Original_Key_PRCo, @Original_Key_EntryEmployee, @Original_Key_StartDate, @Original_Key_Sheet, 1) = 1
	BEGIN
		RAISERROR('This time sheet is locked down. To delete records change the time sheet''s status to "Not Locked".', 16, 1)
	END
	ELSE
	BEGIN
		DELETE FROM [dbo].[PRMyTimesheetDetail]
		WHERE [PRCo] = @Original_Key_PRCo AND [EntryEmployee] = @Original_Key_EntryEmployee AND [StartDate] = @Original_Key_StartDate AND [Sheet] = @Original_Key_Sheet AND [Seq] = @Original_Key_Seq_Seq
    END
END


GO
GRANT EXECUTE ON  [dbo].[vpspPRMyTimeSheetEntryDelete] TO [VCSPortal]
GO
