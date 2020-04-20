SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 7/14/09
-- Description:	Returns the total amount of hours on a time sheet
-- =============================================
CREATE FUNCTION [dbo].[vpfPRMyTimeSheetEntryTotalHours]
	(@Key_PRCo bCompany, @Key_EntryEmployee bEmployee, @Key_StartDate bDate, @Key_Sheet SMALLINT)
RETURNS bHrs
AS
BEGIN
	DECLARE @TotalHours bHrs
	SELECT 
		@TotalHours = SUM(ISNULL([PRMyTimesheetDetail].[DayOne], 0))
		 + SUM(ISNULL([PRMyTimesheetDetail].[DayTwo], 0))
		 + SUM(ISNULL([PRMyTimesheetDetail].[DayThree], 0)) 
		 + SUM(ISNULL([PRMyTimesheetDetail].[DayFour], 0))
		 + SUM(ISNULL([PRMyTimesheetDetail].[DayFive], 0)) 
		 + SUM(ISNULL([PRMyTimesheetDetail].[DaySix], 0))
		 + SUM(ISNULL([PRMyTimesheetDetail].[DaySeven], 0))
	FROM 
		[dbo].[PRMyTimesheetDetail]
	WHERE 
		[PRMyTimesheetDetail].[PRCo] = @Key_PRCo AND
		[PRMyTimesheetDetail].[EntryEmployee] = @Key_EntryEmployee AND
		[PRMyTimesheetDetail].[StartDate] = @Key_StartDate AND
		[PRMyTimesheetDetail].[Sheet] = @Key_Sheet
	GROUP BY 
		[PRMyTimesheetDetail].[PRCo]
		, [PRMyTimesheetDetail].[EntryEmployee]
		, [PRMyTimesheetDetail].[StartDate]
		, [PRMyTimesheetDetail].[Sheet]
	
	RETURN ISNULL(@TotalHours, 0)
END



GO
GRANT EXECUTE ON  [dbo].[vpfPRMyTimeSheetEntryTotalHours] TO [public]
GO
