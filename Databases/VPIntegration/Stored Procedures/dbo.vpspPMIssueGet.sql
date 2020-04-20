SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vpspPMIssueGet]
/************************************************************
* CREATED:		1/9/06  RWH
* MODIFIED:		1/30/06  CHS, 2/7/06	CHS
* MODIFIED:		6/7/07	CHS
* MODIFIED:		6/12/07	CHS
*				GP 1/28/10 - added IssueInfo, DescImpact, DaysImpact, CostImpact, ROMImpact, Type, and Reference
*				GF 11/02/2011 TK-00000 added issuetypedescription to select
*				DAN SO 11/07/2011 - TK-09596 - added RelatedFirm, RelatedFirmContact, and RelatedContactName to Select
*											 - added 2 more LEFT JOIN lines 	
*											 - removed Case and replaced with JOIN on DDCI
*
* USAGE:
*   Returns the PM Project Issues 
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo, Job, VendorGroup
*
************************************************************/
(@JCCo bCompany, @Job bJob, @VendorGroup bGroup,
	@KeyID int = Null)
as
SET NOCOUNT ON;

SELECT i.KeyID, i.PMCo, i.Project, 
	cast(i.Issue as varchar(10)) as Issue,
	i.Description, i.DateInitiated, i.Initiator, 
	isnull(p.FirstName + ' ' + p.LastName, '') as FirstLastName, i.FirmNumber, f.FirmName, i.MasterIssue, 
	mi.Description as MasterIssueDescription,
	i.DateResolved, i.Status, cc.[DisplayValue] as 'StatusText',
	i.Notes, i.FirmNumber, 
	--case i.Status 
	--	when 0 then 'Open' 
	--	else 'Closed' 
	--	end as 'StatusText', 
	i.VendorGroup, i.UniqueAttchID, 
	i.IssueInfo, i.DescImpact, i.DaysImpact, i.CostImpact, i.ROMImpact, i.[Type],
	d.Description AS 'IssueTypeDescription',
	i.Reference, i.RelatedFirm, b.FirmName as RelatedFirmName, 
	i.RelatedFirmContact, isnull(c.FirstName + ' ' + c.LastName,'') as RelatedContactName 

FROM PMIM i with (nolock)
	Left Join PMFM f with (nolock) on i.VendorGroup=f.VendorGroup and i.FirmNumber=f.FirmNumber
	Left Join PMPM p with (nolock) on i.VendorGroup=p.VendorGroup and i.FirmNumber=p.FirmNumber and i.Initiator=p.ContactCode
	Left Join PMIM mi with (nolock) on i.PMCo=mi.PMCo and i.Project=mi.Project and i.MasterIssue = mi.Issue
	LEFT JOIN PMDT d WITH (NOLOCK) ON i.[Type]=d.DocType
	LEFT JOIN PMFM b with (nolock) on b.VendorGroup=i.VendorGroup and b.FirmNumber=i.RelatedFirm 
	LEFT JOIN PMPM c with (nolock) on c.VendorGroup=i.VendorGroup and c.FirmNumber=i.RelatedFirm and c.ContactCode=i.RelatedFirmContact
	LEFT JOIN dbo.DDCI cc WITH (NOLOCK) ON cc.ComboType = 'PMIssueStatus' AND i.Status = cc.DatabaseValue

WHERE i.PMCo=@JCCo and i.Project=@Job
	and i.KeyID = IsNull(@KeyID, i.KeyID)




GO
GRANT EXECUTE ON  [dbo].[vpspPMIssueGet] TO [VCSPortal]
GO
