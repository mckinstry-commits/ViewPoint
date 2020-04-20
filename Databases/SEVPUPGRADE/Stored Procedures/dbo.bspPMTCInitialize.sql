SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspPMTCInitialize]
   /*************************************
   * Created By :  GF 10/23/2001
   * Modified By:	GP 06/22/2009 - Issue 133699 Added EmailOption to insert.
   *
   * Pass this a Firm contact and it will initialize a Transmittal
   * distribution line in PMTC.
   *
   *
   * Pass:
   *       PMCO          PM Company this Transmittal is in
   *       Project       Project for the Transmittal
   *       Transmittal   Transmittal Identifier
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
   (@pmco bCompany, @project bJob, @transmittal bDocument,
    @senttofirm bFirm, @senttocontact bEmployee, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @vendorgroup bGroup, @seq bTrans, @prefmethod varchar(1), @EmailOption char(1)
   
   select @rcode = 0
   
   if @pmco is null or @project is null or @transmittal is null or
       @senttofirm is null or @senttocontact is null
   	begin
   	select @msg = 'Missing information!', @rcode = 1
   	goto bspexit
   	end
   
   select @vendorgroup=h.VendorGroup
   from bHQCO h with (nolock) join bPMCO p with (nolock) on h.HQCo=p.APCo
   where p.PMCo=@pmco
   
   select @prefmethod=PrefMethod
   from bPMPM with (nolock) where VendorGroup=@vendorgroup and FirmNumber=@senttofirm and ContactCode=@senttocontact
   if isnull(@prefmethod,'') = '' select @prefmethod = 'M'
   
   --Get EmailOption, 133966.
   select @EmailOption = isnull(EmailOption,'N') from bPMPF with (nolock) where PMCo=@pmco and Project=@project and
		VendorGroup=@vendorgroup and FirmNumber=@senttofirm and ContactCode=@senttocontact  
   
   select @seq=1
   select @seq=isnull(Max(Seq),0)+1
   from bPMTC with (nolock) where PMCo=@pmco and Project=@project and Transmittal=@transmittal
   
   insert into bPMTC(PMCo, Project, Transmittal, Seq, VendorGroup, SentToFirm, SentToContact, PrefMethod, Send, CC)
   values(@pmco, @project, @transmittal, @seq, @vendorgroup, @senttofirm, @senttocontact, @prefmethod, 'Y', @EmailOption)
   if @@rowcount = 0
       begin
       select @msg = 'Nothing inserted!', @rcode=1
       goto bspexit
       end
   
   if @@rowcount >1
       begin
       select @msg = 'Too many rows affected, inserted aborted!', @rcode=1
       goto bspexit
       end
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMTCInitialize] TO [public]
GO
