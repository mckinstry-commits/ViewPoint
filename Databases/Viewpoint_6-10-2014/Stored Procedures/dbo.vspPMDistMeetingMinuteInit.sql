SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**************************************/
CREATE proc [dbo].[vspPMDistMeetingMinuteInit]
/*************************************
* Created By:	TFS48702 HH 05/01/2013 
* Modified By:	SCOTTP 05/10/2013 - TFS-49587,49703 Don't set DateSent,DateSigned columns
*
*
* Pass this a Firm contact and it will initialize a Meeting Minute
* distribution line in the vPMDistribution table.
*
*
* Pass:
* PMCO          PM Company
* Project       Project
* MeetingType	Meeting Type
* Meeting		Meeting
* MinutesType	Minutes Type
* SentToFirm    Sent to firm to initialize
* SentToContact Contact to initialize
* MeetingKeyID	Meeting Minutes record KeyID
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
(
@pmco bCompany = null
, @project bJob = null
, @meetingtype bDocType = null
, @meeting int = null
, @minutestype tinyint = null
, @senttofirm bFirm = null
, @senttocontact bEmployee = null
, @meetingkeyid bigint = null
, @msg varchar(255) = null output)
as
set nocount on

declare @rcode int, @vendorgroup bGroup, @seq bTrans, @prefmethod varchar(1), @emailoption char(1)

set @rcode = 0


----Check for nulls
if @pmco is null or @project is null or @meetingtype is null or @meeting is null or @minutestype is null or
   @senttofirm is null or @senttocontact is null
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
from dbo.PMPM with (nolock) 
where VendorGroup = @vendorgroup
		and FirmNumber = @senttofirm and ContactCode = @senttocontact

if isnull(@prefmethod,'') = '' set @prefmethod = 'M'

----Get EmailOption, 133966.
select @emailoption = isnull(EmailOption,'N') 
from dbo.PMPF with (nolock) 
where PMCo=@pmco 
		and Project=@project
		and VendorGroup=@vendorgroup 
		and FirmNumber=@senttofirm 
		and ContactCode=@senttocontact

----check if already in distribution table for test logs
IF NOT EXISTS(	SELECT TOP 1 1 
				FROM dbo.vPMDistribution WITH (NOLOCK) 
				WHERE PMCo=@pmco 
						AND Project=@project
						AND VendorGroup=@vendorgroup 
						AND SentToFirm=@senttofirm 
						AND SentToContact=@senttocontact
						AND MeetingType=@meetingtype 
						AND Meeting=@meeting 
						AND MinutesType=@minutestype)

	BEGIN
	
	----Get next Seq
	select @seq = 1
	select @seq = isnull(Max(Seq),0) + 1
	from dbo.vPMDistribution with (nolock) 
	where PMCo = @pmco 
			and Project = @project
			and MeetingType = @meetingtype 
			and Meeting = @meeting 
			and MinutesType = @minutestype

	--Insert vPMDistribution record for Meeting Minutes
	insert into vPMDistribution(PMCo, Project, MeetingType, Meeting, MinutesType, Seq, VendorGroup, SentToFirm, SentToContact, PrefMethod, Send, CC, MeetingMinuteID)
	values(@pmco, @project, @meetingtype, @meeting, @minutestype, @seq, @vendorgroup, @senttofirm, @senttocontact, @prefmethod, 'Y', @emailoption, @meetingkeyid)

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
GRANT EXECUTE ON  [dbo].[vspPMDistMeetingMinuteInit] TO [public]
GO
