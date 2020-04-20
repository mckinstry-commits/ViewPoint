SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMPunchListCopy    Script Date: 06/22/2005 ******/
CREATE      procedure [dbo].[vspPMPunchListCopy]
/************************************************************************************
 * Created By:	bc 07/15/1998
 * Modified By:	bc 09/18/1998
 *				GF 01/30/2003 - issue #19668 not copying all item detail lines. Need to check
 *								PMPD cursor and de-allocate if needed before next item.
 *				GF 04/04/2003 - issue #	21545 added notes, user memos to copy for PMPI and PMPD
 *				GF 06/22/2005 - 6.x changes
 *
 *
 * This SP will copy one punchlist to another.  Pass in the Punchlist you want made and
 * the punchlist it is derived from.  If the renumber items flag is 'Y', then the parameters
 * pertaining to the renumbering of item numbers are not used.
 * If the copy all items parameter is 'Y' then the item list string are optional, otherwise
 * pass in a delimited string of items to copy (i.e. '1,2,3'). Second item string is optional.
 *
 * Both the from and to punchlists need to exist.
 *
 * Returns either STDBTK_SUCCESS or STDBTK_ERROR and a msg in @msg
 *
 * Pass In
 *	PMCo			PM Company to initialize in
 *	Project			Project to add punchlist to
 *	FromPunchList	PunchList being copied from
 *	ToPunchList		PunchList being created
 *	Items			A comma deliminated string holding all (hopefully) of the desired items to copy
 *	StartAt			The number to begin the new items at
 *	IncrementBy		If renumbering, the amount to increment each item by.  1 is the default.
 *
 * Return Parameters
 *	msg	Error Message or Success message
 *
 * Returns
 *	STDBTK_ERORR on Error, STDBTK_SUCCESS if all is well
 *
 *************************************************************************************/
