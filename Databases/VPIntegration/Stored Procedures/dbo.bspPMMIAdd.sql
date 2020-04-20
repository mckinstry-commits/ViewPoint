SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMMIAdd    Script Date: 8/28/99 9:35:15 AM ******/
   CREATE proc [dbo].[bspPMMIAdd]
   /*************************************
   * CREATED BY:	kb 2/12/99
   * LAST MODIFIED:	gf 05/31/2002
   *				GF 12/05/2003 - #23212 - check error messages, wrap concatenated values with isnull
   *				GF 06/13/2006 - 121547 - added PMML.Notes to insert for PMML.
   *
   *
   * Pass:
   *       PMCO          PM Company this Meeting Minute Item
   *       Project       Project for this Meeting Minute Item
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
   
   declare @rcode int, @item int, @vendorgroup bGroup, @present bYN, @opencursor tinyint
   
   select @rcode = 0, @opencursor = 0
   
   
   declare bcPMMI cursor LOCAL FAST_FORWARD
   for select Item from bPMMI
   where PMCo=@pmco and Project=@project and MeetingType=@meetingtype and Meeting=@meeting and MinutesType=0
   
   open bcPMMI
   set @opencursor = 1
   
   -- process rows
   PMMI_loop:
   fetch next from bcPMMI into @item
   
   if @@fetch_status = -1 goto PMMI_end
   if @@fetch_status <> 0 goto PMMI_loop
   
   -- insert item into bPMMI if not exists
   if not exists (select top 1 1 from bPMMI with (nolock) where PMCo=@pmco and Project=@project and MeetingType=@meetingtype
   			and Meeting=@meeting and MinutesType=1 and Item=@item)
   
   	begin
   
   	insert bPMMI(PMCo, Project, MeetingType, Meeting, MinutesType, Item, OriginalItem, 
   				Minutes, VendorGroup, InitFirm, Initiator, ResponsibleFirm, ResponsiblePerson,
   				InitDate, DueDate, FinDate, Status, Issue, Description)
   	select @pmco, @project, @meetingtype, @meeting, 1, @item, OriginalItem,
   				Minutes, VendorGroup, InitFirm, Initiator, ResponsibleFirm, ResponsiblePerson,
   				InitDate, DueDate, FinDate, Status, Issue, Description
   	from bPMMI with (nolock) where PMCo= @pmco and Project = @project and MeetingType = @meetingtype
   	and Meeting = @meeting and MinutesType = 0 and Item=@item
   	if @@rowcount = 1
   		begin
   		-- insert item detail into bPMML
   		insert bPMML(PMCo, Project, MeetingType, Meeting, MinutesType, Item, ItemLine, Description,
   					VendorGroup, ResponsibleFirm, ResponsiblePerson, InitDate, DueDate, FinDate, Status, Notes)
   		select @pmco, @project, @meetingtype, @meeting, 1, @item, ItemLine, Description,
   					VendorGroup, ResponsibleFirm, ResponsiblePerson, InitDate, DueDate, FinDate, Status, Notes
   		from bPMML with (nolock) where PMCo= @pmco and Project = @project and MeetingType = @meetingtype
   		and Meeting = @meeting and MinutesType = 0 and Item=@item
   		end
   
   	end
   
   
   goto PMMI_loop
   
   PMMI_end:
   	close bcPMMI
   	deallocate bcPMMI
   	set @opencursor = 0
   
   
   
   /*
   -- Pseudo cursor
   select @item=min(Item) from bPMMI with (nolock) where PMCo=@pmco and Project=@project and 
   MeetingType=@meetingtype and Meeting=@meeting and MinutesType=0
   while @item is not null
   begin
   
   	-- insert item into bPMMI if not exists
   	if not exists (select top 1 1 from bPMMI with (nolock) where PMCo=@pmco and Project=@project and MeetingType=@meetingtype
   			and Meeting=@meeting and MinutesType=1 and Item=@item)
   
   		begin
   
   		insert bPMMI(PMCo, Project, MeetingType, Meeting, MinutesType, Item, OriginalItem, 
   				Minutes, VendorGroup, InitFirm, Initiator, ResponsibleFirm, ResponsiblePerson,
   				InitDate, DueDate, FinDate, Status, Issue)
   		select @pmco, @project, @meetingtype, @meeting, 1, @item, OriginalItem,
   				Minutes, VendorGroup, InitFirm, Initiator, ResponsibleFirm, ResponsiblePerson,
   				InitDate, DueDate, FinDate, Status, Issue
   		from bPMMI with (nolock) where PMCo= @pmco and Project = @project and MeetingType = @meetingtype
   		and Meeting = @meeting and MinutesType = 0 and Item=@item
   		if @@rowcount = 1
   			begin
   			-- insert item detail into bPMML
   			insert bPMML(PMCo, Project, MeetingType, Meeting, MinutesType, Item, ItemLine, Description,
   					VendorGroup, ResponsibleFirm, ResponsiblePerson, InitDate, DueDate, FinDate, Status)
   			select @pmco, @project, @meetingtype, @meeting, 1, @item, ItemLine, Description,
   					VendorGroup, ResponsibleFirm, ResponsiblePerson, InitDate, DueDate, FinDate, Status
   			from bPMML with (nolock) where PMCo= @pmco and Project = @project and MeetingType = @meetingtype
   			and Meeting = @meeting and MinutesType = 0 and Item=@item
   			end
   
   		end
   
   -- next item
   select @item=min(Item) from bPMMI with (nolock) where PMCo=@pmco and Project=@project and 
   MeetingType=@meetingtype and Meeting=@meeting and MinutesType=0 and Item>@item
   if @@rowcount = 0 select @item = null
   end
   */
   
   
   
   bspexit:
   	if @opencursor = 1
   		begin
   		close bcPMMI
   		deallocate bcPMMI
   		set @opencursor = 0
   		end
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMMIAdd] TO [public]
GO
