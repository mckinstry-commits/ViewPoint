SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vpspPMApprovedCOGet]
/************************************************************
* CREATED:		1/10/06		RWH
* MODIFIED:		4/20/06		chs
* MODIFIED:		6/7/07		CHS
* MODIFIED:		6/13/07		CHS
*
* USAGE:
*   Returns the PM Approved Change Orders
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo and Job 
*
************************************************************/
(@JCCo bCompany, @Job bJob,
	@KeyID int = Null)

AS

SET NOCOUNT ON;

Select a.KeyID, a.PMCo, a.Project, a.ACO, a.Description, 

	cast(a.ACOSequence as varchar(10)) as 'ACOSequence', 
	
	a.Issue, i.Description as 'Issue Description', a.Contract, 
	a.ChangeDays, a.NewCmplDate, a.IntExt,

	case a.IntExt 
		when 'I' then 'Internal' 
		when 'E' then 'External' 
		else '' 
		end as 'IntExtDescription',

	a.DateSent, a.DateReqd, 
	a.ApprovalDate, a.ApprovedBy, a.BillGroup, a.Notes, a.UniqueAttchID, 
 	'ContractChangedAmount' = isnull(PMOIAppAmt,0),
 	a.DateRecd
	
	from PMOH a with (nolock)
		Left Join PMIM i with (nolock) on a.PMCo=i.PMCo 
			and a.Project=i.Project 
			and a.Issue=i.Issue
			
		left join (select b.PMCo, b.Project, b.ACO, PMOIAppAmt=isnull(sum(b.ApprovedAmt),0)
			from bPMOI b with (nolock) where b.ACO is not null
			group by b.PMCo, b.Project, b.ACO) 
			pm on pm.PMCo=a.PMCo and pm.Project=a.Project and pm.ACO=a.ACO			
		
	Where a.PMCo=@JCCo and a.Project=@Job
	and a.KeyID = IsNull(@KeyID, a.KeyID)








GO
GRANT EXECUTE ON  [dbo].[vpspPMApprovedCOGet] TO [VCSPortal]
GO
