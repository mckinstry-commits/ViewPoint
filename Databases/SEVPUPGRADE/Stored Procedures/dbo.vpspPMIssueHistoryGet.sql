SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vpspPMIssueHistoryGet]
/************************************************************
* CREATED:		3/14/06 CHS
* MODIFIED:		6/12/07	CHS
*
* USAGE:
*   Returns the PM Project Issues
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo, Job, Issue
*
************************************************************/
(@JCCo bCompany, @Job bJob, @Issue bIssue,
	@KeyID int = Null)
AS
	SET NOCOUNT ON;
SELECT 
i.PMCo, i.Project, i.Issue, d.Description as 'IssueDescription', 

cast(i.Seq as varchar(5)) as 'Seq', 

i.DocType, t.Description as 'DocTypeDescription', t.DocCategory, 

	case t.DocCategory 
		when 'PCO' then 'Pending Change Order' 
		when 'RFI' then 'Request For Information'
		when 'SUBMIT' then 'Submittal'
		when 'MTG' then 'Meeting Minutes'

		when 'OTHER' then 'Other Documents' 
		when 'DRAWING' then 'Drawing Logs'
		when 'INSPECT' then 'Inspection Logs'
		when 'TEST' then 'Test Logs'
				
		else t.DocCategory  
		end as 'DocCategoryDescription',

i.Document, i.Rev, i.PCOType, i.PCO, i.PCOItem, 
i.ACO, i.ACOItem, i.IssueDateTime, i.Action, i.Login, i.ActionDate, i.UniqueAttchID,

substring(i.Action, 1, 90) as 'ActionTruncated', i.KeyID

FROM PMIH i with (nolock)
Left Join PMIM d with (nolock) on i.PMCo = d.PMCo and i.Project = d.Project and i.Issue = d.Issue
Left Join PMDT t with (nolock) on i.DocType = t.DocType

Where i.PMCo=@JCCo and i.Project=@Job AND i.Issue = @Issue
and i.KeyID = IsNull(@KeyID, i.KeyID)


GO
GRANT EXECUTE ON  [dbo].[vpspPMIssueHistoryGet] TO [VCSPortal]
GO
