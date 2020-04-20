SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  proc [dbo].[vspPMDistSubcontractInit]
/*************************************
* Created By :	SCOTTP 05/02/2013
* Modified by:  AW 09/20/2013 TFS - 62011 Prevent SLs from being generated to the wrong vendor
*
*
* Pass this a Firm contact and it will initialize a Subcontract
* distribution line in the bPMSS table.
*
*
* Pass:
*       PMCO          PM Company this Other Document is in
*       Project       Project for the Other Document
*       SLCo          Subcontract Company
*		SL			  Subcontract
*       SentToFirm    Sent to firm to initialize
*       SentToContact Contact to initialize to
*
* Returns:
*      MSG if Error
* Success returns:
*	0 on Success, 1 on ERROR
*
* Error returns:

*	1 and error message
**************************************/
(@PMCo bCompany = null, @Project bJob = null, @SLCo bCompany = null, @SL varchar(30) = null,
@SentToFirm bFirm = null, @SentToContact bEmployee = null,
@msg varchar(255) = null output)
as

set nocount on

declare @rcode int, @VendorGroup bGroup, @Seq bTrans, @PrefMethod varchar(1), @EmailOption char(1)

select @rcode = 0
   		
--Check for nulls
if @PMCo is null or @Project is null or @SLCo is null or @SL is null or
   @SentToFirm is null or @SentToContact is null
begin
	select @msg = 'Missing information!', @rcode = 1
	goto vspexit
end

INSERT dbo.bPMSS(PMCo,Project,SLCo,SL,Seq,VendorGroup,SendToFirm,SendToContact,Send,PrefMethod,CC)
SELECT @PMCo, @Project, @SLCo, @SL,
	isnull( (select max(Seq) from bPMSS where PMCo=@PMCo AND Project=@Project and SLCo=@SLCo and SL=@SL), 0) + 1, 
	h.VendorGroup, @SentToFirm, @SentToContact, 
	'Y',isnull(m.PrefMethod,'M'), 
	case when isnull(v.CC,'C') = 'N' or dbo.vfToString(s.Vendor) <> dbo.vfToString(z.Vendor) then 'C' else isnull(f.EmailOption,'N') end	
FROM dbo.PMCO p
JOIN dbo.HQCO h on h.HQCo = p.APCo
JOIN dbo.PMPM m on h.VendorGroup=m.VendorGroup and m.FirmNumber=@SentToFirm and m.ContactCode=@SentToContact
JOIN dbo.PMPF f on f.PMCo=@PMCo and f.Project=@Project and
		f.VendorGroup=m.VendorGroup and f.FirmNumber=@SentToFirm and f.ContactCode=@SentToContact
JOIN dbo.SLHDPM s on s.PMCo = @PMCo AND s.Project = @Project and s.SLCo = @SLCo AND s.SL = @SL
JOIN dbo.PMFM z on z.VendorGroup = f.VendorGroup AND z.FirmNumber = f.FirmNumber
LEFT JOIN dbo.PMSS v ON
		v.PMCo = @PMCo AND v.Project = @Project AND v.SLCo = @SLCo AND v.SL = @SL and v.CC = 'N'
WHERE p.PMCo = @PMCo
AND NOT EXISTS (SELECT 1 FROM dbo.bPMSS
	WHERE  PMCo=@PMCo AND Project=@Project AND SLCo=@SLCo AND SL=@SL
		AND VendorGroup=h.VendorGroup AND SendToFirm=@SentToFirm AND SendToContact=@SentToContact
	)

vspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPMDistSubcontractInit] TO [public]
GO
