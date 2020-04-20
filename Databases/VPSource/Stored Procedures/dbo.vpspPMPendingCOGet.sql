SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vpspPMPendingCOGet]
/************************************************************
* CREATED:     5/17/06 chs
* Modified:		8/8/06 chs
* Modified:		9/6/06 chs
* MODIFIED:		6/7/07	CHS
*				GF 11/15/2011 TK-09972 additional fields for 6.4.0 changes
*
*
* USAGE:
*   Returns PM Pending Change Orders
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo, Job 
*
************************************************************/
(@JCCo bCompany, @Job bJob,
	@KeyID int = Null)

AS

SET NOCOUNT ON;

Select p.KeyID, p.PMCo, p.Project, p.PCOType, p.PCO, p.Description, 
	p.Issue, i.Description as 'Issue Description', p.Contract, 
	p.PendingStatus, p.UniqueAttchID,

	case p.PendingStatus 
		when 0 then 'Pending' 
		when 1 then 'Partial'
		when 2 then 'Approved'
		when 3 then 'Final'
		else 'n/a' 
		end as 'Status Description',

	isnull(dt.PCODate1, 'Date Description 1') as 'PCODate1', p.Date1, 
	isnull(dt.PCODate2, 'Date Description 2') as 'PCODate2', p.Date2,
	isnull(dt.PCODate3, 'Date Description 3') as 'PCODate3', p.Date3, 
	
	isnull(dt.PCOItemDate1, 'Item Date Description 1') as 'PCOItemDate1', 
	isnull(dt.PCOItemDate2, 'Item Date Description 2') as 'PCOItemDate2', 
	isnull(dt.PCOItemDate3, 'Item Date Description 3') as 'PCOItemDate3',  
	
	p.ApprovalDate, p.Notes, p.IntExt, 

	case p.IntExt 
		when 'I' then 'Internal' 
		when 'E' then 'External' 
		else '' 
		end as 'IntExtDescription',

	(select isnull((select sum(case FixedAmountYN when 'Y' then FixedAmount else PendingAmount end)
		from PMOI with (nolock) 
		where PMOI.PMCo=p.PMCo 
			and PMOI.Project=p.Project 
			and PMOI.PCOType=p.PCOType 
			and PMOI.PCO = p.PCO),0)) 
	as 'ContractChangeAmt'
	
	----TK-09972
	,p.DateCreated
	,p.InitiatedBy
	,p.Priority
	,cc.[DisplayValue] as 'PriorityDescription'
	,p.ReasonCode
	,rc.Description AS 'ReasonDescription'
	,p.Reference
	,p.ROMAmount
	,p.Status
	,sc.Description AS 'StatusDescription'

	from dbo.PMOP p with (nolock)
	Left Join dbo.PMIM i with (nolock) on p.PMCo=i.PMCo and p.Project=i.Project and p.Issue=i.Issue
	left join dbo.PMDT dt with (nolock) on dt.DocType = p.PCOType
	----TK-09972
	LEFT JOIN dbo.DDCI cc WITH (NOLOCK) ON cc.ComboType = 'PMPCOSPriority' AND p.Priority = cc.DatabaseValue
	LEFT JOIN dbo.HQRC rc WITH (NOLOCK) ON rc.ReasonCode = p.ReasonCode
	LEFT JOIN dbo.PMSC sc WITH (NOLOCK) ON sc.Status = p.Status
	Where p.PMCo=@JCCo and p.Project=@Job
	and p.KeyID = IsNull(@KeyID, p.KeyID)
	







GO
GRANT EXECUTE ON  [dbo].[vpspPMPendingCOGet] TO [VCSPortal]
GO
