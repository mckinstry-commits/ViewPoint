SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**************************************/
CREATE proc [dbo].[vspPMDistSubmittalInit]
/*************************************
* Created By:	GF 10/24/2009 - issue #
* Modified By:	GF 09/06/2010 - issue #141031 changed to use function vfDateOnly
*				SCOTTP 05/10/2013 - TFS-49587,49703 Don't set DateSent,DateReqd columns
*
*
* Pass this a Firm contact and it will initialize a Submittal
* distribution line in the vPMDistribution table.
*
*
* Pass:
* PMCO				PM Company
* Project			Project
* SubmittalType		Submittal Type
* Submittal			Submittal
* SentToFirm		Sent to firm to initialize
* SentToContact		Contact to initialize
* SubmittalKeyID	Submittal KeyID
*
* Returns:
* MSG if Error
*
* Success returns:
* 0 on Success, 1 on ERROR
*
* Error returns:
*
*	1 and error message
**************************************/
(@pmco bCompany = null, @project bJob = null, @submittaltype bDocType = null,
 @submittal bDocument = null, @rev tinyint = null, @senttofirm bFirm = null,
 @senttocontact bEmployee = null,
 @submittalkeyid bigint = null, @msg varchar(255) = null output)
as
set nocount on

declare @rcode int, @vendorgroup bGroup, @seq bTrans, @prefmethod varchar(1), @emailoption char(1)

set @rcode = 0


----Check for nulls
if @pmco is null or @project is null or @submittaltype is null or @submittal is null or
   @rev is null or @senttofirm is null or @senttocontact is null
	begin
	select @msg = 'Missing information!', @rcode = 1
	goto bspexit
	end

----Get VendorGroup
select @vendorgroup = h.VendorGroup
from dbo.HQCO h with (nolock)
join dbo.PMCO p with (nolock) on h.HQCo = p.APCo
where p.PMCo = @pmco

----Get Prefered Method
select @prefmethod = PrefMethod
from dbo.PMPM with (nolock) where VendorGroup = @vendorgroup
and FirmNumber = @senttofirm and ContactCode = @senttocontact
if isnull(@prefmethod,'') = '' set @prefmethod = 'M'

----Get EmailOption, 133966.
select @emailoption = isnull(EmailOption,'N') 
from dbo.PMPF with (nolock) where PMCo=@pmco and Project=@project
and VendorGroup=@vendorgroup and FirmNumber=@senttofirm and ContactCode=@senttocontact
if isnull(@emailoption,'') = '' set @emailoption = 'N'

----check if already in distribution table for test logs
IF NOT EXISTS(SELECT TOP 1 1 FROM dbo.vPMDistribution WITH (NOLOCK) WHERE PMCo=@pmco AND Project=@project
			AND VendorGroup=@vendorgroup AND SentToFirm=@senttofirm AND SentToContact=@senttocontact
			AND SubmittalType=@submittaltype AND Submittal=@submittal and Rev=@rev)
	BEGIN
	
	----Get next Seq
	select @seq = 1
	select @seq = isnull(Max(Seq),0) + 1
	from dbo.vPMDistribution with (nolock) where PMCo = @pmco and Project = @project
	and SubmittalType = @submittaltype and Submittal = @submittal and Rev=@rev

	--Insert vPMDistribution record for Test Logs
	insert into vPMDistribution(PMCo, Project, SubmittalType, Submittal, Rev, Seq, VendorGroup,
			SentToFirm, SentToContact, PrefMethod, Send, CC, SubmittalID)
	values(@pmco, @project, @submittaltype, @submittal, @rev, @seq, @vendorgroup,
			@senttofirm, @senttocontact, @prefmethod, 'Y', @emailoption, @submittalkeyid)
	if @@rowcount = 0
		begin
		select @msg = 'Nothing inserted!', @rcode=1
		goto bspexit
		end

	if @@rowcount > 1
		begin
		select @msg = 'Too many rows affected, insert aborted!', @rcode=1
		goto bspexit
		end
   
   END



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMDistSubmittalInit] TO [public]
GO
