SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspPMSubmittalItemsGet]
/***********************************************************
* Created:     9/1/09		JB		Rewrote SP/cleanup
* Modified:	
* 
* Description:	Get the PM Submittal item(s).
************************************************************/
(@JCCo bCompany, @Job bJob, @Submittal bDocument, @Rev TINYINT, @SubmittalType bDocType, @KeyID BIGINT = NULL)
AS
BEGIN
	SET NOCOUNT ON;

--SELECT @JCCo=2,@Job=' 2840-',@Submittal='  2840-001',@Rev=0,@SubmittalType='SUB'

	SELECT 
		s.KeyID, 
		s.PMCo, 
		s.Project, 
		s.Submittal, 
		h.Description AS 'SubmittalDescription',
		s.SubmittalType,
		s.Rev, 
		CAST(s.Item AS VARCHAR(10)) AS 'Item', 
		s.Description, 
		s.Status, 
		s.Send,
		s.DateReqd, 
		s.DateRecd, 
		s.ToArchEng, 
		s.DueBackArch, 
		s.RecdBackArch,
		s.DateRetd, 
		s.ActivityDate, 
		s.CopiesRecd, 
		s.CopiesSent,
		s.CopiesReqd, 
		s.CopiesRecdArch, 
		s.CopiesSentArch, s.Notes, 
		s.UniqueAttchID, 
		c.Description AS 'StatusDescription',
		CASE s.Send
			WHEN 'Y' THEN 'Yes' 
			WHEN 'N' THEN 'No' 
			ELSE '' 
			END AS 'SendDescription'

	FROM PMSI s WITH (NOLOCK)
		LEFT JOIN PMSM h WITH (NOLOCK) ON h.PMCo = s.PMCo AND h.Project = s.Project AND s.Submittal = h.Submittal AND s.Rev = h.Rev AND s.SubmittalType = h.SubmittalType
		LEFT JOIN PMSC c WITH (NOLOCK) ON s.Status = c.Status

	WHERE @JCCo = s.PMCo 
		AND @Job = s.Project
		AND @Submittal = s.Submittal
		AND @Rev = s.Rev
		AND @SubmittalType = s.SubmittalType
		AND s.KeyID = ISNULL(@KeyID, s.KeyID)

END

GO
GRANT EXECUTE ON  [dbo].[vpspPMSubmittalItemsGet] TO [VCSPortal]
GO
