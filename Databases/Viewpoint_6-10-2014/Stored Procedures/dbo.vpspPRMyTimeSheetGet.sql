SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 6/24/09
-- Description:	Gets the header record from vPRMyTimesheet
-- =============================================
CREATE PROCEDURE dbo.vpspPRMyTimeSheetGet
	(@PersonalTimeSheet bYN, @Key_PRCo bCompany, @Key_EntryEmployee bEmployee, @Key_StartDate bDate = NULL, @Key_Sheet SMALLINT = NULL, @Status TINYINT = NULL)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	SELECT 
		PRMyTimesheet.PRCo AS Key_PRCo
		,PRMyTimesheet.EntryEmployee AS Key_EntryEmployee
		,PRMyTimesheet.StartDate AS Key_StartDate
		,CAST(PRMyTimesheet.Sheet AS VARCHAR) AS Key_Sheet
		,CASE WHEN PRMyTimesheet.[Status] = 1 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS [Status]
		,CAST(pvPRStatusTypes.StatusDescription AS VARCHAR) AS StatusDescription
		,PRMyTimesheet.PersonalTimesheet AS PersonalTimeSheet
		,PRMyTimesheet.CreatedOn
		,PRMyTimesheet.CreatedBy
		,PREH.Shift AS ShiftDefault
		,CASE WHEN PRCT.JobCraft IS NULL THEN PREH.Craft ELSE PRCT.JobCraft END AS CraftDefault --Reciprocal agreement Craft
		,CASE WHEN PRCT.JobCraft IS NULL THEN PREH.Class ELSE NULL END AS ClassDefault --Reciprocal agreement Craft
		,PREH.JCCo AS JCCoDefault
		,PREH.Job AS JobDefault
		,CASE WHEN IncldRemoteTC = 'Y' THEN PREH.EarnCode ELSE NULL END AS EarnCodeDefault
		,PRMyTimesheet.Notes
		,PRMyTimesheet.UniqueAttchID
		,PRMyTimesheet.KeyID
		,dbo.vpfPRMyTimeSheetEntryTotalHours(PRMyTimesheet.PRCo, PRMyTimesheet.EntryEmployee, PRMyTimesheet.StartDate, PRMyTimesheet.Sheet) as TotalHours
		,dbo.vpfPRMyTimeSheetEntryTotalHoursByFactor(PRMyTimesheet.PRCo, PRMyTimesheet.EntryEmployee, PRMyTimesheet.StartDate, PRMyTimesheet.Sheet, 1.0) as TotalRegularHours
		,dbo.vpfPRMyTimeSheetEntryTotalHoursByFactor(PRMyTimesheet.PRCo, PRMyTimesheet.EntryEmployee, PRMyTimesheet.StartDate, PRMyTimesheet.Sheet, 1.5) as TotalOverTimeHours
		,dbo.vpfPRMyTimeSheetEntryTotalHoursByFactor(PRMyTimesheet.PRCo, PRMyTimesheet.EntryEmployee, PRMyTimesheet.StartDate, PRMyTimesheet.Sheet, 2.0) as TotalDoubleTimeHours
		,CAST(NULL AS SMALLDATETIME) AS CopyFromStartDate
		,CAST(NULL AS VARCHAR) AS CopyFromSheet
		,CAST(0 AS BIT) AS CopyHours
		,CAST(NULL AS VARCHAR) As CopyHoursDescription
	FROM 
		PRMyTimesheet WITH (NOLOCK)
		LEFT JOIN pvPRStatusTypes WITH (NOLOCK) ON pvPRStatusTypes.[Status] = PRMyTimesheet.[Status]
		LEFT JOIN PREH WITH (NOLOCK) ON PREH.PRCo = PRMyTimesheet.PRCo AND PREH.Employee = PRMyTimesheet.EntryEmployee 
		LEFT JOIN PREC WITH (NOLOCK) ON PREH.PRCo = PREC.PRCo AND PREH.EarnCode = PREC.EarnCode
		LEFT JOIN JCJM WITH (NOLOCK) ON JCJM.JCCo = PREH.JCCo AND JCJM.Job = PREH.Job
		LEFT JOIN PRCT WITH (NOLOCK) ON PRCT.PRCo = PREH.PRCo AND PRCT.Craft = PREH.Craft AND PRCT.Template = JCJM.CraftTemplate AND RecipOpt = 'O'
	WHERE 
		PersonalTimesheet = @PersonalTimeSheet AND PRMyTimesheet.PRCo = @Key_PRCo AND PRMyTimesheet.EntryEmployee = @Key_EntryEmployee
		AND PRMyTimesheet.[Status] <= ISNULL(@Status, 1) -- Parameter for displaying time sheets that are not sent
		AND PRMyTimesheet.StartDate = ISNULL(@Key_StartDate, PRMyTimesheet.StartDate) AND PRMyTimesheet.Sheet = ISNULL(@Key_Sheet, PRMyTimesheet.Sheet) --Paramters for returning one row
		
END

GO
GRANT EXECUTE ON  [dbo].[vpspPRMyTimeSheetGet] TO [VCSPortal]
GO
