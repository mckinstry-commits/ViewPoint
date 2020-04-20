SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  proc [dbo].[vspPMDistSubCOInit]
/*************************************
* Created By :	GP 02/14/2011
* Modified By:	SCOTTP 05/10/2013 - TFS-49587,49703 Don't set DateSent column
*
*
* Pass this a Firm contact and it will initialize a Subcontract Change Order
* distribution line in the vPMDistribution table.
*
*
* Pass:
*       PMCO          PM Company this Other Document is in
*       Project       Project for the Other Document
*       SubCO		  Subcontract Change Order number from PMSubcontractCO
*       SentToFirm    Sent to firm to initialize
*       SentToContact Contact to initialize to
*		SubCOKeyID   Subcontract Change Order record KeyID
*
* Returns:
*      MSG if Error
* Success returns:
*	0 on Success, 1 on ERROR
*
* Error returns:

*	1 and error message
**************************************/
(@PMCo bCompany = null, @Project bJob = null, @SubCO SMALLINT = null,
@SentToFirm bFirm = null, @SentToContact bEmployee = null,
@SubCOKeyID bigint = null, @msg varchar(255) = null output)
as
set nocount on

	declare @rcode int, @VendorGroup bGroup, @Seq bTrans, @PrefMethod varchar(1), @EmailOption char(1),
			@SLCo bCompany, @SL VARCHAR(30)

	select @rcode = 0
   
   
	--Check for nulls
	if @PMCo is null or @Project is null or @SubCO is null or
       @SentToFirm is null or @SentToContact is null
   	begin
   		select @msg = 'Missing information!', @rcode = 1
   		goto bspexit
   	end
   
	--Get VendorGroup
	select @VendorGroup = h.VendorGroup
	from bHQCO h with (nolock) join bPMCO p with (nolock) on h.HQCo = p.APCo
	where p.PMCo = @PMCo
   
	--Get Prefered Method
	select @PrefMethod = PrefMethod
	from bPMPM with (nolock) where VendorGroup = @VendorGroup and FirmNumber = @SentToFirm and ContactCode = @SentToContact
	if isnull(@PrefMethod,'') = '' select @PrefMethod = 'M'
   
	--Get EmailOption, 133966.
	select @EmailOption = isnull(EmailOption,'N') from bPMPF with (nolock) where PMCo=@PMCo and Project=@Project and
		VendorGroup=@VendorGroup and FirmNumber=@SentToFirm and ContactCode=@SentToContact
		
	----get SLCo and SL
	SELECT @SLCo=SLCo, @SL=SL
	FROM dbo.PMSubcontractCO WHERE KeyID = @SubCOKeyID
	
---- check if already in distribution table for test logs
IF NOT EXISTS(SELECT TOP 1 1 FROM dbo.vPMDistribution WITH (NOLOCK) WHERE PMCo=@PMCo AND Project=@Project
			AND VendorGroup=@VendorGroup AND SentToFirm=@SentToFirm AND SentToContact=@SentToContact
			AND SubCO=@SubCO)
	BEGIN
	
	--Get next Seq
	select @Seq = 1
	select @Seq = isnull(Max(Seq),0) + 1
	from dbo.PMDistribution
	where PMCo = @PMCo and Project = @Project
	AND SLCo = @SLCo AND SL = @SL and SubCO = @SubCO

	--Insert vPMDistribution record for Test Logs
	insert into vPMDistribution(PMCo, Project, SLCo, SL, SubCO, Seq, VendorGroup, SentToFirm, SentToContact, 
			PrefMethod, Send, CC, SubcontractCOID)
	values(@PMCo, @Project, @SLCo, @SL, @SubCO, @Seq, @VendorGroup, @SentToFirm, @SentToContact, 
			@PrefMethod, 'Y', @EmailOption, @SubCOKeyID)
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
GRANT EXECUTE ON  [dbo].[vspPMDistSubCOInit] TO [public]
GO
