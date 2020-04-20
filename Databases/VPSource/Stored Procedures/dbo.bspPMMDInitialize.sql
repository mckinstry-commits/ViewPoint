SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMMDInitialize    Script Date: 8/28/99 9:35:14 AM ******/
   CREATE   proc [dbo].[bspPMMDInitialize]
   /*************************************
   * CREATED BY    :	CJW  4/8/98
   * LAST MODIFIED :	kb 2/01/99
   *					GF 10/26/2001 - Added seq to PMMD table
   *					GF 02/17/2003 - issue #19970 - meeting is a integer not a tinyint
   *					GP 06/22/2009 - Issue 133966 Added EmailOption to insert.
   *
   * Pass this a Firm and contact and it will initialize a
   * firm contact for Meeting minute in PMMD
   *
   *
   * Pass:
   *       PMCO          PM Company this Meeting Minute is in
   *       Project       Project for the Meeting Minute
   *       MeetingType	  Meeting Type for Meeting Minute
   *   	Meeting       Meeting Number for Meeting Minute
   *       MinutesType   Minutes Type for Meeting Minute
   * Returns:
   *      MSG if Error
   * Success returns:
   *	0 on Success, 1 on ERROR
   *
   * Error returns:
   *
   *	1 and error message
   **************************************/
   (@pmco bCompany, @project bJob, @meetingtype bDocType, @meeting int,
    @minutestype tinyint, @firmnumber bFirm, @contactcode bEmployee, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @vendorgroup bGroup, @present bYN, @seq int, @EmailOption char(1)
   
   select @rcode = 0
   
   if @pmco is null or @project is null or @meetingtype is null or
       @meeting is null or @minutestype is null
   	begin
   	select @msg = 'Missing information!', @rcode = 1
   	goto bspexit
   	end
   
   select @vendorgroup=h.VendorGroup
   from bHQCO h with (nolock) join bPMCO p with (nolock) on h.HQCo=p.APCo
   where p.PMCo=@pmco
   
   --Get EmailOption, 133966.
   select @EmailOption = isnull(EmailOption,'N') from bPMPF with (nolock) where PMCo=@pmco and Project=@project and
		VendorGroup=@vendorgroup and FirmNumber=@firmnumber and ContactCode=@contactcode     
   
   if @minutestype = 0 select @present='N'
   if @minutestype = 1 select @present='Y'
   
   select @seq=1
   select @seq=isnull(Max(Seq),0)+1
   from bPMMD with (nolock) where PMCo=@pmco and Project=@project and MeetingType=@meetingtype
   and Meeting=@meeting and MinutesType=@minutestype
   
   if (select count (*) from bPMMD with (nolock) where PMCo = @pmco and Project = @project and MeetingType = @meetingtype
   	and Meeting = @meeting and MinutesType = @minutestype and VendorGroup = @vendorgroup and
   	FirmNumber = @firmnumber and ContactCode = @contactcode) = 0
   
       begin
       insert into bPMMD(PMCo, Project, MeetingType, Meeting, MinutesType, Seq,
                         VendorGroup, FirmNumber, ContactCode, PresentYN, CC)
       values(@pmco, @project, @meetingtype, @meeting, @minutestype, @seq, @vendorgroup, @firmnumber, @contactcode, 
			@present, @EmailOption)
   
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
GRANT EXECUTE ON  [dbo].[bspPMMDInitialize] TO [public]
GO
