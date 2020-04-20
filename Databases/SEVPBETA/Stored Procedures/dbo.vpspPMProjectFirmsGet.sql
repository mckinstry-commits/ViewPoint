SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPMProjectFirmsGet]
/************************************************************
* CREATED:     7/18/06  RWH
* MODIFIED:		6/7/07	CHS
*
* USAGE:
*   Returns the PM Proejct Notes
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

as
SET NOCOUNT ON;

select 
f.KeyID, f.PMCo, f.Project, f.Seq, f.VendorGroup, f.FirmNumber, fn.FirmName, 
f.ContactCode, p.FirstName + ' ' + p.LastName as 'FirstLastName', 
f.Description, f.Notes, f.UniqueAttchID, p.Title, p.FirstName, p.LastName,
p.MiddleInit, p.Phone, p.PhoneExt, p.MobilePhone, p.Fax, p.EMail, 
p.Notes as 'PersonalNotes', p.ExcludeYN

from PMPF f with (nolock)
	Left Join PMFM fn with (nolock) on f.VendorGroup=fn.VendorGroup and f.FirmNumber=fn.FirmNumber
	Left Join PMPM p  with (nolock) on f.VendorGroup=p.VendorGroup and f.FirmNumber=p.FirmNumber and f.ContactCode=p.ContactCode

where f.PMCo = @JCCo and f.Project = @Job
and f.KeyID = IsNull(@KeyID, f.KeyID)


GO
GRANT EXECUTE ON  [dbo].[vpspPMProjectFirmsGet] TO [VCSPortal]
GO
