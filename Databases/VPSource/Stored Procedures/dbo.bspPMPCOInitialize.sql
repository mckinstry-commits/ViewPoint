
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspPMPCOInitialize    Script Date: 8/28/99 9:35:16 AM ******/
   CREATE proc [dbo].[bspPMPCOInitialize]
   /*************************************
   * CREATED BY    : bc 5/15/98
   * Modified By:  GF 09/18/01 - get preferred method from firm contacts
   *				GP 06/22/2009 - Issue 133966 Added EmailOption to insert.
   *				GF 09/05/2010 - issue #141031 use function vfDateOnly
   *				SCOTTP 05/10/2013 - TFS-49587,49703 Don't set DateSent,DateReqd columns
   *										Check first if Distribution record already exists
   *
   *
   * Pass this a Firm contact and it will initialize an PCO Detail line
   * using defaults from the First line on the PCO
   *
   * Pass:
   *       PMCO          PM Company this PCO is in
   *       Project       Project for the PCO
   *	    PCOType	      Pending Change Order Type
   *       PCO           Pending Change Order
   *       SentToFirm    Sent to firm to initialize
   *       SentToContact Contact to initialize to
   *
   *
   * Returns:
   *      MSG if Error
   * Success returns:
   *	0 on Success, 1 on ERROR
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@pmco bCompany, @project bJob, @pcotype bDocType, @pco bPCO,
    @senttofirm bFirm, @senttocontact bEmployee, 
	@msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @vendorgroup bGroup, @seq bTrans,
           @firstseq bTrans, @prefmethod varchar(1), @EmailOption char(1)
   
   select @rcode = 0
   
   if @pmco is null or @project is null or @pcotype is null or @pco is null or
      @senttofirm is null or @senttocontact is null
   	begin
   	select @msg = 'Missing information!', @rcode = 1
   	goto bspexit
   	end
   
   select @vendorgroup=h.VendorGroup
   from bHQCO h with (nolock) join bPMCO p with (nolock) on h.HQCo=p.APCo where p.PMCo=@pmco
   
   select @prefmethod=PrefMethod
   from bPMPM with (nolock) where VendorGroup=@vendorgroup and FirmNumber=@senttofirm and ContactCode=@senttocontact
   if isnull(@prefmethod,'') = '' select @prefmethod = 'M'

   --Get EmailOption, 133966.
   select @EmailOption = isnull(EmailOption,'N') from bPMPF with (nolock) where PMCo=@pmco and Project=@project and
		VendorGroup=@vendorgroup and FirmNumber=@senttofirm and ContactCode=@senttocontact   
   
   IF NOT EXISTS(SELECT TOP 1 1 FROM dbo.bPMCD
		WHERE PMCo=@pmco AND Project=@project
		AND VendorGroup=@vendorgroup AND SentToFirm=@senttofirm AND SentToContact=@senttocontact
		AND PCOType=@pcotype AND PCO=@pco)

   BEGIN
   
   select @seq=1, @firstseq=null
   select @seq=isnull(Max(Seq),0)+1 from bPMCD with (nolock) 
   where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco
   
   select @firstseq=Min(Seq) from bPMCD with (nolock) 
   where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco
   
   if @firstseq is null -- if no seq to base it on
       insert into bPMCD (PMCo, Project, PCOType, PCO, Seq, VendorGroup, SentToFirm, SentToContact,
                          PrefMethod, Send, CC)
       values (@pmco, @project, @pcotype, @pco, @seq, @vendorgroup, @senttofirm, @senttocontact,
                          @prefmethod, 'Y', @EmailOption)
   else
       insert into bPMCD(PMCo, Project, PCOType, PCO, Seq, VendorGroup, SentToFirm, SentToContact,
                         PrefMethod, Send, CC)
       select PMCo, Project, PCOType, PCO, @seq, VendorGroup, @senttofirm, @senttocontact,
                        @prefmethod, 'Y', @EmailOption
       from bPMCD with (nolock) where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco and Seq=@firstseq
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
   
   END   
   
   bspexit:
   	return @rcode

GO

GRANT EXECUTE ON  [dbo].[bspPMPCOInitialize] TO [public]
GO
