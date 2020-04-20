SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vpspPMTransmittalDistributionGet]
/************************************************************
* CREATED:		11/11/06	CHS
* MODIFIED:		6/7/07		CHS
* MODIFIED:		6/12/07		CHS
*
* USAGE:
*   Returns PM Transmittal Items
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo, Job, VendorGroup, OurFirm, and Transmittal
*
************************************************************/
(@JCCo bCompany, @Job bJob, @VendorGroup bGroup, @OurFirm bFirm, 
@Transmittal bDocument,
	@KeyID int = Null)

AS
SET NOCOUNT ON;

SELECT t.KeyID, 
t.PMCo, t.Project, t.Transmittal, 

cast(t.Seq as varchar(10)) as 'Seq', 

t.VendorGroup,
t.SentToFirm, 
f.FirmName as 'SentToFirmName',

t.SentToContact, 
p.FirstName + ' ' + p.LastName as 'SentToContactName',

t.Send,

case t.Send
	when 'Y' then 'Yes'
	when 'N' then 'No'
	end as 'SendYesOrNo',

t.PrefMethod, 

case t.PrefMethod
	when 'M' then 'Print'
	when 'E' then 'Email'
	when 'T' then 'Email - Text Only'
	when 'F' then 'Fax'
	end as 'PrefMethodDesc',
		
t.CC,

case t.CC
	when 'Y' then 'Yes'
	when 'N' then 'No'
	end as 'CCYesOrNo',

t.DateSent, t.Notes, t.UniqueAttchID

FROM PMTC t with (nolock)
	Left Join PMFM f with (nolock) on t.VendorGroup=f.VendorGroup and t.SentToFirm=f.FirmNumber
	Left Join PMPM p with (nolock) on t.VendorGroup=p.VendorGroup and t.SentToFirm=p.FirmNumber and t.SentToContact=p.ContactCode

WHERE
	t.PMCo=@JCCo and t.Project=@Job and t.Transmittal = @Transmittal
	and t.KeyID = IsNull(@KeyID, t.KeyID)




GO
GRANT EXECUTE ON  [dbo].[vpspPMTransmittalDistributionGet] TO [VCSPortal]
GO
