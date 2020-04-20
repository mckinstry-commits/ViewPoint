SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspPMDrawingLogRevisionsGet]
/***********************************************************
* Created:     8/26/09		JB		Rewrote SP/cleanup
* Modified:	
* 
* Description:	Get drawing log revision record(s).
************************************************************/
(@JCCo bCompany, @Job bJob, @DrawingType bDocType, @Drawing bDocument, @KeyID int = Null)
AS
BEGIN
	SET NOCOUNT ON;

	SELECT i.[KeyID]
		, i.[PMCo]
		, i.[Project]
		, i.[DrawingType]
		, i.[Drawing]
		, CAST(i.Rev AS VARCHAR(3)) AS 'Rev'
		, i.[RevisionDate]
		, d.[Description] AS 'DrawingTypeDescription'
		, i.[Status]
		, i.[Notes]
		, i.[UniqueAttchID]
		, i.[Description]
		, i.[Description] AS 'RevisionDescription'
		, j.[Description] AS 'StatusDescription'

	FROM PMDR i WITH (NOLOCK)
		LEFT JOIN PMSC j WITH (NOLOCK) ON i.[Status] = j.[Status]
		LEFT JOIN PMDT d WITH (NOLOCK) ON i.[DrawingType] = d.[DocType]

	WHERE i.[PMCo] = @JCCo
		AND i.[Project] = @Job 
		AND i.[DrawingType] = @DrawingType 
		AND i.[Drawing] = @Drawing
		AND i.[KeyID] = IsNull(@KeyID, i.[KeyID])
END

GO
GRANT EXECUTE ON  [dbo].[vpspPMDrawingLogRevisionsGet] TO [VCSPortal]
GO
