SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vpspPMRFIEntryGet]
/************************************************************
* CREATED:     7/13/06  CHS
* MODIFIED:		6/7/07	CHS
*
* USAGE:
*   Returns PM RFI
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo and Job 
*
************************************************************/
(
	@JCCo bCompany, 
	@Job bJob,
	@ReqFirm bFirm,
	@ReqContact bEmployee,
	@KeyID int = Null
)

AS
SET NOCOUNT ON;


SELECT fi.KeyID, fi.PMCo, fi.Project, fi.RFI, fi.RFIType, 
t.Description as 'RFITypeDescription', fi.Subject,
fi.RFIDate, fi.DateDue, fi.Issue, fi.Status, 
fi.Submittal, 
fi.Drawing, 
fi.Addendum, fi.SpecSec, 
fi.ScheduleNo, fi.VendorGroup, fi.ResponsibleFirm, 
fi.ResponsiblePerson, @ReqFirm as 'ReqFirm', 
rf.FirmName as 'RequestingFirmName', 
@ReqContact as 'ReqContact', rp.FirstName + ' ' + rp.LastName as ReqFirstLastName, 
fi.Notes, fi.UniqueAttchID, fi.Response, fi.PrefMethod

FROM PMRI fi with (nolock)
Left Join PMDT t with (nolock) on fi.RFIType = t.DocType
Left Join PMPM rp with (nolock)on fi.VendorGroup = rp.VendorGroup AND fi.ReqContact = @ReqContact AND fi.ReqFirm = @ReqFirm
Left Join PMFM rf with (nolock) on fi.VendorGroup = rf.VendorGroup AND fi.ReqFirm = @ReqFirm

-- no data should be displayed
where 1=2
and fi.KeyID = IsNull(@KeyID, fi.KeyID)




GO
GRANT EXECUTE ON  [dbo].[vpspPMRFIEntryGet] TO [VCSPortal]
GO
