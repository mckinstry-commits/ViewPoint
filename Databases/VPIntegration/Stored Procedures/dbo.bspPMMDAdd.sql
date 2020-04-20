SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMMDAdd    Script Date: 8/28/99 9:35:14 AM ******/
   CREATE proc [dbo].[bspPMMDAdd]
   /*************************************
   * CREATED BY    : kb 2/12/99
   * LAST MODIFIED : gf 05/31/2002
   *				  GF 12/05/2003 - #23212 - check error messages, wrap concatenated values with isnull
   *
   *
   * Pass:
   *       PMCO          PM Company this RFI is in
   *       Project       Project for the RFI
   *       MeetingType	
   *   	Meeting
   *
   * Returns:
   *      MSG if Error
   * Success returns:
   *	0 on Success, 1 on ERROR
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@pmco bCompany, @project bJob, @meetingtype bDocType, @meeting int, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @agendaseq int, @vendorgroup bGroup, @firmnumber bVendor, @contactcode bEmployee,
   		@presentyn bYN, @seq int, @opencursor tinyint
   
   select @rcode = 0, @agendaseq = 0, @seq = 0, @opencursor = 0
   
   -- create cursor on bPMMD
   declare bcPMMD cursor LOCAL FAST_FORWARD
   for select Seq, VendorGroup, FirmNumber, ContactCode, PresentYN
   from bPMMD
   where PMCo=@pmco and Project=@project and MeetingType=@meetingtype and Meeting=@meeting and MinutesType=0
   
   open bcPMMD
   set @opencursor = 1
   
   -- process minutes detail
   PMMD_loop:
   fetch next from bcPMMD into @agendaseq, @vendorgroup, @firmnumber, @contactcode, @presentyn
   
   if @@fetch_status = -1 goto PMMD_end
   if @@fetch_status <> 0 goto PMMD_loop
   
   -- get next sequence number
   select @seq=isnull(Max(Seq),0)+1
   from bPMMD with (nolock) where PMCo=@pmco and Project=@project and MeetingType=@meetingtype
   and Meeting=@meeting and MinutesType=1
   
   -- insert into bPMMD if not exists
   if not exists (select 1 from bPMMD with (nolock) where PMCo=@pmco and Project=@project 
   			and MeetingType=@meetingtype and Meeting=@meeting and MinutesType=1 
   			and VendorGroup=@vendorgroup and FirmNumber=@firmnumber and ContactCode=@contactcode)
   	begin
   	insert into bPMMD(PMCo, Project, MeetingType, Meeting, MinutesType, Seq, VendorGroup, FirmNumber,
   			ContactCode, PresentYN)
   	select @pmco, @project, @meetingtype, @meeting, 1, @seq, @vendorgroup, @firmnumber,
   			@contactcode, @presentyn
   	end
   
   goto PMMD_loop
   
   
   PMMD_end:
   	close bcPMMD
   	deallocate bcPMMD
   	set @opencursor = 0
   
   
   /*
   -- Pseudo cursor
   select @agendaseq=min(Seq) from bPMMD with (nolock) where PMCo=@pmco and Project=@project and 
   MeetingType=@meetingtype and Meeting=@meeting and MinutesType=0
   while @agendaseq is not null
   begin
   
   	select @vendorgroup=VendorGroup, @firmnumber=FirmNumber, @contactcode=ContactCode, @presentyn=PresentYN
   	from bPMMD with (nolock) where PMCo=@pmco and Project=@project and MeetingType=@meetingtype
   	and Meeting=@meeting and MinutesType=0 and Seq=@agendaseq
   
   	-- get next sequence number
   	select @seq=isnull(Max(Seq),0)+1
   	from bPMMD with (nolock) where PMCo=@pmco and Project=@project and MeetingType=@meetingtype
   	and Meeting=@meeting and MinutesType=1
   
   	-- insert into bPMMD if not exists
   	if not exists (select 1 from bPMMD with (nolock) where PMCo=@pmco and Project=@project and MeetingType=@meetingtype
   			and Meeting=@meeting and MinutesType=1and VendorGroup=@vendorgroup and FirmNumber=@firmnumber
   			and ContactCode=@contactcode)
   
   		begin
       	insert into bPMMD(PMCo, Project, MeetingType, Meeting, MinutesType, Seq, VendorGroup, FirmNumber,
   				ContactCode, PresentYN)
       	select @pmco, @project, @meetingtype, @meeting, 1, @seq, @vendorgroup, @firmnumber,
   				@contactcode, @presentyn
   		end
   
   -- next attendee
   select @agendaseq=min(Seq) from bPMMD with (nolock) where PMCo=@pmco and Project=@project and 
   MeetingType=@meetingtype and Meeting=@meeting and MinutesType=0 and Seq>@agendaseq
   if @@rowcount = 0 select @agendaseq = null
   end
   */
   
   
   
   bspexit:
   	if @opencursor = 1
   		begin
   		close bcPMMD
   		deallocate bcPMMD
  
   		set @opencursor = 0
   		end
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMMDAdd] TO [public]
GO
