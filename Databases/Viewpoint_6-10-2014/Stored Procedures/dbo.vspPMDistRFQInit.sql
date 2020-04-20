SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  proc [dbo].[vspPMDistRFQInit]
/*************************************
* Created By :	AJW 5/1/13 
* Modified By : SCOTTP 05/10/2013 - TFS-49587,49703 Don't set DateSent column, set Send column
*
*
* Pass this a Firm contact and it will initialize a Request for Quote (REQQOTE)
* distribution line in the vPMDistribution table.
*
*
* Pass:
*       PMCO          PM Company this Other Document is in
*       Project       Project for the Other Document
*       SentToFirm    Sent to firm to initialize
*       SentToContact Contact to initialize to
*		RFQID		  Request for Quote record KeyID
*
* Returns:
*      MSG if Error
* Success returns:
*	0 on Success, 1 on ERROR
*
* Error returns:

*	1 and error message
**************************************/
(@PMCo bCompany = null, @Project bJob = null,
@SentToFirm bFirm = null, @SentToContact bEmployee = null,
@RFQID bigint = null, @msg varchar(255) = null output)
as

set nocount on


declare @rcode int, @VendorGroup bGroup

select @rcode = 0

   		
--Check for nulls
if @PMCo is null or @Project is null or @RFQID is null or
   @SentToFirm is null or @SentToContact is null
begin
	select @msg = 'Missing information!', @rcode = 1
	goto vspexit
end

INSERT dbo.vPMDistribution(PMCo,Project,RFQ,Seq,VendorGroup,SentToFirm,SentToContact,PrefMethod,CC,Send,RFQID)
SELECT @PMCo, @Project, q.RFQ, 
	isnull( (select max(Seq) from PMDistribution where PMCo=@PMCo AND Project=@Project and RFQ=q.RFQ), 0) + 1, 
	h.VendorGroup, @SentToFirm, @SentToContact, 
	isnull(m.PrefMethod,'M'), isnull(f.EmailOption,'N'), 'Y', 
	@RFQID
FROM dbo.PMCO p
JOIN dbo.HQCO h on h.HQCo = p.APCo
JOIN dbo.PMPM m on h.VendorGroup=m.VendorGroup and m.FirmNumber=@SentToFirm and m.ContactCode=@SentToContact
JOIN dbo.PMPF f on f.PMCo=@PMCo and f.Project=@Project and
		f.VendorGroup=m.VendorGroup and f.FirmNumber=@SentToFirm and f.ContactCode=@SentToContact
JOIN PMRequestForQuote q on q.KeyID = @RFQID
WHERE p.PMCo = @PMCo
AND NOT EXISTS (SELECT 1 FROM dbo.PMDistribution
	WHERE  PMCo=@PMCo AND Project=@Project AND RFQ=q.RFQ
		AND VendorGroup=h.VendorGroup AND SentToFirm=@SentToFirm AND SentToContact=@SentToContact
	)

vspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPMDistRFQInit] TO [public]
GO
