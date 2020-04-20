SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMRFQInitialize    Script Date: 8/28/99 9:35:18 AM ******/
CREATE proc [dbo].[bspPMRFQInitialize]
/*************************************
   * CREATED BY:		SAE 12/21/97
   * LAST MODIFIED:	LM 2/11/98
   *					GF 09/18/01 - get preferred method from firm contacts
   *					GF 11/10/2004 - issue #22771 parameter for date sent to calculate date req'd
   *					GF 02/02/2008 - issue #126960 added send and cc to insert statement
   *					GP 06/22/2009 - Issue 133966 Added EmailOption to insert.
   *					GF 09/05/2010 - changed to use function vfDateOnly
   *
   *
   * Pass this a Firm contact and it will initialize an RFQ Detail line
   * using defaults from the First line on the RFQ
   *
   * Pass:
   *       PMCO          PM Company this RFI is in
   *       Project       Project for the RFI
   *	PCOType	      Pending Change Order Type
   *       PCO          Pending Change Order
   *       RFQ           RFI Identifier
   *       SentToFirm    Sent to firm to initialize
   *       SentToContact Contact to initialize to
   * Returns:
   *      MSG if Error
   * Success returns:
   *	0 on Success, 1 on ERROR
   *
   * Error returns:
   *	1 and error message
   **************************************/
(@pmco bCompany, @project bJob = null, @pcotype bDocType = null, @pco bPCO = null,
 @rfq bDocument = null, @senttofirm bFirm = null, @senttocontact bEmployee = null,
 @datesent bDate = null, @datedue bDate = null, @msg varchar(255) output)
 as
set nocount on
   
declare @rcode int, @vendorgroup bGroup, @sentdate bDate, @daterequired bDate,
   		@seq bTrans, @firstseq bTrans, @prefmethod varchar(1), @defaultstddaysdue int, @EmailOption char(1)
   
select @rcode = 0
   
   if @pmco is null or @project is null or @pcotype is null or @pco is null or @rfq is null or
     @senttofirm is null or @senttocontact is null
   	begin
   	select @msg = 'Missing information!', @rcode = 1
   	goto bspexit
   	end
   
   select @vendorgroup=h.VendorGroup 
   from bHQCO h with (nolock) join bPMCO p with (nolock) on h.HQCo=p.APCo where p.PMCo=@pmco
   
   -- -- -- get default days due for RFI's from JCJM
   select @defaultstddaysdue=DefaultStdDaysDue
   from bJCJM where JCCo=@pmco and Job=@project
   if isnull(@defaultstddaysdue,0) = 0 set @defaultstddaysdue = 0
   
   select @prefmethod=PrefMethod
   from bPMPM with (nolock) where VendorGroup=@vendorgroup and FirmNumber=@senttofirm and ContactCode=@senttocontact
   if isnull(@prefmethod,'') = '' select @prefmethod = 'M'
   
   --Get EmailOption, 133966.
   select @EmailOption = isnull(EmailOption,'N') from bPMPF with (nolock) where PMCo=@pmco and Project=@project and
		VendorGroup=@vendorgroup and FirmNumber=@senttofirm and ContactCode=@senttocontact     

-- -- -- if date sent is empty use system date
----#141031
if isnull(@datesent,'') = '' set @datesent = dbo.vfDateOnly()

-- -- -- if date due is empty use default days due and date sent to calculate one
if isnull(@datedue,'') = '' and isnull(@datesent,'') <> '' and @defaultstddaysdue > 0
   	begin
   	select @datedue = dateadd(Day, @defaultstddaysdue, @datesent)
   	end


begin transaction

select @seq=1, @firstseq=null

select @seq=isnull(Max(RFQSeq),0)+1 from bPMQD with (nolock) where PMCo=@pmco and
   	  Project=@project and PCOType=@pcotype and PCO=@pco and RFQ=@rfq
   
select @firstseq=Min(RFQSeq) from bPMQD with (nolock) where PMCo=@pmco and
   	  Project=@project and PCOType=@pcotype and PCO=@pco and RFQ=@rfq
if @firstseq is null
	begin
	insert into bPMQD(PMCo, Project, PCOType, PCO, RFQ, RFQSeq, VendorGroup, SentToFirm,
				SentToContact, DateSent, DateReqd, PrefMethod, Send, CC)
   	values(@pmco, @project, @pcotype, @pco, @rfq, @seq, @vendorgroup, @senttofirm,
				@senttocontact, @datesent, @datedue, @prefmethod, 'Y', @EmailOption)
	end
else
	begin
	insert into bPMQD(PMCo, Project, PCOType, PCO, RFQ, RFQSeq, VendorGroup, SentToFirm,
				SentToContact, DateSent, DateReqd, PrefMethod, Send, CC)
   	select PMCo, Project, PCOType, PCO, RFQ, @seq, VendorGroup, @senttofirm,
				@senttocontact, @datesent, @datedue, @prefmethod, 'Y', @EmailOption
	from bPMQD with (nolock) 
	where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco and RFQ=@rfq and RFQSeq = @firstseq
	end

if @@rowcount = 0
       begin
       select @msg = 'Nothing inserted!', @rcode=1
       rollback
       goto bspexit
       end
   
if @@rowcount >1
       begin
       select @msg = 'Too many rows affected, inserted aborted!', @rcode=1
       rollback
       goto bspexit
       end
   
   commit transaction
   
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMRFQInitialize] TO [public]
GO
