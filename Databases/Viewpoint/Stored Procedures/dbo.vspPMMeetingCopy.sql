SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************************************/
CREATE  procedure [dbo].[vspPMMeetingCopy]
/************************************************************************
* Created By:	GF 06/287/2005
* Modified By:
*
* Purpose of Stored Procedure
* Copy a meeting from a source project to a destination project.
* Tables copied: PMMM (Meeting Minute), PMMI (Meeting Items)
* PMML (Meeting Item Detail), and PMMD (Meeting Attendees).
* Call from PMMeetingCopy form
*
*
*
* Notes about Stored Procedure
*
*
* returns 0 if successfull
* returns 1 and error msg if failed
*
*************************************************************************/
(@pmco bCompany, @src_project bProject, @dest_project bProject, @vendorgroup bGroup,
 @preparer_firm bVendor, @preparer bEmployee, @meeting_date bDate = null,
 @meetingtype bDocType, @meeting int, @minutestype tinyint, @copy_detail bYN = 'N',
 @copy_attendees bYN = 'N', @msg varchar(255) output)
as
set nocount on

declare @rcode int, @seq int, @errmsg varchar(255), @openpmmm_cursor tinyint, @openpmmi_cursor tinyint,
		@openpmml_cursor tinyint, @pmmmud_flag bYN, @pmmiud_flag bYN, @pmmlud_flag bYN,
		@joins varchar(2000), @where varchar(2000), @inputmask varchar(30), 
		@itemlength varchar(10), @item int, @itemline tinyint, @beg_status bStatus,
		@location varchar(30)

select @rcode = 0, @pmmmud_flag = 'N', @pmmiud_flag = 'N', @pmmlud_flag = 'N',
		@openpmmm_cursor = 0, @openpmmi_cursor = 0, @openpmml_cursor = 0

if @pmco is null
	begin
	select @msg = 'Missing PM Company', @rcode = 1
	goto bspexit
	end

if @src_project is null
	begin
	select @msg = 'Missing source project', @rcode = 1
	goto bspexit
	end

if @dest_project is null
	begin
	select @msg = 'Missing destination project', @rcode = 1
	goto bspexit
	end

if @preparer is null
	begin
	select @msg = 'Missing preparer', @rcode = 1
	goto bspexit
	end

if @meetingtype is null
	begin
	select @msg = 'Missing Meeting Type', @rcode = 1
	goto bspexit
	end


-- -- -- check for submittal user memos
if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.bPMMM'))
	select @pmmmud_flag = 'Y'
if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.bPMMI'))
	select @pmmiud_flag = 'Y'
if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.bPMML'))
	select @pmmlud_flag = 'Y'


-- -- -- get the mask for bDocument
select @inputmask=InputMask, @itemlength = convert(varchar(10), InputLength)
from DDDTShared with (nolock) where Datatype = 'bDocument'
if isnull(@inputmask,'') = '' select @inputmask = 'R'
if isnull(@itemlength,'') = '' select @itemlength = '10'
if @inputmask in ('R','L')
	begin
 	select @inputmask = @itemlength + @inputmask + 'N'
 	end

-- -- -- Default status to first Beginning type status code
-- -- -- use Default Begin status from PMCO if there is one else use from PMSC
select @beg_status = BeginStatus from PMCO with (nolock) where PMCo=@pmco and BeginStatus is not null
if @@rowcount = 0 select @beg_status = min(Status) from PMSC with (nolock) where CodeType = 'B'


-- declare cursor on PMMM Meetings for source project
declare bcPMMM cursor LOCAL FAST_FORWARD for select Location
from PMMM
where PMCo=@pmco and Project=@src_project and MeetingType=@meetingtype and Meeting=@meeting and MinutesType=@minutestype

-- open cursor
open bcPMMM
set @openpmmm_cursor = 1

PMMM_loop:
fetch next from bcPMMM into @location

if @@fetch_status <> 0 goto PMMM_end

-- -- -- if exists in destination project, then do not copy meeting
if exists(select 1 from PMMM where PMCo=@pmco and Project=@dest_project and MeetingType=@meetingtype
							and Meeting=@meeting and MinutesType=@minutestype)
	goto PMMM_loop


-- -- -- copy Meeting Minutes into PMMM if missing in destination project
insert into PMMM (PMCo, Project, MeetingType, MeetingDate, Meeting, MinutesType, MeetingTime, Location,
		Subject, VendorGroup, FirmNumber, Preparer, NextDate, NextTime, NextLocation, Notes)
select @pmco, @dest_project, @meetingtype, isnull(@meeting_date, m.MeetingDate), @meeting, @minutestype, null, m.Location,
		m.Subject, @vendorgroup, @preparer_firm, @preparer, null, null, null, m.Notes
