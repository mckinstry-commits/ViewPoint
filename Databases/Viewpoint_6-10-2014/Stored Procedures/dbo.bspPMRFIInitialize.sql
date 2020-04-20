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
   *				SCOTTP 05/10/2013 - TFS-49587,49703 Don't set DateSent,DateReq columns
   *										Check first if Distribution record already exists
   *                SCOTTP 08/20/2013 - TFS-58548 Add optional parameter for Email Option
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
    @senttofirm bFirm = null, @senttocontact bEmployee = null, @emailOptionOverride char(1) = null,
    @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @vendorgroup bGroup, @sentdate bDate, @daterequired bDate,
   		@rfiseq bTrans, @firstseq bTrans, @prefmethod varchar(1),
   		@EmailOption char(1)
   
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
   
   -- -- -- get preferred method of contact from PMPM
   select @prefmethod=PrefMethod
   from bPMPM with (nolock) where VendorGroup=@vendorgroup and FirmNumber=@senttofirm and ContactCode=@senttocontact
   if isnull(@prefmethod,'') = '' set @prefmethod = 'M'
   
   --Get EmailOption, 133966.
   if @emailOptionOverride is null
   begin
		select @EmailOption = isnull(EmailOption,'N') from bPMPF with (nolock) where PMCo=@pmco and Project=@project and
				VendorGroup=@vendorgroup and FirmNumber=@senttofirm and ContactCode=@senttocontact
   end
   else
   begin
		select @EmailOption = @emailOptionOverride
   end
   
   IF NOT EXISTS(SELECT TOP 1 1 FROM dbo.bPMRD
		WHERE PMCo=@pmco AND Project=@project
		AND VendorGroup=@vendorgroup AND SentToFirm=@senttofirm AND SentToContact=@senttocontact
		AND RFIType=@rfitype and RFI=@rfi)

   BEGIN
   
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
					SentToContact, InformationReq, PrefMethod, Send, CC)
   		values(@pmco, @project, @rfitype, @rfi, @rfiseq, @vendorgroup, @senttofirm,
					@senttocontact, null, @prefmethod, 'Y', @EmailOption)
   		end
	else
		begin
		insert into bPMRD(PMCo, Project, RFIType, RFI, RFISeq, VendorGroup, SentToFirm,
					SentToContact, InformationReq, PrefMethod, Send, CC)
   		select PMCo, Project, RFIType, RFI, @rfiseq, VendorGroup, @senttofirm,
					@senttocontact, InformationReq, @prefmethod, 'Y', @EmailOption
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
   
   END
   
   
   bspexit:
   	return @rcode




GO
GRANT EXECUTE ON  [dbo].[bspPMRFIInitialize] TO [public]
GO