(@pmco bCompany, @project bJob, @frompunchlist bDocument, @topunchlist bDocument,
 @copyallitems bYN = 'N', @unfinished bYN = 'N', @renumber bYN = 'N', @startat tinyint = 0,
 @incrementby tinyint = 0, @itemlist varchar(8000) = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @opencursor tinyint, @opencursor2 tinyint, @orig_item smallint,
		@pi_description varchar(255), @vendorgroup bGroup, @pi_responsiblefirm bFirm,
		@pi_location varchar(10), @pi_duedate bDate, @pi_findate bDate,
		@billable bYN, @billablefirm bFirm, @issue bIssue, @itemline tinyint, 
		@pd_description varchar(255), @pd_location varchar(10), @pd_responsiblefirm bFirm, 
		@pd_duedate bDate, @pd_findate bDate, @toseq smallint, @copyitem int, @detail_item smallint,
  		@pmpuud_flag bYN, @pmpiud_flag bYN, @pmpdud_flag bYN, @joins varchar(2000),
		@where varchar(2000)

select @rcode=1, @msg='Error in copy!', @opencursor = 0, @opencursor2 = 0,
  	   @pmpuud_flag = 'N', @pmpiud_flag = 'N', @pmpdud_flag = 'N'


-- -- -- when renumbering items check start at and increment by values are not zero
if @renumber = 'Y'
	begin
	if @startat = 0
	  	begin
	  	select @msg = 'When renumbering items, must have a start at value. Cannot copy.', @rcode = 1
	  	goto bspexit
	  	end
	if @incrementby = 0
	  	begin
	  	select @msg = 'When renumbering items, must have a increment by value. Cannot copy.', @rcode = 1
	  	goto bspexit
	  	end
	end

-- -- -- if copy all items flag is 'N', check item lists are not null
if @copyallitems = 'N'
	begin
	if isnull(@itemlist,'') = ''
		begin
	  	select @msg = 'No items selected to copy. Cannot copy.', @rcode = 1
	  	goto bspexit
	  	end
	end

-- -- -- make sure that the to punch list has no existing items
if exists (select 1 from PMPI with (nolock) where PMCo = @pmco and Project = @project and PunchList = @topunchlist)
  	begin
  	select @msg = 'Items exist in punch list: ' + @topunchlist + '.  Cannot copy.', @rcode = 1
  	goto bspexit
  	end

-- -- -- set the user memo flags for the tables that have user memos
if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.bPMPU'))
  	select @pmpuud_flag = 'Y'
if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.bPMPI'))
  	select @pmpiud_flag = 'Y'
if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.bPMPD'))
  	select @pmpdud_flag = 'Y'


-- -- -- first check if to punch list exists. if new add, else check if PMPU record was
-- -- -- created with null values. If true will need to update with data from @frompunchlist
if not exists(select 1 from PMPU with (nolock) where PMCo=@pmco and Project=@project and PunchList=@topunchlist)
	begin
	insert PMPU (PMCo, Project, PunchList, Description, PunchListDate, PrintOption, Notes)
	select @pmco, @project, @topunchlist, a.Description, null, a.PrintOption, a.Notes
	from PMPU a where a.PMCo=@pmco and a.Project=@project and a.PunchList=@frompunchlist
	if @@rowcount <> 0 and @pmpuud_flag = 'Y'
  		begin
  		-- build joins and where clause
  		select @joins = ' from PMPU join PMPU z with (nolock) on z.PMCo = ' + convert(varchar(3),@pmco) 
  						+ ' and z.Project = ' + CHAR(39) + @project + CHAR(39) 
  						+ ' and z.PunchList = ' + CHAR(39) + @frompunchlist + CHAR(39)
  		select @where = ' where PMPU.PMCo = ' + convert(varchar(3),@pmco) 
  						+ ' and PMPU.Project = ' + CHAR(39) + @project + CHAR(39) 
  						+ ' and PMPU.PunchList = ' + CHAR(39) + @topunchlist + CHAR(39)
  		-- execute user memo update
  		exec @rcode = bspPMProjectCopyUserMemos 'PMPU', @joins, @where, @msg output
  		end
	end
else
	begin
	if exists(select 1 from PMPU with (nolock) where PMCo=@pmco and Project=@project 
					and PunchList=@topunchlist and Description is null)
  		begin
  		update PMPU set Description = a.Description, Notes = a.Notes
		from PMPU join PMPU a on a.PMCo=@pmco and a.Project=@project and a.PunchList=@frompunchlist
		where PMPU.PMCo=@pmco and PMPU.Project=@project and PMPU.PunchList=@topunchlist
  		if @pmpuud_flag = 'Y'
  			begin
  			-- build joins and where clause
  			select @joins = ' from PMPU join PMPU z with (nolock) on z.PMCo = ' + convert(varchar(3),@pmco) 
  						+ ' and z.Project = ' + CHAR(39) + @project + CHAR(39) 
  						+ ' and z.PunchList = ' + CHAR(39) + @frompunchlist + CHAR(39)
  			select @where = ' where PMPU.PMCo = ' + convert(varchar(3),@pmco) 
  						+ ' and PMPU.Project = ' + CHAR(39) + @project + CHAR(39) 
  						+ ' and PMPU.PunchList = ' + CHAR(39) + @topunchlist + CHAR(39)
  			-- execute user memo update
  			exec @rcode = bspPMProjectCopyUserMemos 'PMPU', @joins, @where, @msg output
  			end
  		end
	end




-- -- -- Set @startat to zero and @incrementby to 1 if not renumbering items
if @renumber = 'N'
	begin
	select @startat = 0, @incrementby = 1
	end


-- -- -- declare cursor for all items within the from punchlist
declare bcPMPI cursor local fast_forward for select Item
from PMPI
where PMCo=@pmco and Project=@project and PunchList=@frompunchlist

-- -- -- open cursor
open bcPMPI
set @opencursor = 1

-- -- -- set flags
set @copyitem = 0
set @toseq = @startat
  
-- -- -- loop through the from punchlist items and copy them into the to punchlist
process_loop:
fetch next from bcPMPI into @orig_item

if @@fetch_status <> 0 goto process_loop_end

-- -- -- if not copying all items, check to see if item is in the item lists
if @copyallitems = 'N'
	begin
	if charindex(';' + rtrim(convert(varchar(6),@orig_item)) + ';',@itemlist) = 0 goto process_loop
	end

-- -- -- get from punch list item info
select @pi_description=Description, @vendorgroup=VendorGroup, @pi_responsiblefirm=ResponsibleFirm,
  		@pi_location=Location, @pi_duedate=DueDate, @pi_findate=FinDate, @billable=BillableYN,
		@billablefirm=BillableFirm, @issue=Issue
from PMPI where PMCo=@pmco and Project=@project and PunchList=@frompunchlist and Item=@orig_item
if @@rowcount = 0 goto process_loop
-- -- -- if unfinished only check finish date
if @unfinished = 'Y' and isnull(@pi_findate,'') <> '' goto process_loop

-- -- -- add new items
begin transaction
if @renumber='Y'
  	begin
  	-- need to handle resequencing issues with the @toseq variable
  	insert into PMPI(PMCo, Project, PunchList, Item, Description, VendorGroup, ResponsibleFirm, Location,
  				DueDate, FinDate, BillableYN, BillableFirm, Issue, Notes)
  	select @pmco, @project, @topunchlist, @toseq, @pi_description, @vendorgroup, @pi_responsiblefirm, @pi_location,
  				@pi_duedate, @pi_findate, @billable, @billablefirm, @issue, 
  				d.Notes from PMPI d with (nolock) where d.PMCo=@pmco and d.Project=@project 
  							and d.PunchList=@frompunchlist and d.Item=@orig_item
  	if @@rowcount <> 0 and @pmpiud_flag = 'Y'
  		begin
  		-- build joins and where clause
  		select @joins = ' from PMPI join PMPI z on z.PMCo = ' + convert(varchar(3),@pmco) 
  						+ ' and z.Project = ' + CHAR(39) + @project + CHAR(39) 
  						+ ' and z.PunchList = ' + CHAR(39) + @frompunchlist + CHAR(39)
  						+ ' and z.Item = ' + convert(varchar(6), @orig_item)
  		select @where = ' where PMPI.PMCo = ' + convert(varchar(3),@pmco) 
  						+ ' and PMPI.Project = ' + CHAR(39) + @project + CHAR(39) 
  						+ ' and PMPI.PunchList = ' + CHAR(39) + @topunchlist + CHAR(39)
  						+ ' and PMPI.Item = ' + convert(varchar(6), @toseq)
  		-- execute user memo update
  		exec @rcode = bspPMProjectCopyUserMemos 'PMPI', @joins, @where, @msg output
  		end
  	end
else
  	begin
  	insert into PMPI(PMCo, Project, PunchList, Item, Description, VendorGroup, ResponsibleFirm, Location,
  					DueDate, FinDate, BillableYN, BillableFirm, Issue, Notes)
  	select @pmco, @project, @topunchlist, @orig_item, @pi_description, @vendorgroup, @pi_responsiblefirm,
			@pi_location, @pi_duedate, @pi_findate, @billable, @billablefirm, @issue,
  			d.Notes from PMPI d where d.PMCo=@pmco and d.Project=@project and d.PunchList=@frompunchlist and d.Item=@orig_item
  	if @@rowcount <> 0 and @pmpiud_flag = 'Y'
  		begin
  		-- build joins and where clause
  		select @joins = ' from PMPI join PMPI z on z.PMCo = ' + convert(varchar(3),@pmco) 
  						+ ' and z.Project = ' + CHAR(39) + @project + CHAR(39) 
  						+ ' and z.PunchList = ' + CHAR(39) + @frompunchlist + CHAR(39)
  
  						+ ' and z.Item = ' + convert(varchar(6), @orig_item)
  		select @where = ' where PMPI.PMCo = ' + convert(varchar(3),@pmco) 
  						+ ' and PMPI.Project = ' + CHAR(39) + @project + CHAR(39) 
  						+ ' and PMPI.PunchList = ' + CHAR(39) + @topunchlist + CHAR(39)
  						+ ' and PMPI.Item = ' + convert(varchar(6), @orig_item)
  		-- execute user memo update
  		exec @rcode = bspPMProjectCopyUserMemos 'PMPI', @joins, @where, @msg output
  		end
  	end
  



-- -- -- if no lines for item skip line copy section
if not exists(select top 1 1 from PMPD with (nolock) where PMCo=@pmco and Project=@project
					and PunchList=@frompunchlist and Item=@orig_item)
	goto process_itemloop_end


select @detail_item=@orig_item
-- -- -- set PMPD line item depending on whether renumbering
if @renumber = 'Y' select @detail_item=@toseq

-- -- -- cursor for punch list item detail
declare bcPMPD cursor fast_forward for
select ItemLine, Description, Location, VendorGroup, ResponsibleFirm, DueDate, FinDate
from PMPD
where PMCo=@pmco and Project=@project and PunchList=@frompunchlist and Item=@orig_item

-- -- -- open cursor
open bcPMPD
select @opencursor2 = 1

process_itemline_loop:
fetch next from bcPMPD into @itemline, @pd_description, @pd_location, @vendorgroup, @pd_responsiblefirm, @pd_duedate, @pd_findate

if @@fetch_status <> 0 goto process_itemloop_end

insert into PMPD(PMCo, Project, PunchList, Item, ItemLine, Description, Location, VendorGroup, 
				ResponsibleFirm, DueDate, FinDate)
select @pmco, @project, @topunchlist, @detail_item, @itemline, @pd_description, @pd_location, @vendorgroup, 
				@pd_responsiblefirm, @pd_duedate, @pd_findate
if @@rowcount <> 0 and @pmpdud_flag = 'Y'
	begin
	-- -- -- build joins and where clause
	select @joins = ' from PMPD join PMPD z on z.PMCo = ' + convert(varchar(3),@pmco) 
  						+ ' and z.Project = ' + CHAR(39) + @project + CHAR(39)
  						+ ' and z.PunchList = ' + CHAR(39) + @frompunchlist + CHAR(39)
  						+ ' and z.Item = ' + convert(varchar(6), @orig_item)
  						+ ' and z.ItemLine = ' + convert(varchar(6), @itemline)
	select @where = ' where PMPD.PMCo = ' + convert(varchar(3),@pmco) 
  						+ ' and PMPD.Project = ' + CHAR(39) + @project + CHAR(39)
  						+ ' and PMPD.PunchList = ' + CHAR(39) + @topunchlist + CHAR(39)
  						+ ' and PMPD.Item = ' + convert(varchar(6), @detail_item)
  						+ ' and PMPD.ItemLine = ' + convert(varchar(6), @itemline)
  	-- -- -- execute user memo update
  	exec @rcode = bspPMProjectCopyUserMemos 'PMPD', @joins, @where, @msg output
  	end


goto process_itemline_loop



process_itemloop_end:
-- -- -- Had to put the resequencing code here in case line items existed
if @renumber = 'Y' select @toseq = @toseq + @incrementby



process_next_item:
if @opencursor2 = 1
	begin
	close bcPMPD
	deallocate bcPMPD
	select @opencursor2 = 0
	end

commit transaction
select @copyitem = @copyitem + 1

goto process_loop



process_loop_end:
select @msg = convert(varchar(6), @copyitem) + ' items copied.', @rcode=0




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

	if @rcode <> 0 select @msg = isnull(@msg,'') 
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPunchListCopy] TO [public]
GO
