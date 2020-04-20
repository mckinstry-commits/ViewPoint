SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 7/23/09
-- Description:	Gets the header record from vPRMyTimesheet
-- =============================================
CREATE PROCEDURE [dbo].[vpspPRMyForemanTimeSheetGet]
	(@Key_PRCo bCompany, @Key_EntryEmployee bEmployee, @CurrentVPUser bVPUserName)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF EXISTS(SELECT TOP 1 1 FROM DDUP WHERE VPUserName = @CurrentVPUser AND MyTimesheetRole > 1)
	BEGIN
		EXEC vpspPRMyTimeSheetGet 'N', @Key_PRCo, @Key_EntryEmployee
	END
	ELSE
	BEGIN
		DECLARE @errMsg AS VARCHAR(MAX)
		SET @errMsg = 'You are not setup as a foreman in V6. Run the VA User Profile form to set user: ' + @CurrentVPUser + ' as a foreman.'
		RAISERROR(@errMsg, 16, 1)
		GOTO vspExit
	END
	
	vspExit:
END


GO
GRANT EXECUTE ON  [dbo].[vpspPRMyForemanTimeSheetGet] TO [VCSPortal]
GO
