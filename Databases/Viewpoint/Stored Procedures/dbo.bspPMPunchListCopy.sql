SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMPunchListCopy    Script Date: 8/28/99 9:35:17 AM ******/
CREATE  procedure [dbo].[bspPMPunchListCopy]
/************************************************************************************
* This SP will copy one punchlist to another.  Pass in the Punchlist you want made and
* the punchlist it is derived from.  The parameters pertaining to the renumbering of
* item numbers are optional.
*
* Both the from and to punchlists need to exist.
*
* Returns either STDBTK_SUCCESS or STDBTK_ERROR and a msg in @msg
*
* Pass In
*	Connection	Connection to do query on
*
*
* Created: 	bc 7/15/98
* Modified:	bc 9/18/98
*			GF 01/30/2003 - issue #19668 not copying all item detail lines. Need to check
*							PMPD cursor and de-allocate if needed before next item.
*			GF 04/04/2003 - issue #	21545 added notes, user memos to copy for PMPI and PMPD
*			GF 10/30/2008 - issue #130136 pmpu notes changed from varchar(8000) to varchar(max)
*
*
*	PMCo		PM Company to initialize in
*	Project		Project to add punchlist to
*	FromPunchList	PunchList being copied from
*	ToPunchList	PunchList being created
*	Items		A comma deliminated string holding all (hopefully) of the desired items to copy
*	StartAt		The number to begin the new items at
*	IncrementBy	If renumbering, the amount to increment each item by.  1 is the default.
*
* Return Parameters
*	msg	Error Message or Success message
*
* Returns
*	STDBTK_ERORR on Error, STDBTK_SUCCESS if all is well
*
*************************************************************************************/
(@pmco bCompany, @project bJob, @frompunchlist varchar(10), @topunchlist varchar(10), @items varchar(255),
 @renumber varchar(1), @startat tinyint, @incrementby tinyint, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @orig_item smallint, @pi_description varchar(255), @vendorgroup bGroup, 
		@pi_responsiblefirm bFirm, @pi_location varchar(10),
		@pi_duedate bDate, @pi_findate bDate, @billable bYN, @billablefirm bFirm, @issue bIssue,
		@itemline tinyint, @pd_description varchar(255), @pd_location varchar(10),
		@pd_responsiblefirm bFirm, @pd_duedate bDate, @pd_findate bDate,
		@itemcontrol varchar(255), @opencursor tinyint, @opencursor2 tinyint, @toseq smallint,
		@findidx int, @copyitem int, @detail_item smallint, @copy_desc varchar(20), @counter int,
		@pmpuud_flag bYN, @pmpiud_flag bYN, @pmpdud_flag bYN, @joins varchar(2000), @where varchar(2000),
		@pmpunotes varchar(max)
   
   select @rcode=1, @msg='Error in copy!', @opencursor = 0, @opencursor2 = 0,
   	   @pmpuud_flag = 'N', @pmpiud_flag = 'N', @pmpdud_flag = 'N'
   
   
   -- set the user memo flags for the tables that have user memos
   if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.bPMPU'))
   	select @pmpuud_flag = 'Y'
   if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.bPMPI'))
   	select @pmpiud_flag = 'Y'
   if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.bPMPD'))
   	select @pmpdud_flag = 'Y'
   
   -- get from punch list data
   select @copy_desc=Description, @pmpunotes = Notes
   from PMPU with (nolock)
   where PMCo = @pmco and Project = @project and PunchList = @frompunchlist
   
   -- first check if PMPU record was created with null values. If true will need to
   -- update with data from @frompunchlist
   if exists(select 1 from PMPU with (nolock) where PMCo=@pmco and Project=@project and PunchList=@topunchlist and Description is null)
   	begin
   	update PMPU set Notes = @pmpunotes
   	where PMCo = @pmco and Project = @project and PunchList = @topunchlist
   	if @pmpuud_flag = 'Y'
   		begin
   		-- build joins and where clause
   		select @joins = ' from bPMPU join bPMPU z with (nolock) on z.PMCo = ' + convert(varchar(3),@pmco) 
   						+ ' and z.Project = ' + CHAR(39) + @project + CHAR(39) 
   						+ ' and z.PunchList = ' + CHAR(39) + @frompunchlist + CHAR(39)
   		select @where = ' where bPMPU.PMCo = ' + convert(varchar(3),@pmco) 
   						+ ' and bPMPU.Project = ' + CHAR(39) + @project + CHAR(39) 
   						+ ' and bPMPU.PunchList = ' + CHAR(39) + @topunchlist + CHAR(39)
   		-- execute user memo update
   		exec @rcode = bspPMProjectCopyUserMemos 'bPMPU', @joins, @where, @msg output
   		end
   	end
   
   
   -- make sure that the topunchlist has no existing items
   if exists (select 1 from PMPI with (nolock) where PMCo = @pmco and Project = @project and PunchList = @topunchlist)
   	begin
   	select @msg = 'Items exist in punchlist ' + @topunchlist + '.  Cannot copy.', @rcode = 1
   	goto bspexit
   	end
   
   -- Set startat to zero if it is being passed into bsp as null
   if @startat is null select @startat = 0
   
   -- Set incrementby to '1' if it is being passed into bsp as zero because it will be used in an expression regardless
   if @incrementby = 0 select @incrementby = 1
   
   -- declare cursor for all items within the from punchlist
   declare bcPMPI cursor fast_forward for
   select Item, Description, VendorGroup, ResponsibleFirm, Location,
   		DueDate, FinDate, BillableYN, BillableFirm, Issue
   from bPMPI with (nolock)
   where PMCo=@pmco and Project=@project and PunchList=@frompunchlist
   and charindex('' + convert(varchar,Item) + '', @items) <> 0
   
   -- open curosr 
   open bcPMPI
   
   -- set flags
   set @opencursor = 1
   set @copyitem = 0
   set @toseq = @startat
   
   -- loop through the from_punchlist items and copy them into the to_punchlist
   process_loop:
   fetch next from bcPMPI into @orig_item, @pi_description, @vendorgroup, @pi_responsiblefirm,
   				@pi_location, @pi_duedate, @pi_findate, @billable, @billablefirm, @issue
   
   if @@fetch_status <> 0 goto process_loop_end
   
   -- get PMPI notes for copy
   --select @pmpinotes = Notes from bPMPI with (nolock) 
   --where PMCo=@pmco and Project=@project and PunchList=@frompunchlist and Item=@orig_item
   --if @@rowcount = 0 select @pmpinotes = null
   
   -- add new items
   begin transaction
   if @renumber='Y'
   	begin
   	-- need to handle resequencing issues with the @toseq variable
   	insert into bPMPI(PMCo, Project, PunchList, Item, Description, VendorGroup, ResponsibleFirm, Location,
   				DueDate, FinDate, BillableYN, BillableFirm, Issue, Notes)
   	select @pmco, @project, @topunchlist, @toseq, @pi_description, @vendorgroup, @pi_responsiblefirm, @pi_location,
   				@pi_duedate, @pi_findate, @billable, @billablefirm, @issue, 
   				d.Notes from bPMPI d with (nolock) where d.PMCo=@pmco and d.Project=@project 
   							and d.PunchList=@frompunchlist and d.Item=@orig_item
   	if @@rowcount <> 0 and @pmpiud_flag = 'Y'
   		begin
   		-- build joins and where clause
   		select @joins = ' from bPMPI join bPMPI z on z.PMCo = ' + convert(varchar(3),@pmco) 
   						+ ' and z.Project = ' + CHAR(39) + @project + CHAR(39) 
   						+ ' and z.PunchList = ' + CHAR(39) + @frompunchlist + CHAR(39)
   						+ ' and z.Item = ' + convert(varchar(6), @orig_item)
   		select @where = ' where bPMPI.PMCo = ' + convert(varchar(3),@pmco) 
   						+ ' and bPMPI.Project = ' + CHAR(39) + @project + CHAR(39) 
   						+ ' and bPMPI.PunchList = ' + CHAR(39) + @topunchlist + CHAR(39)
   						+ ' and bPMPI.Item = ' + convert(varchar(6), @toseq)
   		-- execute user memo update
   		exec @rcode = bspPMProjectCopyUserMemos 'bPMPI', @joins, @where, @msg output
   		end
   	end
   else
   	begin
   	insert into bPMPI(PMCo, Project, PunchList, Item, Description, VendorGroup, ResponsibleFirm, Location,
   					DueDate, FinDate, BillableYN, BillableFirm, Issue, Notes)
   	select @pmco, @project, @topunchlist, @orig_item, @pi_description, @vendorgroup, @pi_responsiblefirm, @pi_location,
   					@pi_duedate, @pi_findate, @billable, @billablefirm, @issue,
   					d.Notes from bPMPI d with (nolock) where d.PMCo=@pmco and d.Project=@project 
   							and d.PunchList=@frompunchlist and d.Item=@orig_item
   	if @@rowcount <> 0 and @pmpiud_flag = 'Y'
   		begin
   		-- build joins and where clause
   		select @joins = ' from bPMPI join bPMPI z on z.PMCo = ' + convert(varchar(3),@pmco) 
   						+ ' and z.Project = ' + CHAR(39) + @project + CHAR(39) 
   						+ ' and z.PunchList = ' + CHAR(39) + @frompunchlist + CHAR(39)
   
   						+ ' and z.Item = ' + convert(varchar(6), @orig_item)
   		select @where = ' where bPMPI.PMCo = ' + convert(varchar(3),@pmco) 
   						+ ' and bPMPI.Project = ' + CHAR(39) + @project + CHAR(39) 
   						+ ' and bPMPI.PunchList = ' + CHAR(39) + @topunchlist + CHAR(39)
   						+ ' and bPMPI.Item = ' + convert(varchar(6), @orig_item)
   		-- execute user memo update
   		exec @rcode = bspPMProjectCopyUserMemos 'bPMPI', @joins, @where, @msg output
   		end
   	end
   
   
   
   select Item from PMPD with (nolock) 
   where PMCo=@pmco and Project=@project and PunchList=@frompunchlist and Item=@orig_item
   if @@rowcount <> 0
   	begin
   	if @renumber = 'Y'
   		begin
   		select @detail_item=@toseq
   		end
   	else
   		begin
   		select @detail_item=@orig_item
   		end
   
   	-- check for existance of PMPD cursor, if exists de-allocate
   	if @opencursor2 = 1
   		begin
   		close bcPMPD
   		deallocate bcPMPD
   		end
   	
   	-- cursor for punch list item detail
   	declare bcPMPD cursor fast_forward for
   	select ItemLine, Description, Location, VendorGroup, ResponsibleFirm, DueDate, FinDate
   	from bPMPD with (nolock)
   	where PMCo=@pmco and Project=@project and PunchList=@frompunchlist and Item=@orig_item
   
   	open bcPMPD
   
   	select @opencursor2 = 1
   
   	process_itemline_loop:
   	fetch next from bcPMPD into @itemline, @pd_description, @pd_location, @vendorgroup, @pd_responsiblefirm, @pd_duedate, @pd_findate
   
   	if @@fetch_status <> 0 goto process_itemloop_end
   
   	insert into bPMPD(PMCo, Project, PunchList, Item, ItemLine, Description, Location,
   				VendorGroup, ResponsibleFirm, DueDate, FinDate)
   	values (@pmco, @project, @topunchlist, @detail_item, @itemline, @pd_description, @pd_location,
   			@vendorgroup, @pd_responsiblefirm, @pd_duedate, @pd_findate)
   	if @@rowcount <> 0 and @pmpdud_flag = 'Y'
   		begin
   		-- build joins and where clause
   		select @joins = ' from bPMPD join bPMPD z on z.PMCo = ' + convert(varchar(3),@pmco) 
   							+ ' and z.Project = ' + CHAR(39) + @project + CHAR(39)
   							+ ' and z.PunchList = ' + CHAR(39) + @frompunchlist + CHAR(39)
   							+ ' and z.Item = ' + convert(varchar(6), @orig_item)
   							+ ' and z.ItemLine = ' + convert(varchar(6), @itemline)
   		select @where = ' where bPMPD.PMCo = ' + convert(varchar(3),@pmco) 
   							+ ' and bPMPD.Project = ' + CHAR(39) + @project + CHAR(39)
   							+ ' and bPMPD.PunchList = ' + CHAR(39) + @topunchlist + CHAR(39)
   							+ ' and bPMPD.Item = ' + convert(varchar(6), @detail_item)
   							+ ' and bPMPD.ItemLine = ' + convert(varchar(6), @itemline)
   		-- execute user memo update
   		exec @rcode = bspPMProjectCopyUserMemos 'bPMPD', @joins, @where, @msg output
   		end
   
   	goto process_itemline_loop
   
   	process_itemloop_end:
   
   	end
   
   -- Had to put the resequencing code here in case line items existed
   if @renumber = 'Y'
   	begin
   	select @toseq = @toseq + @incrementby
   	end
   
   commit transaction
   
   select @copyitem = @copyitem + 1
   goto process_loop
   
   process_loop_end:
   select @msg = convert(varchar(5), @copyitem) + ' items copied.', @rcode=0
   
   
   
   
   bspexit:
   	if @opencursor = 1
      		begin
   		close bcPMPI
   		deallocate bcPMPI
      		end
   	if @opencursor2 = 1
   		begin
   		close bcPMPD
   		deallocate bcPMPD
   		end
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMPunchListCopy] TO [public]
GO
