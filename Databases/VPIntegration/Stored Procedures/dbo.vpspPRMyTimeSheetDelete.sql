SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 6/24/09
-- Description:	Deletes the header record from vPRMyTimesheet
-- =============================================
CREATE PROCEDURE [dbo].[vpspPRMyTimeSheetDelete]
	(@Original_Key_PRCo bCompany, @Original_Key_EntryEmployee bEmployee, @Original_Key_StartDate bDate, @Original_Key_Sheet VARCHAR(6))
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF dbo.vpIsMyTimeSheetInStatus(@Original_Key_PRCo, @Original_Key_EntryEmployee, @Original_Key_StartDate, @Original_Key_Sheet, 1) = 1
	BEGIN
		RAISERROR('This time sheet is locked down and not able to be deleted. To delete this time sheet change the status to "Unlocked"', 16, 1)
	END
	ELSE
	BEGIN
		--Delete the detail records first
		DELETE FROM [dbo].[PRMyTimesheetDetail]
		WHERE [PRCo] = @Original_Key_PRCo AND [EntryEmployee] = @Original_Key_EntryEmployee AND [StartDate] = @Original_Key_StartDate AND [Sheet] = @Original_Key_Sheet
	
		--Now delete the header record
		DELETE FROM [dbo].[PRMyTimesheet]
		WHERE PRCo = @Original_Key_PRCo AND [EntryEmployee] = @Original_Key_EntryEmployee AND StartDate = @Original_Key_StartDate AND Sheet = @Original_Key_Sheet
	END
END


GO
GRANT EXECUTE ON  [dbo].[vpspPRMyTimeSheetDelete] TO [VCSPortal]
GO
