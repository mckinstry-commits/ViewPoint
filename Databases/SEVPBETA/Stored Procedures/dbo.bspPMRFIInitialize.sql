SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMRFIInitialize    Script Date: 8/28/99 9:35:18 AM ******/
 CREATE  proc [dbo].[bspPMRFIInitialize]
 /*************************************
   * CREATED BY:		SAE  12/11/97
   * LAST MODIFIED:	SAE  12/11/97
   *					GF 09/18/01 - get preferred method from firm contacts
   *					GF 11/10/2004 - issue #22771 parameters for date sent and date due
   *					GF 02/02/2008 - issue #126960 added send and cc to insert statement
   *					GP 06/22/2009 - Issue 133966 Added EmailOption to insert.
   *					GF 09/05/2010 - changed to use function vfDateOnly
   *
   *
   *
   * Pass this a Firm contact and it will initialize a RFI Detail line
   * using defaults from the First line on the RFI
   
   *
   * Pass:
   *       PMCO          PM Company this RFI is in
   *       Project       Project for the RFI
   *       RFIType       Document type of RFI
   *       RFI           RFI Identifier
   *       SentToFirm    Sent to firm to initialize
   *       SentToContact Contact to initialize to
   *		@datesent
   *		@datedue
   *
   * Returns:
   *      MSG if Error
   * Success returns:
   *	0 on Success, 1 on ERROR
   *
   * Error returns:
   
   *	1 and error message
   **************************************/
   (@pmco bCompany, @project bJob = null, @rfitype bDocType = null, @rfi bDocument = null,
    @senttofirm bFirm = null, @senttocontact bEmployee = null, @datesent bDate = null,
    @datedue bDate = null, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @vendorgroup bGroup, @sentdate bDate, @daterequired bDate,
   		@rfiseq bTrans, @firstseq bTrans, @prefmethod varchar(1),
   		@defaultrfidaysdue int, @EmailOption char(1)
   
   select @rcode = 0
   
   if @pmco is null or @project is null or @rfitype is null or @rfi is null or
     @senttofirm is null or @senttocontact is null
   	begin
   	select @msg = 'Missing information!', @rcode = 1
   	goto bspexit
   	end
   
   -- -- -- get vendor group from HQ
   select @vendorgroup=h.VendorGroup
   from bHQCO h with (nolock) join bPMCO p with (nolock) on h.HQCo=p.APCo
   where p.PMCo=@pmco
   
   -- -- -- get default days due for RFI's from JCJM
   select @defaultrfidaysdue=DefaultRFIDaysDue
   from bJCJM where JCCo=@pmco and Job=@project
   if isnull(@defaultrfidaysdue,0) = 0 set @defaultrfidaysdue = 0
   
   -- -- -- get preferred method of contact from PMPM
   select @prefmethod=PrefMethod
   from bPMPM with (nolock) where VendorGroup=@vendorgroup and FirmNumber=@senttofirm and ContactCode=@senttocontact
   if isnull(@prefmethod,'') = '' set @prefmethod = 'M'
   
   --Get EmailOption, 133966.
   select @EmailOption = isnull(EmailOption,'N') from bPMPF with (nolock) where PMCo=@pmco and Project=@project and
		VendorGroup=@vendorgroup and FirmNumber=@senttofirm and ContactCode=@senttocontact    
   
   -- -- -- if date sent is empty use system date
   ----#141031
   if isnull(@datesent,'') = '' set @datesent = dbo.vfDateOnly()
   
   -- -- -- if date due is empty use default days due and date sent to calculate one
   if isnull(@datedue,'') = '' and isnull(@datesent,'') <> '' and @defaultrfidaysdue > 0
   	begin
   	select @datedue = dateadd(Day, @defaultrfidaysdue, @datesent)
   	end
   
   begin transaction
   
   select @rfiseq=1, @firstseq=null
   -- -- -- get next PMRD sequence
   select @rfiseq=isnull(Max(RFISeq),0)+1 
   from bPMRD with (nolock) where PMCo=@pmco and Project=@project and RFIType=@rfitype and RFI=@rfi

------ get first sequence from PMRD
select @firstseq=Min(RFISeq) 
from PMRD with (nolock) where PMCo=@pmco and Project=@project and RFIType=@rfitype and RFI=@rfi
if @firstseq is null
	begin
	insert into bPMRD(PMCo, Project, RFIType, RFI, RFISeq, VendorGroup, SentToFirm,
				SentToContact, DateSent, InformationReq, DateReqd, PrefMethod, Send, CC)
   	values(@pmco, @project, @rfitype, @rfi, @rfiseq, @vendorgroup, @senttofirm,
				@senttocontact, @datesent, null, @datedue, @prefmethod, 'Y', @EmailOption)
   	end
else
	begin
	insert into bPMRD(PMCo, Project, RFIType, RFI, RFISeq, VendorGroup, SentToFirm,
				SentToContact, DateSent, InformationReq, DateReqd, PrefMethod, Send, CC)
   	select PMCo, Project, RFIType, RFI, @rfiseq, VendorGroup, @senttofirm,
				@senttocontact, @datesent, InformationReq, @datedue, @prefmethod, 'Y', @EmailOption
	from bPMRD with (nolock) where PMCo=@pmco and Project=@project and RFIType=@rfitype 
	and RFI=@rfi and RFISeq = @firstseq
   	end

   if @@rowcount = 0
       begin
       select @msg = 'Nothing inserted!', @rcode=1
       rollback
       goto bspexit
       end
   
   if @@rowcount > 1
       begin
       select @msg = 'Too many rows affected, inserted aborted!', @rcode=1
       rollback
       goto bspexit
       end
   
   commit transaction
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMRFIInitialize] TO [public]
GO
