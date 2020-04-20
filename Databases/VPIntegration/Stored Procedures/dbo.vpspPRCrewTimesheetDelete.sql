SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Chris Gall
-- Create date: 4/11/12
-- Description:	Deletes the Crew Timesheet detail record
-- =============================================
CREATE PROCEDURE [dbo].[vpspPRCrewTimesheetDelete]
	(@Original_Key_PRCo bCompany, @Original_Key_Crew varchar(10), @Original_Key_PostDate bDate, @Original_Key_SheetNum int)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @isLocked AS BIT
	
	SELECT 
		@isLocked = CASE WHEN PRRH.[Status] = 1 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END
	FROM [dbo].[PRRH] WITH (NOLOCK)
	WHERE
		PRRH.PRCo = @Original_Key_PRCo 
		AND PRRH.Crew = @Original_Key_Crew
		AND PRRH.PostDate = @Original_Key_PostDate
		AND PRRH.SheetNum = @Original_Key_SheetNum

	IF @isLocked = 1
	BEGIN
		RAISERROR('This crew time sheet is locked down. To delete records change the time sheet''s status to "Not Completed".', 16, 1)
	END
	ELSE
	BEGIN
		DELETE FROM 
			[dbo].[PRRH]
		WHERE 
			PRRH.PRCo = @Original_Key_PRCo 
			AND PRRH.Crew = @Original_Key_Crew
			AND PRRH.PostDate = @Original_Key_PostDate
			AND PRRH.SheetNum = @Original_Key_SheetNum
    END
END

GO
GRANT EXECUTE ON  [dbo].[vpspPRCrewTimesheetDelete] TO [VCSPortal]
GO
