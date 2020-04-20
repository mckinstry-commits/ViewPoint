SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**************************************/
CREATE proc [dbo].[vspPMDistProjectIssuesInit]
/*************************************
* Created By:	GF 09/30/2010 - issue #141553/TFS#791
* Modified By:	SCOTTP 05/10/2013 - TFS-49587,49703 Don't set DateSent column
*
*
* Pass this a Firm contact and it will initialize a Project Issue Log
* distribution line in the vPMDistribution table.
*
*
* Pass:
* IssueKeyID	PMIM Key ID
* SentToFirm    Sent to firm to initialize
* SentToContact Contact to initialize
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
(@IssueKeyID BIGINT = NULL, @SentToFirm bFirm = null,
 @SentToContact bEmployee = null,
 @msg varchar(255) = null output)
as
set nocount on

declare @rcode int, @PMCo bCompany, @Project bJob, @IssueType bDocType, 
		@Issue INT, @VendorGroup bGroup, @Seq bigint, @PrefMethod varchar(1),
		@EmailOption char(1)

set @rcode = 0

----Check for nulls
if @IssueKeyID is null or @SentToFirm is null or @SentToContact is null
	begin
	select @msg = 'Missing information!', @rcode = 1
	goto bspexit
	end

----get project issue info from PMIM
SELECT @PMCo=PMCo, @Project=Project, @IssueType = Type, @Issue = Issue,
		@VendorGroup = VendorGroup
FROM dbo.bPMIM WHERE KeyID = @IssueKeyID
IF @@rowcount = 0
	BEGIN
	select @msg = 'Project Issue not found.', @rcode = 1
	goto bspexit
	END
	

----Get Prefered Method
select @PrefMethod = PrefMethod
from dbo.bPMPM where VendorGroup = @VendorGroup
and FirmNumber = @SentToFirm and ContactCode = @SentToContact
if isnull(@PrefMethod,'') = '' set @PrefMethod = 'M'

----Get EmailOption
select @EmailOption = isnull(EmailOption,'N') 
from dbo.bPMPF where PMCo=@PMCo and Project=@Project
and VendorGroup=@VendorGroup and FirmNumber=@SentToFirm and ContactCode=@SentToContact

----check if already in distribution table for prpject issue
IF NOT EXISTS(SELECT TOP 1 1 FROM dbo.vPMDistribution WHERE PMCo=@PMCo AND Project=@Project
			AND VendorGroup=@VendorGroup AND SentToFirm=@SentToFirm AND SentToContact=@SentToContact
			AND Issue=@Issue)
	BEGIN
	
	----Get next Seq
	select @Seq = 1
	select @Seq = isnull(Max(Seq),0) + 1
	from dbo.vPMDistribution where PMCo = @PMCo and Project = @Project AND Issue = @Issue

	--Insert vPMDistribution record for project issue
	insert into vPMDistribution(PMCo, Project, IssueType, Issue, Seq, VendorGroup,
			SentToFirm, SentToContact, PrefMethod, Send, CC, IssueID)
	values(@PMCo, @Project, @IssueType, @Issue, @Seq, @VendorGroup, @SentToFirm,
			@SentToContact, @PrefMethod, 'Y', @EmailOption, @IssueKeyID)
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
GRANT EXECUTE ON  [dbo].[vspPMDistProjectIssuesInit] TO [public]
GO
