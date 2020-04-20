SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMImmportDataPhases   Script Date: 05/22/2006 ******/
CREATE proc [dbo].[vspPMImportDataPhases]
/*************************************
 * Created By:	GF 05/23/2006 6.x only
 * Modified By:	GF 10/10/2008 - issue #130158 make sure empty string are set to null
 *				GF 12/01/2008 - issue #131256
 *				GF 02/10/2011 - issue #143294 changed @xnotes to varchar(max)
 *
 *
 * Called from PM Import Data stored procedure to load phase data from PMWX
 * into PMWP for import id.
 *
 *
 * Pass:
 * PMCO			PM Company
 * Template		PM Import Template
 * ImportId		PM Import ID
 * UserName		Viewpoint user name
 * RetainPct	Default Retainage percent
 *
 *
 * Returns:
 * Msg			Returns either an error message or successful completed message
 *
 *
 * Success returns:
 *	0 on Success, 1 on ERROR
 *
 * Error returns:
 *  
 *	1 and error message
 **************************************/
(@pmco bCompany = 0, @template varchar(10) = null, @importid varchar(10) = null,
 @username bVPUserName = null, @retainpct bPct, @msg varchar(500) output)
as
set nocount on

declare @rcode int, @validcnt int, @opencursor int, @seq int, @datarow varchar(max), @errmsg varchar(500)

declare @importroutine varchar(20), @filetype varchar(1), @delimiter varchar(1), @otherdelim varchar(2),
		@defaultsiregion varchar(6), @char varchar(2), @char1 varchar(3), @charpos int, @retstring varchar(max),
		@retstringlist varchar(max), @field varchar(max), @complete tinyint, @counter int,
		@endcharpos int, @itemoption varchar(1), @contractitem bContractItem, @itemdesc bItemDesc,
		@recordtypecol int, @begrectypepos int, @endrectypepos int, @rectypelen int

declare @xitem varchar(60), @xdesc varchar(60), @xphase varchar(60), @xnotes varchar(max),
		@xmisc1 varchar(60), @xmisc2 varchar(60), @xmisc3 varchar(60), @phasegroup bGroup

select @rcode = 0, @complete = 0, @counter = 0, @opencursor = 0

select @xitem = '', @xdesc = '', @xphase = '', @xmisc1 = '', @xmisc2 = '', @xmisc3 = '', @xnotes = ''

if @pmco is null
	begin
	select @msg = 'Missing PM Company!', @rcode = 1
	goto bspexit
	end

if @template is null
	begin
	select @msg = 'Missing Import Template!', @rcode = 1
	goto bspexit
	end

if @importid is null
	begin
	select @msg = 'Missing Import Id!', @rcode = 1
	goto bspexit
	end

if @username is null
	begin
	select @msg = 'Missing Viewpoint User Name!', @rcode = 1
	goto bspexit
	end

------ get phase group from HQCO
select @phasegroup=PhaseGroup from HQCO where HQCo=@pmco
if @@rowcount = 0
	begin
	select @msg = 'Invalid HQ Company, cannot find phase group.', @rcode = 1
	goto bspexit
	end

------ get import template data
select @importroutine=ImportRoutine, @filetype=FileType, @delimiter=Delimiter,
	   @otherdelim=OtherDelim, @defaultsiregion=DefaultSIRegion, @itemoption=ItemOption,
	   @contractitem=ContractItem, @itemdesc=ItemDescription, @recordtypecol=RecordTypeCol,
	   @begrectypepos=BegRecTypePos, @endrectypepos=EndRecTypePos
from PMUT with (nolock) where Template=@template
if @@rowcount = 0
	begin
	select @msg = 'Invalid Import Template!', @rcode = 1
	goto bspexit
	end

------ set record type length for file type = 'F' fixed length
if @filetype = 'F'
	begin
	if @begrectypepos = @endrectypepos
		select @rectypelen = 1
	else
		select @rectypelen = @endrectypepos - @begrectypepos + 1
	end

------ preset the delimiter character
if @delimiter = '0' set @char = char(9)
if @delimiter = '1' set @char = ';'
if @delimiter = '2' set @char = ','
if @delimiter = '3' set @char = char(32)
if @delimiter = '4' set @char = '|'
if @delimiter = '5' set @char = @otherdelim

set @char1 = '"' + @char

/******************************************************************************
 *
 * declare cursor to process data rows from PMWX
 *
 *****************************************************************************/

declare bcPMWX cursor LOCAL FAST_FORWARD for select Seq, DataRow
from PMWX where PMCo=@pmco and ImportId=@importid

------ open cursor
open bcPMWX
select @opencursor = 1, @validcnt = 0

------ cycle thru cursor
process_loop:
fetch next from bcPMWX into @seq, @datarow

if (@@fetch_status <> 0) goto process_loop_end

if @filetype = 'F' goto fixedlength_file
if @filetype = 'D' goto delimited_file
goto process_loop

---------------------------------------------------------------
------ check file type for fixed length and skip if not type '2'
---------------------------------------------------------------
fixedlength_file:
------ skip if record type not (4)
if substring(@datarow, @begrectypepos, @rectypelen) <> '2'
	goto process_loop

------ trim spaces
set @datarow = ltrim(rtrim(@datarow))
if len(@datarow) = 0 goto process_loop
------ fill with spaces to at least 200 characters for parsing substrings
if len(@datarow) < 200 select @datarow = @datarow + SPACE(200)
------parse fixed length data row
set @xitem = ltrim(rtrim(substring(@datarow,14,10)))
set @xdesc = ltrim(rtrim(substring(@datarow,40,30)))
set @xphase = ltrim(rtrim(substring(@datarow,25,14)))
---- set empty strings to null
if @xdesc = '' set @xdesc = null
if @xnotes = '' set @xnotes = null
---- execute stored proc to insert phase record
exec @rcode = dbo.bspPMWPAdd @pmco, @importid, @phasegroup, @xitem, @xphase, @xdesc, @xmisc1, @xmisc2, @xmisc3, @xnotes, @errmsg output
if @rcode <> 0 
	begin
	select @msg = @errmsg, @rcode = 1
	goto bspexit
	end

