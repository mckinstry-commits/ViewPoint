
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspPMDCInitialize    Script Date: 8/28/99 9:35:09 AM ******/
   CREATE proc [dbo].[bspPMDCInitialize]
   /*************************************
   * CREATED BY    : SAE  1/26/98
   * LAST MODIFIED : SAE  1/26/98
   *					GP 06/22/2009 - Issue 133966 Added EmailOption to insert.
   *					GF 09/05/2010 - issue #141031 use functin vfDateOnly
   *					SCOTTP 05/10/2013 - TFS-49587,49703 Set Send column to 'Y',
							Add and assign Sequence and Preferred Method columns
   *
   * Pass this a Firm contact and it will initialize a PMDC line
   * using defaults from the First line on the Log
   *
   * Pass:
   *       PMCO          PM Company this RFI is in
   *       Project       Project for the RFI
   *       LogDate       Log To add distribution rec to
   *       DailyLog      Log number for that day
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
   (@pmco bCompany, @project bJob, @logdate bDate, @dailylog int,
    @senttofirm bFirm, @senttocontact bEmployee, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @vendorgroup bGroup, @seq bTrans, @prefmethod varchar(1), @EmailOption char(1)
   
   select @rcode = 0
   
   if @pmco is null or @project is null or @logdate is null or @dailylog is null or
   	@senttofirm is null or @senttocontact is null
   	begin
   	select @msg = 'Missing information!', @rcode = 1
   	goto bspexit
   	end
   
   -- get vendor group
   select @vendorgroup=h.VendorGroup 
   from bHQCO h with (nolock) join bPMCO p with (Nolock) on h.HQCo=p.APCo
   where p.PMCo=@pmco
   
   ----Get Prefered Method
	select @prefmethod = PrefMethod
	from dbo.PMPM with (nolock) where VendorGroup = @vendorgroup
	and FirmNumber = @senttofirm and ContactCode = @senttocontact
	if isnull(@prefmethod,'') = '' set @prefmethod = 'M'

   --Get EmailOption, 133966.
   select @EmailOption = isnull(EmailOption,'N') from bPMPF with (nolock) where PMCo=@pmco and Project=@project and
		VendorGroup=@vendorgroup and FirmNumber=@senttofirm and ContactCode=@senttocontact   
   
   -- only insert record if doesn't already exist
   if not exists (select TOP 1 1 from bPMDC with (nolock) where PMCo=@pmco and Project=@project 
   			and LogDate=@logdate and DailyLog=@dailylog and VendorGroup=@vendorgroup 
   			and SentToFirm=@senttofirm and SentToContact=@senttocontact)
   	begin
   
   	----Get next Seq
	select @seq = 1
	select @seq = isnull(Max(Seq),0) + 1
	from dbo.bPMDC where PMCo = @pmco and Project = @project
	and LogDate=@logdate and DailyLog=@dailylog

   	-- insert PMDC row
   	insert into bPMDC(PMCo, Project, LogDate, DailyLog, Seq, VendorGroup, SentToFirm, SentToContact, PrefMethod, Send, CC)
   	----#141031
   	values(@pmco, @project, @logdate, @dailylog, @seq, @vendorgroup, @senttofirm, @senttocontact, @prefmethod, 'Y', @EmailOption)
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
   
   	end    
   
   
   
   
   	
   bspexit:
   	return @rcode

GO

GRANT EXECUTE ON  [dbo].[bspPMDCInitialize] TO [public]
GO
