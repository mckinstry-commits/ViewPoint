SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Chris Gall
-- Create date: 4/26/12
-- Description:	Gets all available phases for the Crew Timesheet Edit Phases dialog
-- =============================================
CREATE PROCEDURE [dbo].[vpspPRCrewTimesheetPhaseEditGet]
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
		
	-- Get the list of phases for the JCCo/Job
	SELECT
		 Phase
		,[Description]
	FROM
		JCJP
	WHERE
		JCCo = @JCCo
		AND Job = @Job
	ORDER BY
		Phase		
END

GO
GRANT EXECUTE ON  [dbo].[vpspPRCrewTimesheetPhaseEditGet] TO [VCSPortal]
GO
