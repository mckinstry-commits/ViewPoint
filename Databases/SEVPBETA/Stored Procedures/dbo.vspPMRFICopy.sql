SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPMRFICopy]
  /***********************************************************
   * CREATED BY:	GP	09/27/2010
   * REVIEWD BY:	
   * MODIFIED BY:	GF 10/09/S010 - issue #141648
   *				
   * USAGE:
   * Copies RFI info and related tab info to new RFI.
   *
   * INPUT PARAMETERS
   *	PMCo   
   *	OldProject
   *	OldRFIType
   *	OldRFI
   *	NewProject
   *	NewRFIType
   *	NewRFI
   *	NewRFIDesc
   *	
   *	
   *
   * OUTPUT PARAMETERS
   *   @msg      Description of Department if found.
   *
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/ 
  
  	(@PMCo bCompany, @OldProject bJob, @OldRFIType bDocType, @OldRFI bDocument, @NewProject bJob, @NewRFIType bDocType,
  	@NewRFI bDocument, @NewRFIDesc varchar(60) = null, @Username bVPUserName = null, @msg varchar(255) output)
  as
  set nocount on

declare @rcode int, @PMDHNextSeq int
select @rcode = 0

--------------
--VALIDATION--
--------------
if @PMCo is null
begin
	select @msg='Missing PM Company!', @rcode = 1
	goto vspexit
end

if @OldProject is null
begin
	select @msg='Missing Copy From Project!', @rcode = 1
	goto vspexit
end

if @OldRFIType is null
begin
	select @msg='Missing Copy From RFI Type!', @rcode = 1
	goto vspexit
end

if @OldRFI is null
begin
	select @msg='Missing Copy From RFI!', @rcode = 1
	goto vspexit
end

if @NewProject is null
begin
	select @msg='Missing Copy To Project!', @rcode = 1
	goto vspexit
end

if @NewRFIType is null
begin
	select @msg='Missing Copy To RFI Type!', @rcode = 1
	goto vspexit
end

if @NewRFI is null
begin
	select @msg='Missing Copy To RFI!', @rcode = 1
	goto vspexit
end

if @Username is null
begin
	select @msg='Missing Username!', @rcode = 1
	goto vspexit
end

--make sure the Copy From RFI exists
if not exists (select top 1 1 from dbo.PMRI where PMCo = @PMCo and Project = @OldProject and 
	RFIType = @OldRFIType and RFI = @OldRFI)
begin
	select @msg='The RFI you are attempting to copy from does not exists, please enter a new value.', @rcode = 1
	goto vspexit	
end

--make sure the Copy To RFI does not exist
if exists (select top 1 1 from dbo.PMRI where PMCo = @PMCo and Project = @NewProject and 
	RFIType = @NewRFIType and RFI = @NewRFI)
begin
	select @msg='The RFI you are attempting to copy to already exists, please enter a new value.', @rcode = 1
	goto vspexit	
end

--------
--COPY--
--------
--RFI
insert bPMRI (PMCo, Project, RFIType, RFI, [Subject], RFIDate, Issue, [Status], Submittal, Drawing, 
	Addendum, SpecSec, ScheduleNo, VendorGroup, ResponsibleFirm, ResponsiblePerson, ReqFirm, ReqContact, Notes, Response, 
	DateDue, ImpactDesc, ImpactDays, ImpactCosts, ImpactPrice, RespondFirm, RespondContact, DateSent, DateRecd, PrefMethod, 
	InfoRequested, ImpactDaysYN, ImpactCostsYN, ImpactPriceYN)
select @PMCo, @NewProject, @NewRFIType, @NewRFI, @NewRFIDesc, RFIDate, NULL /*Issue*/, [Status], Submittal, Drawing, 
	Addendum, SpecSec, ScheduleNo, VendorGroup, ResponsibleFirm, ResponsiblePerson, ReqFirm, ReqContact, Notes, Response, 
	DateDue, ImpactDesc, ImpactDays, ImpactCosts, ImpactPrice, RespondFirm, RespondContact, DateSent, DateRecd, PrefMethod, 
	InfoRequested, ImpactDaysYN, ImpactCostsYN, ImpactPriceYN
	from dbo.bPMRI
	where PMCo = @PMCo and Project = @OldProject and RFIType = @OldRFIType and RFI = @OldRFI

--Response
insert vPMRFIResponse (PMCo, Project, RFIType, RFI, Seq, DisplayOrder, [Send], DateRequired, VendorGroup, RespondFirm, 
	RespondContact, Notes, LastDate, LastBy, RFIID, [Status], DateSent, ToFirm, ToContact, DateReceived)
select @PMCo, @NewProject, @NewRFIType, @NewRFI, Seq, DisplayOrder, [Send], DateRequired, VendorGroup, RespondFirm, 
	RespondContact, Notes, LastDate, LastBy, RFIID, [Status], DateSent, ToFirm, ToContact, DateReceived
	from dbo.vPMRFIResponse
	where PMCo = @PMCo and Project = @OldProject and RFIType = @OldRFIType and RFI = @OldRFI 

--Distribution
delete bPMRD where PMCo = @PMCo and Project = @NewProject and RFIType = @NewRFIType and RFI = @NewRFI

insert bPMRD (PMCo, Project, RFIType, RFI, RFISeq, VendorGroup, SentToFirm, SentToContact, DateSent, InformationReq, 
	DateReqd, Response, DateRecd, [Send], PrefMethod, CC)
select @PMCo, @NewProject, @NewRFIType, @NewRFI, RFISeq, VendorGroup, SentToFirm, SentToContact, DateSent, InformationReq, 
	DateReqd, Response, DateRecd, [Send], PrefMethod, CC
	from dbo.bPMRD old
	where PMCo = @PMCo and Project = @OldProject and RFIType = @OldRFIType and RFI = @OldRFI
	--and not exists (select top 1 1 from dbo.bPMRD new where new.PMCo=@PMCo and new.Project=@NewProject and new.RFIType=@NewRFIType
	--	and new.RFI=@NewRFI and new.SentToFirm=old.SentToFirm and new.SentToContact=old.SentToContact)

--History
select @PMDHNextSeq = isnull(max(Seq),0) + 1 from dbo.PMDH where PMCo = @PMCo and Project = @NewProject and DocCategory = 'RFI'

insert bPMDH (PMCo, Project, DocType, Document, Seq, ActionDateTime, 
	[Action], DocCategory, FieldType, UserName)
values (@PMCo, @NewProject, @NewRFIType, @NewRFI, @PMDHNextSeq, getdate(), 
	'RFI:' + char(9) + 'Copy Project:' + @OldProject + ' RFIType:' + @OldRFIType + ' RFI:' + @OldRFI, 'RFI', 'A', @Username)




vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMRFICopy] TO [public]
GO
