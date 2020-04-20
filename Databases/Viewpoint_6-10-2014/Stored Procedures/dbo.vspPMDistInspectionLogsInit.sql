SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


--CREATE PROC [dbo].[vspPMDistInspectionLogsInit]
CREATE  PROC [dbo].[vspPMDistInspectionLogsInit]
/*************************************
* Created By :	Dan So 07/09/2009 - Issue #134721 - Distribution Grid Enhancement
* Modified By:	GF 10/15/2009 - issue #136116 - check for duplicate firm contact in distribution table for test log
*				GF 09/03/2010 - issue #141031 change to use date only function
*				SCOTTP 05/10/2013 - TFS-49587,49703 Don't set DateSent column
*
* Pass this a Firm contact and it will initialize an Inspection Log
* distribution line in the vPMDistribution table.
*
*
* Pass:
*       PMCo				PM Company this Other Document is in
*       Project				Project for the Other Document
*       InspectionType		Inspection Type in PM Test Logs
*       InspectionCode		Inspection Code in PM Test Logs
*       SentToFirm			Sent to firm to initialize
*       SentToContact		Contact to initialize to
*		InspectionKeyId		Inspection record KeyID
*
* Returns:
*      MSG if Error
* Success returns:
*	0 on Success, 1 on ERROR
*
* Error returns:

*	1 and error message
**************************************/
(@PMCo bCompany = null, @Project bJob = null, @InspectionType bDocType = null, @InspectionCode bDocument = null,
@SentToFirm bFirm = null, @SentToContact bEmployee = null,
@InspectionKeyId bigint = null, @msg varchar(255) = null output)
as
set nocount on
   
	declare @rcode int, @VendorGroup bGroup, @Seq bTrans, @PrefMethod varchar(1), @EmailOption char(1)

	select @rcode = 0
   
   
	--Check for nulls
	if @PMCo is null or @Project is null or @InspectionType is null or @InspectionCode is null or
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
   
---- check if already in distribution table for test logs
IF NOT EXISTS(SELECT TOP 1 1 FROM dbo.vPMDistribution WITH (NOLOCK) WHERE PMCo=@PMCo AND Project=@Project
			AND VendorGroup=@VendorGroup AND SentToFirm=@SentToFirm AND SentToContact=@SentToContact
			AND InspectionType=@InspectionType AND InspectionCode=@InspectionCode)
	BEGIN
	
	--Get next Seq
	select @Seq = 1
	select @Seq = isnull(Max(Seq),0) + 1
	from vPMDistribution with (nolock) where PMCo = @PMCo and Project = @Project and InspectionType = @InspectionType 
		and InspectionCode = @InspectionCode

	--Insert vPMDistribution record for Test Logs
	insert into vPMDistribution(PMCo, Project, InspectionType, InspectionCode, Seq, VendorGroup, SentToFirm, SentToContact, 
		PrefMethod, Send, CC, InspectionLogID)
	values(@PMCo, @Project, @InspectionType, @InspectionCode, @Seq, @VendorGroup, @SentToFirm, @SentToContact, 
		@PrefMethod, 'Y', @EmailOption, @InspectionKeyId)
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
GRANT EXECUTE ON  [dbo].[vspPMDistInspectionLogsInit] TO [public]
GO
