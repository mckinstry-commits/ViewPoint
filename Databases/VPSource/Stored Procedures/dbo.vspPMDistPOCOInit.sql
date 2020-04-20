SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPMDistPOCOInit]
/*************************************
* Created By :	TRL 04/04/2011 TK-03845
* Modified By:	GP 7/28/2011 - TK-07143 changed bPO to varchar(30)
*
*
* Pass this a Firm contact and it will initialize a Purchase Order Change Order
* distribution line in the vPMDistribution table.
*
*
* Pass:
*       PMCO          PM Company this Other Document is in
*       Project       Project for the Other Document
*       POCONum		  PO Change Order number from PMPOCO
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
(@PMCo bCompany = null, @Project bJob = null, @POCONum SMALLINT = null,
@SentToFirm bFirm = null, @SentToContact bEmployee = null, @DateSent bDate = null, @DateSigned bDate = null, 
@POCOKeyID bigint = null, @msg varchar(255) = null output)
as

set nocount on

declare @rcode int, @VendorGroup bGroup, @Seq bTrans, @PrefMethod varchar(1), @EmailOption char(1),
		@POCo bCompany, @PO varchar(30)

select @rcode = 0

   		
--Check for nulls
if @PMCo is null or @Project is null or @POCONum is null or
   @SentToFirm is null or @SentToContact is null
begin
	select @msg = 'Missing information!', @rcode = 1
	goto vspexit
end
   
--Get VendorGroup
select @VendorGroup = h.VendorGroup
from dbo.HQCO h with (nolock) join bPMCO p with (nolock) on h.HQCo = p.APCo
where p.PMCo = @PMCo

--Get Prefered Method
select @PrefMethod = PrefMethod
from dbo.PMPM with (nolock) 
where VendorGroup = @VendorGroup and FirmNumber = @SentToFirm and ContactCode = @SentToContact

if isnull(@PrefMethod,'') = '' 
begin
	select @PrefMethod = 'M'
end

--Get EmailOption
select @EmailOption = isnull(EmailOption,'N') 
from dbo.PMPF with (nolock) 
where PMCo=@PMCo and Project=@Project and
VendorGroup=@VendorGroup and FirmNumber=@SentToFirm and ContactCode=@SentToContact
	
--get POCo and PO
select @POCo=POCo, @PO=PO from dbo.PMPOCO where KeyID = @POCOKeyID
	
--Get DateSent
----#141031
if isnull(@DateSent,'') = '' 
begin
	set @DateSent = dbo.vfDateOnly()
end

-- check if already in distribution table for test logs
if not exists(select top 1 1 from dbo.vPMDistribution with (nolock) where PMCo=@PMCo AND Project=@Project
			and VendorGroup=@VendorGroup and SentToFirm=@SentToFirm and SentToContact=@SentToContact
			and POCONum=@POCONum)
begin
	
	--Get next Seq
	select @Seq = 1
	
	select @Seq = isnull(Max(Seq),0) + 1
	from dbo.PMDistribution
	where PMCo = @PMCo and Project = @Project and POCo = @POCo AND PO = @PO and POCONum = @POCONum

	--Insert vPMDistribution record for Test Logs
	insert into dbo.vPMDistribution(PMCo, Project, POCo, PO, POCONum, Seq, VendorGroup, SentToFirm, SentToContact, 
			PrefMethod, [Send], CC, DateSent, POCOID)
	values(@PMCo, @Project, @POCo, @PO, @POCONum, @Seq, @VendorGroup, @SentToFirm, @SentToContact, 
			@PrefMethod, 'Y', @EmailOption, @DateSent, @POCOKeyID)
	if @@rowcount = 0
	begin
		select @msg = 'Nothing inserted!', @rcode=1
		goto vspexit
	end

	if @@rowcount > 1
	begin
		select @msg = 'Too many rows affected, insert aborted!', @rcode=1
		goto vspexit
	end
END

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMDistPOCOInit] TO [public]
GO
