SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 9/20/09
-- Description:	Returns the PRMyTimesheets that are ready to send
-- =============================================
CREATE PROCEDURE [dbo].[vspPRMyTimesheetSendLoad]
	(@PRCo bCompany, @PRGroup bGroup, @IncludeThroughStartDate bDate)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT EntryEmployee, StartDate, FullName AS EmployeeName, Sheet, PersonalTimesheet, CreatedBy, CreatedOn, CASE [Status] WHEN 2 THEN 'Ready to send' WHEN 3 THEN 'Send Error' END AS [Status], ErrorMessage
	FROM PRMyTimesheet WITH (NOLOCK)
		INNER JOIN PREHFullName WITH (NOLOCK) ON PRMyTimesheet.PRCo = PREHFullName.PRCo 
			AND PRMyTimesheet.EntryEmployee = PREHFullName.Employee
	WHERE PRMyTimesheet.PRCo = @PRCo 
		AND (PRMyTimesheet.StartDate <= @IncludeThroughStartDate OR @IncludeThroughStartDate IS NULL)
		AND PRMyTimesheet.[Status] BETWEEN 2 AND 3
		AND PREHFullName.PRGroup = @PRGroup
END

GO
GRANT EXECUTE ON  [dbo].[vspPRMyTimesheetSendLoad] TO [public]
GO
