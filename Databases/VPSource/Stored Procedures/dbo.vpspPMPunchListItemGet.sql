SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [dbo].[vpspPMPunchListItemGet]
/************************************************************
* CREATED:		1/11/06		CHS
* MODIFIED:		3/12/07		chs
* MODIFIED:		6/5/07		chs
* MODIFIED:		6/7/07	CHS
*
* USAGE:
*   Returns the PM Test Logs releated to a passed in Company
*	and Job
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo, Job, PunchList
*   
************************************************************/
(@JCCo bCompany, @Job bJob, @PunchList bDocument,
	@KeyID int = Null)

AS
SET NOCOUNT ON;

SELECT
i.KeyID, 
i.PMCo, 
i.Project, 
i.PunchList, 
h.Description as 'PunchListDescription', 

--i.Item,
cast(i.Item as varchar(5)) as 'Item',

i.Description, 
i.VendorGroup, 

i.ResponsibleFirm,
f.FirmName as 'ResponsibleFirmName', 
i.Location, 
l.Description as 'LocationDescription', 
i.DueDate, 
i.FinDate, 
i.BillableYN, 

i.BillableFirm,
bf.FirmName as 'BillableFirmName', 
i.Issue, 
d.Description as 'IssueDescription', 
i.Notes, 
i.UniqueAttchID

FROM PMPI i with (nolock)
left join PMPU h with (nolock) on i.PMCo = h.PMCo AND i.Project= h.Project AND i.PunchList = h.PunchList
Left Join PMFM f with (nolock) on i.VendorGroup=f.VendorGroup and i.ResponsibleFirm=f.FirmNumber
Left Join PMPL l with (nolock) on i.PMCo=l.PMCo and i.Project=l.Project and i.Location=l.Location
Left Join PMFM bf with (nolock) on i.VendorGroup=bf.VendorGroup and i.BillableFirm=bf.FirmNumber
Left Join PMIM d with (nolock) on i.PMCo=d.PMCo and i.Project=d.Project and i.Issue=d.Issue

Where i.PMCo=@JCCo and i.Project=@Job and i.PunchList=@PunchList
and i.KeyID = IsNull(@KeyID, i.KeyID)

GO
GRANT EXECUTE ON  [dbo].[vpspPMPunchListItemGet] TO [VCSPortal]
GO
