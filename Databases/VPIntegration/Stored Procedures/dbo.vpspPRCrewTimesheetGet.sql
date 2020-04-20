SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Chris Gall
-- Create date: 4/11/12
-- Modified:  Chris G 8/7/12 TK-16896 | B-07454 - Added KeyID
-- Description:	Gets the Crew Timesheet List from PRRH
-- =============================================
CREATE PROCEDURE [dbo].[vpspPRCrewTimesheetGet]
	(@Key_PRCo bCompany, @Key_EntryEmployee bVPUserName, @Key_PostDate bDate = NULL, @Key_SheetNum SMALLINT = NULL, @Status TINYINT = NULL)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    SELECT
		PRRH.PRCo AS Key_PRCo
		,PRRH.Crew AS Key_Crew
		,PRCR.Description AS CrewDescription
		,PRRH.PostDate AS Key_PostDate
		,CAST(SheetNum AS VARCHAR) AS Key_SheetNum -- To allow "+" as a value
		,PRRH.PRGroup
		,PRRH.JCCo
		,HQCO.Name AS JCCoName
		,PRRH.Job
		,JCJM.Description AS JobDescription
		,PRRH.Shift
		,CASE WHEN PRRH.[Status] = 1 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS [Status]
		,PRRH.CreatedBy
		,CASE WHEN PRRH.[Status] = 1 THEN 'Awaiting Approval' ELSE 'New' END AS StatusDescription
		,PRRH.UniqueAttchID
		,PRRH.Notes AS Notes
		,PRCO.EMCo AS DefaultEMCo         -- For adding equipment
		,HQCOEM.EMGroup AS DefaultEMGroup -- For adding equipment
		,PRRH.PhaseGroup -- For equipment lookup (add row)
		,CAST(NULL AS SMALLDATETIME) AS CopyFromPostDate
		,CAST(NULL AS VARCHAR) AS CopyFromSheet
		,CAST(0 AS BIT) AS CopyHours
		,CAST(NULL AS VARCHAR) As CopyHoursDescription
		,PRRH.KeyID
	FROM 
		PRRH WITH (NOLOCK)
		LEFT JOIN PRCR WITH (NOLOCK) ON PRCR.PRCo = PRRH.PRCo AND PRCR.Crew = PRRH.Crew
		LEFT JOIN JCJM WITH (NOLOCK) ON JCJM.JCCo = PRRH.JCCo AND JCJM.Job = PRRH.Job
		LEFT JOIN HQCO WITH (NOLOCK) ON PRRH.JCCo = HQCO.HQCo
		LEFT JOIN PRCO WITH (NOLOCK) ON PRCO.PRCo = PRRH.PRCo
		LEFT JOIN HQCO HQCOEM WITH (NOLOCK) ON HQCOEM.HQCo = PRCO.EMCo
	WHERE
		PRRH.PRCo = @Key_PRCo AND PRRH.CreatedBy = @Key_EntryEmployee
		AND PRRH.[Status] <= ISNULL(@Status, 1) -- Parameter for displaying time sheets that are not sent
		AND PRRH.PostDate = ISNULL(@Key_PostDate, PRRH.PostDate) AND PRRH.SheetNum = ISNULL(@Key_SheetNum, PRRH.SheetNum) --Paramters for returning one row
END

GO
GRANT EXECUTE ON  [dbo].[vpspPRCrewTimesheetGet] TO [VCSPortal]
GO
