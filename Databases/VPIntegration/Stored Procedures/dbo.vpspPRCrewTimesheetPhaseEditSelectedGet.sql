SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Chris Gall
-- Create date: 4/26/12
-- Description:	Gets selected phases for the Crew Timesheet Edit Phases dialog
-- =============================================
CREATE PROCEDURE [dbo].[vpspPRCrewTimesheetPhaseEditSelectedGet]
	(@Key_PRCo bCompany, @Key_Crew varchar(10), @Key_PostDate bDate, @Key_SheetNum SMALLINT)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @JCCo as bCompany, @Job as bJob
	
	-- Get the JCCo, Job and PhaseGroup for the crew timesheet
	SELECT 
		 @JCCo = JCCo
		,@Job = Job
	FROM
		PRRH
	WHERE
		PRCo = @Key_PRCo
		AND Crew = @Key_Crew
		AND PostDate = @Key_PostDate
		AND SheetNum = @Key_SheetNum

	SELECT 1 AS Id, PRRH.Phase1 AS Phase, JCJP.[Description] FROM PRRH
		LEFT JOIN JCJP JCJP ON JCJP.Phase = PRRH.Phase1 AND JCJP.JCCo = @JCCo AND JCJP.Job = @Job
		WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND PostDate = @Key_PostDate AND SheetNum = @Key_SheetNum 
	UNION
	SELECT 2 AS Id, PRRH.Phase2 AS Phase, JCJP.[Description] FROM PRRH
		LEFT JOIN JCJP JCJP ON JCJP.Phase = PRRH.Phase2 AND JCJP.JCCo = @JCCo AND JCJP.Job = @Job
		WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND PostDate = @Key_PostDate AND SheetNum = @Key_SheetNum 
	UNION
	SELECT 3 AS Id, PRRH.Phase3 AS Phase, JCJP.[Description] FROM PRRH
		LEFT JOIN JCJP JCJP ON JCJP.Phase = PRRH.Phase3 AND JCJP.JCCo = @JCCo AND JCJP.Job = @Job
		WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND PostDate = @Key_PostDate AND SheetNum = @Key_SheetNum 
	UNION
	SELECT 4 AS Id, PRRH.Phase4 AS Phase, JCJP.[Description] FROM PRRH
		LEFT JOIN JCJP JCJP ON JCJP.Phase = PRRH.Phase4 AND JCJP.JCCo = @JCCo AND JCJP.Job = @Job
		WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND PostDate = @Key_PostDate AND SheetNum = @Key_SheetNum 
	UNION
	SELECT 5 AS Id, PRRH.Phase5 AS Phase, JCJP.[Description] FROM PRRH
		LEFT JOIN JCJP JCJP ON JCJP.Phase = PRRH.Phase5 AND JCJP.JCCo = @JCCo AND JCJP.Job = @Job
		WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND PostDate = @Key_PostDate AND SheetNum = @Key_SheetNum 
	UNION
	SELECT 6 AS Id, PRRH.Phase6 AS Phase, JCJP.[Description] FROM PRRH
		LEFT JOIN JCJP JCJP ON JCJP.Phase = PRRH.Phase6 AND JCJP.JCCo = @JCCo AND JCJP.Job = @Job
		WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND PostDate = @Key_PostDate AND SheetNum = @Key_SheetNum 
	UNION
	SELECT 7 AS Id, PRRH.Phase7 AS Phase, JCJP.[Description] FROM PRRH
		LEFT JOIN JCJP JCJP ON JCJP.Phase = PRRH.Phase7 AND JCJP.JCCo = @JCCo AND JCJP.Job = @Job
		WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND PostDate = @Key_PostDate AND SheetNum = @Key_SheetNum 
	UNION
	SELECT 8 AS Id, PRRH.Phase8 AS Phase, JCJP.[Description] FROM PRRH
		LEFT JOIN JCJP JCJP ON JCJP.Phase = PRRH.Phase8 AND JCJP.JCCo = @JCCo AND JCJP.Job = @Job
		WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND PostDate = @Key_PostDate AND SheetNum = @Key_SheetNum 
		
END

GO
GRANT EXECUTE ON  [dbo].[vpspPRCrewTimesheetPhaseEditSelectedGet] TO [VCSPortal]
GO
