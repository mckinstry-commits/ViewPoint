SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPMPunchListItemDetailGet]
/************************************************************
* CREATED:     1/11/06  CHS
* MODIFIED:		10/30/06 chs
* MODIFIED:		6/7/07	CHS
*
* USAGE:
*   Returns Punchlist Item Detail (PMPD)
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo, Job, PunchList, Item, VendorGroup
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*
************************************************************/
(@JCCo bCompany, @Job bJob, @PunchList bDocument, @Item smallint, 
@VendorGroup bGroup,
	@KeyID int = Null )

AS
	SET NOCOUNT ON;

SELECT 
d.KeyID, 
d.PMCo, 
d.Project, 
d.PunchList, 
h.Description as 'PunchListDescription', 
d.Item, 
i.Description as 'ItemDescription',
d.ItemLine, 
d.Description, 
d.Description as 'ItemLineDescription', 
d.Location, 
l.Description as 'LocationDescription', 
d.VendorGroup, 
d.ResponsibleFirm, 
f.FirmName,
d.DueDate, 
d.FinDate, 
d.UniqueAttchID 

FROM PMPD d
left join PMPU h with (nolock) on d.PMCo = h.PMCo AND d.Project= h.Project AND d.PunchList = h.PunchList
Left Join PMFM f with (nolock) on d.VendorGroup=f.VendorGroup and d.ResponsibleFirm=f.FirmNumber
Left Join PMPL l with (nolock) on d.PMCo=l.PMCo and d.Project=l.Project and d.Location=l.Location
Left join PMPI i with (nolock) on d.PMCo = i.PMCo AND d.Project= i.Project AND d.VendorGroup=i.VendorGroup AND d.PunchList = i.PunchList AND d.Item = i.Item

Where d.PMCo=@JCCo 
and d.Project=@Job 
and d.PunchList=@PunchList
and d.Item=@Item
and d.KeyID = IsNull(@KeyID, d.KeyID)


GO
GRANT EXECUTE ON  [dbo].[vpspPMPunchListItemDetailGet] TO [VCSPortal]
GO
