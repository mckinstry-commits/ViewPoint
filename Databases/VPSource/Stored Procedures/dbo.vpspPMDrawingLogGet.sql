SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPMDrawingLogGet]
/***********************************************************
* Created:     8/26/09		JB		Rewrote SP/cleanup
* Modified:	
* 
* Description:	Get the drawing log record(s).
************************************************************/
(@JCCo bCompany, @Job bJob, @KeyID int = Null)
AS
BEGIN
	SET NOCOUNT ON;
	
	SELECT i.[KeyID]
		, i.[PMCo]
		, i.[Project]
		, i.[DrawingType]
		, i.[Drawing]
		, i.[DateIssued]
		, d.[Description] AS 'DrawingTypeDescription'
		, i.[Status]
		, i.[Notes]
		, i.[UniqueAttchID]
		, i.[Description]
		, j.[Description] AS 'StatusDescription'

	FROM PMDG i WITH (NOLOCK)
		LEFT JOIN PMSC j WITH (NOLOCK) ON i.[Status] = j.[Status]
		LEFT JOIN PMDT d WITH (NOLOCK) ON i.[DrawingType] = d.[DocType]

	Where i.[PMCo] = @JCCo 
		AND i.[Project] = @Job
		AND i.[KeyID] = IsNull(@KeyID, i.[KeyID])

END


GO
GRANT EXECUTE ON  [dbo].[vpspPMDrawingLogGet] TO [VCSPortal]
GO