from PMMM m with (nolock) where m.PMCo=@pmco and m.Project=@src_project and m.MeetingType=@meetingtype
and m.Meeting=@meeting and m.MinutesType=@minutestype
if @@rowcount = 0
	begin
	select @msg = 'Error occurred copy source meeting to destination meeting in PMMM.', @rcode = 2
	goto bspexit
	end
-- -- -- copy user memos if any for PMMM
if @pmmmud_flag = 'Y'
	begin
	-- build joins and where clause
	select @joins = ' from PMMM join PMMM z on z.PMCo = ' + convert(varchar(3),@pmco) +
					' and z.Project = ' + CHAR(39) + @src_project + CHAR(39) +
					' and z.MeetingType = ' + CHAR(39) + @meetingtype + CHAR(39) +
					' and z.Meeting = ' + convert(varchar(10), @meeting) +
					' and z.MinutesType = ' + convert(varchar(3), @minutestype)
	select @where = ' where PMMM.PMCo = ' + convert(varchar(3),@pmco) + +
					' and PMMM.Project = ' + CHAR(39) + @dest_project + CHAR(39) +
					' and PMMM.MeetingType = ' + CHAR(39) + @meetingtype + CHAR(39) +
					' and PMMM.Meeting = ' + convert(varchar(10), @meeting) + 
					' and PMMM.MintuesType = ' + convert(varchar(3), @minutestype)
	-- execute user memo update
	exec @rcode = dbo.bspPMProjectCopyUserMemos 'PMMM', @joins, @where, @msg output
	end


-- -- -- attendees are by meeting, if flagged to copy do at this point (PMMD)
if @copy_attendees = 'Y'
	begin
	-- -- -- copy Meeting Attendees PMMD into destination project
	insert into PMMD (PMCo, Project, MeetingType, Meeting, MinutesType, Seq, VendorGroup, FirmNumber, ContactCode, PresentYN)
	select @pmco, @dest_project, @meetingtype, @meeting, @minutestype, d.Seq, d.VendorGroup, d.FirmNumber, d.ContactCode, d.PresentYN
	from PMMD d with (nolock) where d.PMCo=@pmco and d.Project=@src_project and d.MeetingType=@meetingtype
	and d.Meeting=@meeting and d.MinutesType=@minutestype
	and not exists(select top 1 1 from PMMD a with (nolock) where a.PMCo=@pmco and a.Project=@dest_project
					and a.MeetingType=@meetingtype and a.Meeting=@meeting and a.MinutesType=@minutestype and a.Seq=d.Seq)
	end



-- declare cursor on PMMI Meeting items for source project and meeting to copy.
declare bcPMMI cursor LOCAL FAST_FORWARD for select Item
from PMMI
where PMCo=@pmco and Project=@src_project and MeetingType=@meetingtype 
and Meeting=@meeting and MinutesType=@minutestype

-- open cursor
open bcPMMI
set @openpmmi_cursor = 1

PMMI_loop:
fetch next from bcPMMI into @item

if @@fetch_status <> 0 goto PMMI_end

-- -- -- copy Meeting Minutes Items into PMMI if missing in destination project
insert into PMMI (PMCo, Project, MeetingType, Meeting, MinutesType, Item, OriginalItem, Minutes,
		VendorGroup, InitFirm, Initiator, ResponsibleFirm, ResponsiblePerson, InitDate,
		DueDate, FinDate, Status, Issue, Description)
select @pmco, @dest_project, @meetingtype, @meeting, @minutestype, @item, i.OriginalItem, i.Minutes,
		@vendorgroup, i.InitFirm, i.Initiator, i.ResponsibleFirm, i.ResponsiblePerson, i.InitDate,
		null, null, @beg_status, null, i.Description
from PMMI i with (nolock) where i.PMCo=@pmco and i.Project=@src_project and i.MeetingType=@meetingtype
and i.Meeting=@meeting and i.MinutesType=@minutestype and i.Item=@item
and not exists(select top 1 1 from PMMI a with (nolock) where a.PMCo=@pmco and a.Project=@dest_project
				and a.MeetingType=@meetingtype and a.Meeting=@meeting and a.MinutesType=@minutestype and a.Item=@item)
-- -- -- if nothing copied goto next item
if @@rowcount = 0 goto PMMI_loop

-- -- -- copy PMMI user memos if any
if @pmmiud_flag = 'Y'
	begin
	-- build joins and where clause
	select @joins = ' from PMMI join PMMI z on z.PMCo = ' + convert(varchar(3),@pmco) +
					' and z.Project = ' + CHAR(39) + @src_project + CHAR(39) +
					' and z.MeetingType = ' + CHAR(39) + @meetingtype + CHAR(39) +
					' and z.Meeting = ' + convert(varchar(10), @meeting) +
					' and z.MinutesType = ' + convert(varchar(3), @minutestype) +
					' and z.Item = ' + convert(varchar(10), @item)
	select @where = ' where PMMI.PMCo = ' + convert(varchar(3),@pmco) + +
					' and PMMI.Project = ' + CHAR(39) + @dest_project + CHAR(39) +
					' and PMMI.MeetingType = ' + CHAR(39) + @meetingtype + CHAR(39) +
					' and PMMI.Meeting = ' + convert(varchar(10), @meeting) + 
					' and PMMI.MinutesType = ' + convert(varchar(3), @minutestype) +
					' and PMMI.Item = ' + convert(varchar(10), @item)
	-- execute user memo update
	exec @rcode = dbo.bspPMProjectCopyUserMemos 'PMMI', @joins, @where, @msg output
	end

