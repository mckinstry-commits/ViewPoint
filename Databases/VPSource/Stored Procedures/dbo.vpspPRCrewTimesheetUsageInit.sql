SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Chris Gall
-- Create date: 5/2/2012
-- Description:	Wraps V6 stored proc to: "Initialized equipment usage in bPRRQ based on the employee hours posted in bPRRE."
-- =============================================
CREATE PROCEDURE [dbo].[vpspPRCrewTimesheetUsageInit]
	(@Key_PRCo bCompany, @Key_Crew varchar(10), @Key_PostDate bDate, @Key_SheetNum SMALLINT)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @rcode INTEGER, @msg AS VARCHAR(255)

	EXEC @rcode = bspPRTSInitUsage @Key_PRCo, @Key_Crew, @Key_PostDate, @Key_SheetNum, @msg = @msg OUTPUT
	IF @rcode <> 0
	BEGIN
		SET @msg = 'Usage initialization failed - ' + @msg
		RAISERROR(@msg, 16, 1)
	END
END


GO
GRANT EXECUTE ON  [dbo].[vpspPRCrewTimesheetUsageInit] TO [VCSPortal]
GO
