SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  proc [dbo].[vspPMDistPunchListInit]
/*************************************
* Created By :	AJW 5/1/13 
* Modifiy By :	SCOTTP 05/10/2013 - TFS-49587,49703 Don't set DateSent column, set Send column
*
*
* Pass this a Firm contact and it will initialize a Approved Change Order
* distribution line in the vPMDistribution table.
*
*
* Pass:
*       PMCO          PM Company this Other Document is in
*       Project       Project for the Other Document
*       ACO			  Approved Change Order number from PMACOS
*       SentToFirm    Sent to firm to initialize
*       SentToContact Contact to initialize to
*		PunchListID   Punch List record KeyID
*
* Returns:
*      MSG if Error
* Success returns:
*	0 on Success, 1 on ERROR
*
* Error returns:

*	1 and error message
**************************************/
(@PMCo bCompany = null, @Project bJob = null, @PUNCHLIST bDocument = null,
@SentToFirm bFirm = null, @SentToContact bEmployee = null, 
@PUNCHLISTID bigint = null, @msg varchar(255) = null output)
as

set nocount on


declare @rcode int, @VendorGroup bGroup, @Seq bTrans, @PrefMethod varchar(1), @EmailOption char(1),
		@POCo bCompany, @PO varchar(30)

select @rcode = 0

   		
--Check for nulls
if @PMCo is null or @Project is null or @PUNCHLIST is null or
   @SentToFirm is null or @SentToContact is null
begin
	select @msg = 'Missing information!', @rcode = 1
	goto vspexit
end

INSERT dbo.vPMDistribution(PMCo,Project,PunchList,Seq,VendorGroup,SentToFirm,SentToContact,PrefMethod,CC,Send,PunchListID)
SELECT @PMCo, @Project, @PUNCHLIST, 
	isnull( (select max(Seq) from PMDistribution where PMCo=@PMCo AND Project=@Project and PunchList=@PUNCHLIST), 0) + 1, 
	h.VendorGroup, @SentToFirm, @SentToContact, 
	isnull(m.PrefMethod,'M'), isnull(f.EmailOption,'N'), 'Y', 
	@PUNCHLISTID
FROM dbo.PMCO p
JOIN dbo.HQCO h on h.HQCo = p.APCo
JOIN dbo.PMPM m on h.VendorGroup=m.VendorGroup and m.FirmNumber=@SentToFirm and m.ContactCode=@SentToContact
JOIN dbo.PMPF f on f.PMCo=@PMCo and f.Project=@Project and
		f.VendorGroup=m.VendorGroup and f.FirmNumber=@SentToFirm and f.ContactCode=@SentToContact
WHERE p.PMCo = @PMCo
AND NOT EXISTS (SELECT 1 FROM dbo.PMDistribution
	WHERE  PMCo=@PMCo AND Project=@Project AND PunchList=@PUNCHLIST
		AND VendorGroup=h.VendorGroup AND SentToFirm=@SentToFirm AND SentToContact=@SentToContact
	)

vspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPMDistPunchListInit] TO [public]
GO