-- -- -- if not copy item detail (PMML) then goto next item in (PMMI)
if @copy_detail <> 'Y' goto PMMI_loop

-- -- -- declare cursor on PMML Meeting Item Detail for source project and meeting to copy.
declare bcPMML cursor LOCAL FAST_FORWARD for select ItemLine
from PMML
where PMCo=@pmco and Project=@src_project and MeetingType=@meetingtype 
and Meeting=@meeting and MinutesType=@minutestype and Item=@item
	
-- -- -- open cursor
open bcPMML
set @openpmml_cursor = 1
	PMML_loop:
fetch next from bcPMML into @itemline
	
if @@fetch_status <> 0 goto PMML_end

-- -- -- copy Meeting Item Detail into PMML if missing in destination project
insert into PMML (PMCo, Project, MeetingType, Meeting, MinutesType, Item, ItemLine, Description,
			VendorGroup, ResponsibleFirm, ResponsiblePerson, InitDate, DueDate, FinDate, Status, Notes)
select @pmco, @dest_project, @meetingtype, @meeting, @minutestype, @item, @itemline, l.Description,
			@vendorgroup, l.ResponsibleFirm, l.ResponsiblePerson, l.InitDate, null, null, @beg_status, l.Notes
from PMML l with (nolock) where l.PMCo=@pmco and l.Project=@src_project and l.MeetingType=@meetingtype
and l.Meeting=@meeting and l.MinutesType=@minutestype and l.Item=@item and l.ItemLine=@itemline
and not exists(select top 1 1 from PMML a with (nolock) where a.PMCo=@pmco and a.Project=@dest_project
					and a.MeetingType=@meetingtype and a.Meeting=@meeting and a.MinutesType=@minutestype 
					and a.Item=@item and a.ItemLine=@itemline)
-- -- -- if nothing copied goto next item
if @@rowcount = 0 goto PMML_loop

-- -- -- copy PMML user memos if any
if @pmmlud_flag = 'Y'
	begin
	-- build joins and where clause
	select @joins = ' from PMML join PMML z on z.PMCo = ' + convert(varchar(3),@pmco) +
						' and z.Project = ' + CHAR(39) + @src_project + CHAR(39) +
						' and z.MeetingType = ' + CHAR(39) + @meetingtype + CHAR(39) +
						' and z.Meeting = ' + convert(varchar(10), @meeting) +
						' and z.MinutesType = ' + convert(varchar(3), @minutestype) +
						' and z.Item = ' + convert(varchar(10), @item) +
						' and z.ItemLine = ' + convert(varchar(3), @itemline)
	select @where = ' where PMML.PMCo = ' + convert(varchar(3),@pmco) + +
						' and PMML.Project = ' + CHAR(39) + @dest_project + CHAR(39) +
						' and PMML.MeetingType = ' + CHAR(39) + @meetingtype + CHAR(39) +
						' and PMML.Meeting = ' + convert(varchar(10), @meeting) + 
						' and PMML.MinutesType = ' + convert(varchar(3), @minutestype) +
						' and PMML.Item = ' + convert(varchar(10), @item) +
						' and PMML.ItemLine = ' + convert(varchar(3), @itemline)
	-- execute user memo update
	exec @rcode = dbo.bspPMProjectCopyUserMemos 'PMML', @joins, @where, @msg output
	end

goto PMML_loop

PMML_end:
	if @openpmml_cursor <> 0
		begin
		close bcPMML
		deallocate bcPMML
		select @openpmml_cursor = 0
		end



goto PMMI_loop

PMMI_end:
     if @openpmmi_cursor <> 0
         begin
         close bcPMMI
         deallocate bcPMMI
         select @openpmmi_cursor = 0
         end



goto PMMM_loop

PMMM_end:
     if @openpmmm_cursor <> 0
         begin
         close bcPMMM
         deallocate bcPMMM
         select @openpmmm_cursor = 0
         end





bspexit:
	if @openpmml_cursor <> 0
		begin
		close bcPMML
		deallocate bcPMML
		select @openpmml_cursor = 0
		end

     if @openpmmi_cursor <> 0
         begin
         close bcPMMI
         deallocate bcPMMI
         select @openpmmi_cursor = 0
         end

     if @openpmmm_cursor <> 0
         begin
         close bcPMMM
         deallocate bcPMMM
         select @openpmmm_cursor = 0
         end

	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMMeetingCopy] TO [public]
GO
