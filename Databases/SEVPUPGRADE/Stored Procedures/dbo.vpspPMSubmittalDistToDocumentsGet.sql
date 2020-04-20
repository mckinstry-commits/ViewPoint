SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPMSubmittalDistToDocumentsGet]
/************************************************************
* CREATED:     2/5/07  CHS
* MODIFIED:		6/7/07	CHS
*
* USAGE:
*   Returns the PM Submittal Items
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo and Job 
*
************************************************************/
(@JCCo bCompany, @Job bJob, @Submittal bDocument, @Rev tinyint, 
@SubmittalType bDocType,
	@KeyID int = Null)
as
SET NOCOUNT ON;


select s.KeyID, 
s.PMCo, s.Project, s.Submittal, h.Description as 'SubmittalDescription',
s.SubmittalType,
s.Rev, s.Item, s.Description, s.Status, s.Send,
s.DateReqd, s.DateRecd, s.ToArchEng, s.DueBackArch, s.RecdBackArch,
s.DateRetd, s.ActivityDate, s.CopiesRecd, s.CopiesSent,
s.CopiesReqd, s.CopiesRecdArch, s.CopiesSentArch, s.Notes, 
s.UniqueAttchID, c.Description as 'StatusDescription',
	case s.Send
		when 'Y' then 'Yes' 
		when 'N' then 'No' 
		else '' 
		end as 'SendDescription'

from PMSI s with (nolock)
	left join PMSM h with (nolock) on h.PMCo = s.PMCo 
		and h.Project = s.Project 
		and s.Submittal = h.Submittal 
		and s.Rev = h.Rev 
		and s.SubmittalType = h.SubmittalType
	left Join PMSC c with (nolock) on s.Status=c.Status

where 
	@JCCo = s.PMCo 
	and @Job = s.Project
	and @Submittal = s.Submittal
	and @Rev = s.Rev
	and @SubmittalType = s.SubmittalType
	and s.KeyID = IsNull(@KeyID, s.KeyID)


GO
GRANT EXECUTE ON  [dbo].[vpspPMSubmittalDistToDocumentsGet] TO [VCSPortal]
GO
