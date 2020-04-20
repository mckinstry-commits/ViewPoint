SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 7/14/09
-- Modified:	DAN SO 01/10/2013 - D-06482/140623 - same factor different earn codes causing displayed values to use last earn code
-- Description:	Returns the total amount of hours on a time sheet by factor
-- =============================================
CREATE FUNCTION [dbo].[vpfPRMyTimeSheetEntryTotalHoursByFactor]
	(@Key_PRCo bCompany, @Key_EntryEmployee bEmployee, @Key_StartDate bDate, @Key_Sheet SMALLINT, @Factor bRate)
RETURNS bHrs
AS
BEGIN
	DECLARE @TotalHoursByFactor bHrs
	SELECT @TotalHoursByFactor = SUM(ISNULL([PRMyTimesheetDetail].[DayOne], 0))
		 + SUM(ISNULL([PRMyTimesheetDetail].[DayTwo], 0))
		 + SUM(ISNULL([PRMyTimesheetDetail].[DayThree], 0))
		 + SUM(ISNULL([PRMyTimesheetDetail].[DayFour], 0))
		 + SUM(ISNULL([PRMyTimesheetDetail].[DayFive], 0))
		 + SUM(ISNULL([PRMyTimesheetDetail].[DaySix], 0))
		 + SUM(ISNULL([PRMyTimesheetDetail].[DaySeven], 0))
	FROM
		PRMyTimesheetDetail
		JOIN PREC WITH (NOLOCK) ON PREC.PRCo = PRMyTimesheetDetail.PRCo AND PREC.EarnCode = PRMyTimesheetDetail.EarnCode
	WHERE [PRMyTimesheetDetail].[PRCo] = @Key_PRCo AND
		[PRMyTimesheetDetail].[EntryEmployee] = @Key_EntryEmployee AND
		[PRMyTimesheetDetail].[StartDate] = @Key_StartDate AND
		[PRMyTimesheetDetail].[Sheet] = @Key_Sheet AND 
		[PREC].[Factor] = @Factor
	GROUP BY 
		[PRMyTimesheetDetail].[PRCo], 
		[PRMyTimesheetDetail].[EntryEmployee], 
		[PRMyTimesheetDetail].[StartDate], 
		[PRMyTimesheetDetail].[Sheet], 
		--[PRMyTimesheetDetail].[EarnCode], -- D-06482/140623 --
		[PREC].[Factor]
	
	RETURN ISNULL(@TotalHoursByFactor, 0)
END


GO
GRANT EXECUTE ON  [dbo].[vpfPRMyTimeSheetEntryTotalHoursByFactor] TO [public]
GO
