SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Chris Gall
-- Create date: 4/16/2012
-- Modified: Chris G 8/7/12 TK-16896 | B-07454 - Added KeyID
-- Description:	Gets the detail record from PRRE
-- =============================================
CREATE PROCEDURE [dbo].[vpspPRCrewTimeSheetEmployeeGet]
	(@Key_PRCo bCompany, @Key_Crew varchar(10), @Key_PostDate bDate, @Key_SheetNum SMALLINT,
		-- NOTE: Header text type has to include Phase (bPhase varchar(20)) and Description(varchar(60)) + formatting
		@Phase1HeaderText varchar(100) = NULL OUTPUT,
		@Phase2HeaderText varchar(100) = NULL OUTPUT,
		@Phase3HeaderText varchar(100) = NULL OUTPUT,
		@Phase4HeaderText varchar(100) = NULL OUTPUT,
		@Phase5HeaderText varchar(100) = NULL OUTPUT,
		@Phase6HeaderText varchar(100) = NULL OUTPUT,
		@Phase7HeaderText varchar(100) = NULL OUTPUT,
		@Phase8HeaderText varchar(100) = NULL OUTPUT)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @JCCo bCompany, @Job bJob, @PhaseGroup bGroup

	-- Retreive the dynamic phase header text.  This is used
	-- to replace #PhaseX# in the pPortalDataGridColumns
	SELECT
		 @JCCo = JCCo
		,@Job = Job
		,@PhaseGroup = PhaseGroup
		,@Phase1HeaderText = Phase1
		,@Phase2HeaderText = Phase2
		,@Phase3HeaderText = Phase3
		,@Phase4HeaderText = Phase4
		,@Phase5HeaderText = Phase5
		,@Phase6HeaderText = Phase6
		,@Phase7HeaderText = Phase7
		,@Phase8HeaderText = Phase8
	FROM PRRH
	WHERE
		PRCo = @Key_PRCo
		AND Crew = @Key_Crew
		AND PostDate = @Key_PostDate
		AND SheetNum = @Key_SheetNum
		
	-- Add description to the headers such that description is pulled as a tooltip, which
	-- are formatted as [Header]{description:[Description]} (ex. "1-0102{description:Concrete Phase}")
	SELECT @Phase1HeaderText = @Phase1HeaderText + '{description:' +  JCJP.[Description] + '}' FROM JCJP WHERE Phase = @Phase1HeaderText AND JCCo = @JCCo AND Job = @Job AND PhaseGroup = @PhaseGroup
	SELECT @Phase2HeaderText = @Phase2HeaderText + '{description:' +  JCJP.[Description] + '}' FROM JCJP WHERE Phase = @Phase2HeaderText AND JCCo = @JCCo AND Job = @Job AND PhaseGroup = @PhaseGroup
	SELECT @Phase3HeaderText = @Phase3HeaderText + '{description:' +  JCJP.[Description] + '}' FROM JCJP WHERE Phase = @Phase3HeaderText AND JCCo = @JCCo AND Job = @Job AND PhaseGroup = @PhaseGroup
	SELECT @Phase4HeaderText = @Phase4HeaderText + '{description:' +  JCJP.[Description] + '}' FROM JCJP WHERE Phase = @Phase4HeaderText AND JCCo = @JCCo AND Job = @Job AND PhaseGroup = @PhaseGroup
	SELECT @Phase5HeaderText = @Phase5HeaderText + '{description:' +  JCJP.[Description] + '}' FROM JCJP WHERE Phase = @Phase5HeaderText AND JCCo = @JCCo AND Job = @Job AND PhaseGroup = @PhaseGroup
	SELECT @Phase6HeaderText = @Phase6HeaderText + '{description:' +  JCJP.[Description] + '}' FROM JCJP WHERE Phase = @Phase6HeaderText AND JCCo = @JCCo AND Job = @Job AND PhaseGroup = @PhaseGroup
	SELECT @Phase7HeaderText = @Phase7HeaderText + '{description:' +  JCJP.[Description] + '}' FROM JCJP WHERE Phase = @Phase7HeaderText AND JCCo = @JCCo AND Job = @Job AND PhaseGroup = @PhaseGroup
	SELECT @Phase8HeaderText = @Phase8HeaderText + '{description:' +  JCJP.[Description] + '}' FROM JCJP WHERE Phase = @Phase8HeaderText AND JCCo = @JCCo AND Job = @Job AND PhaseGroup = @PhaseGroup
		
	SELECT
		 PRRE.PRCo As Key_PRCo
		,PRRE.Crew AS Key_Crew
		,PRRE.PostDate As Key_PostDate
		,PRRE.SheetNum AS Key_SheetNum
		,PRRE.Employee AS Key_Employee
		,(PREH.LastName + ', ' + PREH.FirstName) AS EmployeeName
		,CAST(PRRE.LineSeq AS VARCHAR) AS Key_LineSeq -- user VARCHAR for '+' default
		,PRRE.Craft
		,PRRE.Class
		,PRRE.Craft AS CraftDefault		
		,PRRE.Class AS ClassDefault
		,PRRH.Phase1 AS PhaseTimeEntry1
		,PRRE.Phase1RegHrs	
		,PRRE.Phase1OTHrs
		,PRRE.Phase1DblHrs
		,PRRH.Phase2 AS PhaseTimeEntry2
		,PRRE.Phase2RegHrs	
		,PRRE.Phase2OTHrs
		,PRRE.Phase2DblHrs
		,PRRH.Phase3 AS PhaseTimeEntry3
		,PRRE.Phase3RegHrs	
		,PRRE.Phase3OTHrs
		,PRRE.Phase3DblHrs
		,PRRH.Phase4 AS PhaseTimeEntry4
		,PRRE.Phase4RegHrs	
		,PRRE.Phase4OTHrs
		,PRRE.Phase4DblHrs
		,PRRH.Phase5 AS PhaseTimeEntry5
		,PRRE.Phase5RegHrs	
		,PRRE.Phase5OTHrs
		,PRRE.Phase5DblHrs
		,PRRH.Phase6 AS PhaseTimeEntry6
		,PRRE.Phase6RegHrs	
		,PRRE.Phase6OTHrs
		,PRRE.Phase6DblHrs
		,PRRH.Phase7 AS PhaseTimeEntry7
		,PRRE.Phase7RegHrs	
		,PRRE.Phase7OTHrs
		,PRRE.Phase7DblHrs
		,PRRH.Phase8 AS PhaseTimeEntry8
		,PRRE.Phase8RegHrs	
		,PRRE.Phase8OTHrs
		,PRRE.Phase8DblHrs		
		,ISNULL(PRRE.TotalHrs, 0) AS TotalHrs
		,PRRE.KeyID
	FROM PRRE
	LEFT JOIN PRRH WITH (NOLOCK) ON PRRH.PRCo = @Key_PRCo AND PRRH.Crew = @Key_Crew AND PRRH.PostDate = @Key_PostDate AND PRRH.SheetNum = @Key_SheetNum
	LEFT JOIN PREH WITH (NOLOCK) ON PREH.PRCo = PRRE.PRCo AND PREH.Employee = PRRE.Employee
	WHERE
		PRRE.PRCo = @Key_PRCo
		AND PRRE.Crew = @Key_Crew
		AND PRRE.PostDate = @Key_PostDate
		AND PRRE.SheetNum = @Key_SheetNum
END


GO
GRANT EXECUTE ON  [dbo].[vpspPRCrewTimeSheetEmployeeGet] TO [VCSPortal]
GO
