SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 6/24/09
-- Modified: Chris G 8/7/12 TK-16896 | B-07454 - Added KeyID
-- Description:	Gets the detail record from vPRMyTimesheetDetail
-- =============================================
CREATE PROCEDURE [dbo].[vpspPRMyTimeSheetEntryGet]
	(@PersonalTimeSheet bYN, @Key_PRCo bCompany, @Key_EntryEmployee bEmployee, @Key_StartDate bDate, @Key_Sheet SMALLINT, @ShortDatePattern VARCHAR(20), @Key_Seq_Seq TINYINT = NULL, 
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

	SELECT @DayOneHeaderText = @Key_StartDate
		,@DayOneHeaderText_Format = '{0:ddd ' + REPLACE(REPLACE(REPLACE(@ShortDatePattern,'/y',''),'y/',''),'y','') + '}'
		,@DayTwoHeaderText = DATEADD(DAY, 1, @Key_StartDate)
		,@DayTwoHeaderText_Format = @DayOneHeaderText_Format
		,@DayThreeHeaderText = DATEADD(DAY, 2, @Key_StartDate)
		,@DayThreeHeaderText_Format = @DayOneHeaderText_Format
		,@DayFourHeaderText = DATEADD(DAY, 3, @Key_StartDate)
		,@DayFourHeaderText_Format = @DayOneHeaderText_Format
		,@DayFiveHeaderText = DATEADD(DAY, 4, @Key_StartDate)
		,@DayFiveHeaderText_Format = @DayOneHeaderText_Format
		,@DaySixHeaderText = DATEADD(DAY, 5, @Key_StartDate)
		,@DaySixHeaderText_Format = @DayOneHeaderText_Format
		,@DaySevenHeaderText = DATEADD(DAY, 6, @Key_StartDate)
		,@DaySevenHeaderText_Format = @DayOneHeaderText_Format

	SELECT @PersonalTimeSheet AS PersonalTimeSheet
		  ,PRMyTimesheetDetail.[PRCo] AS Key_PRCo
		  ,[EntryEmployee] AS Key_EntryEmployee
		  ,[StartDate] AS Key_StartDate
		  ,[Sheet] AS Key_Sheet
		  ,[Seq] AS Key_Seq_Seq 
		  ,PRMyTimesheetDetail.[Employee]
		  ,FullName AS EmployeeName
		  ,PRMyTimesheetDetail.[JCCo]
		  ,HQCO.Name AS CompanyName
		  ,PRMyTimesheetDetail.[Job]
		  ,JCJM.[Description] AS JobDescription
		  ,PRMyTimesheetDetail.[PhaseGroup]
		  ,[Phase]
		  ,dbo.vfValidPhaseDesc(PRMyTimesheetDetail.[JCCo], PRMyTimesheetDetail.[Job], [Phase], PRMyTimesheetDetail.[PhaseGroup]) AS PhaseDescription
		  ,PRMyTimesheetDetail.[EarnCode]
		  ,PREC.[Description] AS EarnCodeDescription
		  ,PRMyTimesheetDetail.[Craft]
		  ,PRCM.[Description] AS CraftDescription
		  ,PRMyTimesheetDetail.[Class]
		  ,PRCC.[Description] AS ClassDescription
		  ,[Shift]
		  ,[DayOne]
		  ,[DayTwo]
		  ,[DayThree]
		  ,[DayFour]
		  ,[DayFive]
		  ,[DaySix]
		  ,[DaySeven]
		  ,[CreatedBy]
		  ,[CreatedOn]
		  ,[Approved]
		  ,dbo.vpfYesNo([Approved]) AS ApprovedDescription
		  ,[ApprovedBy]
		  ,[ApprovedOn]
		  ,CASE WHEN Approved = 'Y' THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS BoolApproved
		  ,[Memo]
		  ,@ShortDatePattern AS ShortDatePattern
		  ,PRMyTimesheetDetail.KeyID
	  FROM [dbo].[PRMyTimesheetDetail] WITH (NOLOCK)
		LEFT JOIN HQCO WITH (NOLOCK) ON PRMyTimesheetDetail.JCCo = HQCO.HQCo
		LEFT JOIN JCJM WITH (NOLOCK) ON PRMyTimesheetDetail.JCCo = JCJM.JCCo AND PRMyTimesheetDetail.Job = JCJM.Job
		LEFT JOIN PREC WITH (NOLOCK) ON PRMyTimesheetDetail.PRCo = PREC.PRCo AND PRMyTimesheetDetail.EarnCode = PREC.EarnCode
		LEFT JOIN PRCM WITH (NOLOCK) ON PRMyTimesheetDetail.PRCo = PRCM.PRCo AND PRMyTimesheetDetail.Craft = PRCM.Craft
		LEFT JOIN PRCC WITH (NOLOCK) ON PRMyTimesheetDetail.PRCo = PRCC.PRCo AND PRMyTimesheetDetail.Craft = PRCC.Craft AND PRMyTimesheetDetail.Class = PRCC.Class
		LEFT JOIN PREHFullName WITH (NOLOCK) ON PRMyTimesheetDetail.PRCo = PREHFullName.PRCo AND PRMyTimesheetDetail.Employee = PREHFullName.Employee
	  WHERE PRMyTimesheetDetail.[LineType] = 'J' --0 is the job line type which is the only line type we are supporting in Connects right now
		AND PRMyTimesheetDetail.[PRCo] = @Key_PRCo AND [EntryEmployee] = @Key_EntryEmployee AND [StartDate] = @Key_StartDate AND [Sheet] = @Key_Sheet
		  AND [Seq] = ISNULL(@Key_Seq_Seq, Seq)  --Paramters for returning one row
		  order by PRMyTimesheetDetail.[Employee], PRMyTimesheetDetail.[Job], [Phase]
END


GO
GRANT EXECUTE ON  [dbo].[vpspPRMyTimeSheetEntryGet] TO [VCSPortal]
GO
