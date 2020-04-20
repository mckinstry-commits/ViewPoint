SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 7/14/09
-- Modified: Chris G 8/7/12 TK-16896 | B-07454 - Added KeyID
-- Description:	Returns all the time card records that the logged in user is allowed to update/approve from PRMyTimesheetDetail
-- =============================================
CREATE PROCEDURE [dbo].[vpspPRMyTimeSheetApprovalDetailGet]
	(@StartDate bDate, @UserName bVPUserName, @InitalLoad BIT = 1, @ShortDatePattern VARCHAR(20), @Key_PRCo bCompany = NULL, @Key_EntryEmployee bEmployee = NULL, @Key_StartDate bDate = NULL, @Key_Sheet SMALLINT = NULL, @Key_Seq_Seq TINYINT = NULL, 
		@DayOneHeaderText bDate = NULL OUTPUT, 
		@DayOneHeaderText_Format VARCHAR(16) = NULL OUTPUT, 
		@DayTwoHeaderText bDate = NULL OUTPUT, 
		@DayTwoHeaderText_Format VARCHAR(16) = NULL OUTPUT, 
		@DayThreeHeaderText bDate = NULL OUTPUT, 
		@DayThreeHeaderText_Format VARCHAR(16) = NULL OUTPUT, 
		@DayFourHeaderText bDate = NULL OUTPUT, 
		@DayFourHeaderText_Format VARCHAR(16) = NULL OUTPUT, 
		@DayFiveHeaderText bDate = NULL OUTPUT, 
		@DayFiveHeaderText_Format VARCHAR(16) = NULL OUTPUT, 
		@DaySixHeaderText bDate = NULL OUTPUT, 
		@DaySixHeaderText_Format VARCHAR(16) = NULL OUTPUT, 
		@DaySevenHeaderText bDate = NULL OUTPUT,
		@DaySevenHeaderText_Format VARCHAR(16) = NULL OUTPUT)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT @DayOneHeaderText = @StartDate
		,@DayOneHeaderText_Format = '{0:ddd ' + REPLACE(REPLACE(REPLACE(@ShortDatePattern,'/y',''),'y/',''),'y','') + '}'
		,@DayTwoHeaderText = DATEADD(DAY, 1, @StartDate)
		,@DayTwoHeaderText_Format = @DayOneHeaderText_Format
		,@DayThreeHeaderText = DATEADD(DAY, 2, @StartDate)
		,@DayThreeHeaderText_Format = @DayOneHeaderText_Format
		,@DayFourHeaderText = DATEADD(DAY, 3, @StartDate)
		,@DayFourHeaderText_Format = @DayOneHeaderText_Format
		,@DayFiveHeaderText = DATEADD(DAY, 4, @StartDate)
		,@DayFiveHeaderText_Format = @DayOneHeaderText_Format
		,@DaySixHeaderText = DATEADD(DAY, 5, @StartDate)
		,@DaySixHeaderText_Format = @DayOneHeaderText_Format
		,@DaySevenHeaderText = DATEADD(DAY, 6, @StartDate)
		,@DaySevenHeaderText_Format = @DayOneHeaderText_Format;
		
	WITH TimeSheetEntriesThatCanBeApproved(PRCo, EntryEmployee, StartDate, Sheet, Seq)
	AS
	(
		SELECT DISTINCT PRCo, EntryEmployee, StartDate, Sheet, Seq
		FROM PRMyTimesheetDetailForApproval
			INNER JOIN HQRP ON PRMyTimesheetDetailForApproval.Reviewer = HQRP.Reviewer
		WHERE VPUserName = @UserName AND StartDate = @StartDate AND [Status] BETWEEN 1 AND 3
	)

	SELECT PRMyTimesheetDetail.PRCo AS Key_PRCo
		  ,PRMyTimesheetDetail.EntryEmployee AS Key_EntryEmployee
		  ,PRMyTimesheetDetail.StartDate AS Key_StartDate
		  ,PRMyTimesheetDetail.Sheet AS Key_Sheet
		  ,PRMyTimesheetDetail.Seq AS Key_Seq_Seq 
		  ,PRMyTimesheetDetail.Employee
		  ,FullName
		  ,PRMyTimesheetDetail.JCCo
		  ,HQCO.Name AS CompanyName
		  ,PRMyTimesheetDetail.Job
		  ,JCJM.[Description] AS JobDescription
		  ,PRMyTimesheetDetail.PhaseGroup
		  ,Phase
		  ,dbo.vfValidPhaseDesc(PRMyTimesheetDetail.JCCo, PRMyTimesheetDetail.Job, Phase, PRMyTimesheetDetail.PhaseGroup) AS PhaseDescription
		  ,PRMyTimesheetDetail.EarnCode
		  ,PREC.[Description] AS EarnCodeDescription
		  ,PRMyTimesheetDetail.Craft
		  ,PRCM.[Description] AS CraftDescription
		  ,PRMyTimesheetDetail.Class
		  ,PRCC.[Description] AS ClassDescription
		  ,PRMyTimesheetDetail.Shift
		  ,DayOne
		  ,DayTwo
		  ,DayThree
		  ,DayFour
		  ,DayFive
		  ,DaySix
		  ,DaySeven
		  ,CASE WHEN Approved = 'Y' THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS BoolApproved
		  ,Approved
		  ,dbo.vpfYesNo([Approved]) AS ApprovedDescription
		  ,ApprovedBy
		  ,ApprovedOn
		  ,DayOne + DayTwo + DayThree + DayFour + DayFive + DaySix + DaySeven AS TimeCardEntryTotal
		  ,@StartDate AS StartDate
		  ,@UserName AS UserName
		  ,CAST(1 AS BIT) AS RecordCanBeDeleted
		  ,@ShortDatePattern AS ShortDatePattern
		  ,PRMyTimesheetDetail.KeyID
	FROM PRMyTimesheetDetail LEFT JOIN HQCO WITH (NOLOCK) ON PRMyTimesheetDetail.JCCo = HQCO.HQCo
		LEFT JOIN JCJM WITH (NOLOCK) ON PRMyTimesheetDetail.JCCo = JCJM.JCCo AND PRMyTimesheetDetail.Job = JCJM.Job
		LEFT JOIN PREC WITH (NOLOCK) ON PRMyTimesheetDetail.PRCo = PREC.PRCo AND PRMyTimesheetDetail.EarnCode = PREC.EarnCode
		LEFT JOIN PRCM WITH (NOLOCK) ON PRMyTimesheetDetail.PRCo = PRCM.PRCo AND PRMyTimesheetDetail.Craft = PRCM.Craft
		LEFT JOIN PRCC WITH (NOLOCK) ON PRMyTimesheetDetail.PRCo = PRCC.PRCo AND PRMyTimesheetDetail.Craft = PRCC.Craft AND PRMyTimesheetDetail.Class = PRCC.Class
		LEFT JOIN PREHFullName WITH (NOLOCK) ON PRMyTimesheetDetail.PRCo = PREHFullName.PRCo AND PRMyTimesheetDetail.Employee = PREHFullName.Employee
	WHERE LineType = 'J' --Connects is only supporting the job line types right now
		AND ((@InitalLoad = 0 AND PRMyTimesheetDetail.PRCo = @Key_PRCo AND PRMyTimesheetDetail.EntryEmployee = @Key_EntryEmployee AND StartDate = @Key_StartDate AND Sheet = @Key_Sheet AND Seq = @Key_Seq_Seq) -- Returns a specific detail record
		OR (@InitalLoad = 1 
				AND EXISTS (SELECT TOP 1 1 
					FROM TimeSheetEntriesThatCanBeApproved
					WHERE PRMyTimesheetDetail.PRCo = TimeSheetEntriesThatCanBeApproved.PRCo
						AND PRMyTimesheetDetail.EntryEmployee = TimeSheetEntriesThatCanBeApproved.EntryEmployee
						AND PRMyTimesheetDetail.StartDate = TimeSheetEntriesThatCanBeApproved.StartDate
						AND PRMyTimesheetDetail.Sheet = TimeSheetEntriesThatCanBeApproved.Sheet
						AND PRMyTimesheetDetail.Seq = TimeSheetEntriesThatCanBeApproved.Seq)))
			-- Returns the time card entries that can be modified in the control
END


GO
GRANT EXECUTE ON  [dbo].[vpspPRMyTimeSheetApprovalDetailGet] TO [VCSPortal]
GO