goto next_phase_record



---------------------------------------------------------------
------ for delimited file 'D' only record type '2' or 'P' valid
------ since the record type column can be any column will need
------ to parse until counter = @recordtypecol
---------------------------------------------------------------
delimited_file:

select @retstring = @datarow, @complete = 0, @counter = 1
if isnull(@retstring,'') = '' goto process_loop
while @complete = 0
BEGIN
----	if substring(@retstring,1,1) = '"'
----		begin
----		exec dbo.vspPMImportParseString @retstring, @char1, @charpos output, @field output, @retstringlist output, @errmsg output
----		select @retstring = substring(@retstringlist,2,len(@retstringlist))
----		end
----	else
		begin
		exec dbo.vspPMImportParseString @retstring, @char, @charpos output, @field output, @retstringlist output, @errmsg output
		select @retstring=@retstringlist
		end
	------ set some values
	set @endcharpos = @charpos
	if len(ltrim(rtrim(@field))) > 0 and substring(ltrim(@field),1,1) = '"'
		begin
		set @field = ltrim(rtrim(@field))
		set @field = substring(@field, 2, len(@field))
		end
	if len(ltrim(rtrim(@field))) > 1 and substring(@field, len(@field), 1) = '"'
		begin
		set @field = ltrim(rtrim(@field))
		set @field = substring(@field, 1, len(@field)-1)
		end
	----set @field = replace(@field,'"','')
	set @field = ltrim(rtrim(@field))
	if @field = '"' set @field = ''
	------ if counter = record type column check record type
	if @counter = @recordtypecol and @field not in ('2','P') goto process_loop
	if @counter = @recordtypecol and @field in ('2','P') goto parse_columns
	------ increment counter and check for end of string
	select @counter = @counter + 1
	if @endcharpos = 0 set @complete = 1
END
----- if we made it here we have a problem in the delimited file where column count never equals record type column
select @msg = 'Unable to parse record type column, check Record Type Column in PM Import Template Master is correct.', @rcode = 1
goto bspexit

------ parse the phase columns and load into PMWP
parse_columns:
select @complete = 0, @counter = 1
while @complete = 0
BEGIN
----	if substring(@datarow,1,1) = '"'
----		begin
----		exec dbo.vspPMImportParseString @datarow, @char1, @charpos output, @field output, @retstringlist output, @errmsg output
----		select @datarow = substring(@retstringlist,2,len(@retstringlist))
----		end
----	else
		begin
		exec dbo.vspPMImportParseString @datarow, @char, @charpos output, @field output, @retstringlist output, @errmsg output
		select @datarow=@retstringlist
		end
	------ set some values
	set @endcharpos = @charpos
	if len(ltrim(rtrim(@field))) > 0 and substring(ltrim(@field),1,1) = '"'
		begin
		set @field = ltrim(rtrim(@field))
		set @field = substring(@field, 2, len(@field))
		end
	if len(ltrim(rtrim(@field))) > 1 and substring(@field, len(@field), 1) = '"'
		begin
		set @field = ltrim(rtrim(@field))
		set @field = substring(@field, 1, len(@field)-1)
		end
	----set @field = replace(@field,'"','')
	set @field = ltrim(rtrim(@field))
	if @field = '"' set @field = ''
	------ only certain columns are currently being used
	if @importroutine = 'Timberline'
		begin
		------ "P","    2.001","Sitework Sub                  ","   ",11202002,0.00,"bd",,,1,"",""
		if @counter = 2 set @xphase = @field
		if @counter = 3 set @xdesc = @field
		if @counter = 5 set @xmisc1 = @field 
		if @counter = 6 set @xmisc2 = @field ------ phase qty
		if @counter = 7 set @xmisc3 = @field ------ phase um
		set @xitem = ''
		if @xmisc2 = '0.00' set @xmisc2 = null
		end
	else
		begin
		if @counter = 3 set @xitem = @field
		if @counter = 4 set @xphase = @field
		if @counter = 5 set @xdesc = @field
		if @counter = 6 set @xnotes = @field
		end
	------ increment counter and check for end of string
	select @counter = @counter + 1
	if @endcharpos = 0 set @complete = 1
END

---- set empty strings to null
if @xdesc = '' set @xdesc = null
if @xnotes = '' set @xnotes = null

---- execute stored proc to insert phase record
exec @rcode = dbo.bspPMWPAdd @pmco, @importid, @phasegroup, @xitem, @xphase, @xdesc, @xmisc1, @xmisc2, @xmisc3, @xnotes, @errmsg output
if @rcode <> 0 
	begin
	select @msg = @errmsg, @rcode = 1
	goto bspexit
	end

goto next_phase_record



	


next_phase_record:
select @xitem = '', @xdesc = '', @xphase = '', @xmisc1 = '', @xmisc2 = '', @xmisc3 = '', @xnotes = ''
select @validcnt = @validcnt + 1
goto process_loop


process_loop_end:
select @msg = 'Phase records: ' + convert(varchar(6),@validcnt) + '. '


























bspexit:
	if @opencursor = 1
		begin
		close bcPMWX
		deallocate bcPMWX
  		select @opencursor = 0
  		end

	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMImportDataPhases] TO [public]
GO
