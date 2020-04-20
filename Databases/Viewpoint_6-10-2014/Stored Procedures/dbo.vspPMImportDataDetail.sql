SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMImmportDataDetail   Script Date: 05/24/2006 ******/
CREATE proc [dbo].[vspPMImportDataDetail]
/*************************************
 * Created By:	GF 05/24/2006 6.x only
 * Modified By:	GF 07/24/2008 - issue #129078 check for BillFlag, ItemUnitFlag, PhaseUnitFlag in import record
*				GF 10/10/2008 - issue #130158 make sure empty string are set to null
*				GF 12/01/2008 - issue #131256.
*				GF 05/04/2009 = issue #133531 - remove comma's from numeric strings
 *
 *
 * Called from PM Import Data stored procedure to load cost type detail
 * data from PMWX into PMWD for import id.
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

declare @rcode int, @validcnt int, @opencursor int, @seq int, @datarow varchar(7500), @errmsg varchar(255)

declare @importroutine varchar(20), @filetype varchar(1), @delimiter varchar(1), @otherdelim varchar(2),
		@defaultsiregion varchar(6), @char varchar(2), @char1 varchar(3), @charpos int, @retstring varchar(8000),
		@retstringlist varchar(8000), @field varchar(8000), @complete tinyint, @counter int,
		@endcharpos int, @itemoption varchar(1), @contractitem bContractItem, @itemdesc bItemDesc,
		@recordtypecol int, @begrectypepos int, @endrectypepos int, @rectypelen int

declare @xitem varchar(60), @xphase varchar(60), @xcosttype varchar(60), @xum varchar(60),
		@xbillflag varchar(60), @xitemunitflag varchar(60), @xphaseunitflag varchar(60),
		@xhours varchar(60), @xunits varchar(60), @xcosts varchar(60), @xmisc1 varchar(60),
		@xmisc2 varchar(60), @xmisc3 varchar(60), @phasegroup bGroup, @xnotes varchar(7000),
		@usephaseum bYN, @keepflags varchar(1)

select @rcode = 0, @complete = 0, @counter = 0, @opencursor = 0

select @xitem = '', @xphase = '', @xcosttype = '', @xum = '', @xbillflag = '', @xitemunitflag = '',
	   @xphaseunitflag = '', @xhours = '', @xunits = '', @xcosts = '', @xmisc1 = '',
	   @xmisc2 = '', @xmisc3 = '', @xnotes = '', @keepflags = 'N'

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
	   @begrectypepos=BegRecTypePos, @endrectypepos=EndRecTypePos, @usephaseum=UsePhaseUM
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
------ check file type for fixed length and skip if not type '3'
---------------------------------------------------------------
fixedlength_file:
------ skip if record type not (4)
if substring(@datarow, @begrectypepos, @rectypelen) <> '3'
	goto process_loop

------ trim spaces
set @datarow = ltrim(rtrim(@datarow))
if len(@datarow) = 0 goto process_loop
------ fill with spaces to at least 200 characters for parsing substrings
if len(@datarow) < 200 select @datarow = @datarow + SPACE(200)
------parse fixed length data row
set @xitem = ltrim(rtrim(substring(@datarow,14,10)))
set @xphase = ltrim(rtrim(substring(@datarow,25,14)))
set @xcosttype = ltrim(rtrim(substring(@datarow,40,2)))
set @xunits = ltrim(rtrim(substring(@datarow,42,13)))
set @xum = ltrim(rtrim(substring(@datarow,56,4)))
set @xhours = ltrim(rtrim(substring(@datarow,61,13)))
set @xcosts = ltrim(rtrim(substring(@datarow,75,13)))

if isnull(@xum,'') = '' set @xum = 'LS'

---- set empty strings to null
if @xnotes = '' set @xnotes = null

---- execute stored proc to insert cost type record
exec @rcode = dbo.bspPMWDAdd @pmco, @importid, @phasegroup, @xitem, @xphase, @xcosttype, @xum, @xbillflag, @xitemunitflag,
					@xphaseunitflag, @xhours, @xunits, @xcosts, @xmisc1, @xmisc2, @xmisc3, @xnotes, @errmsg output
if @rcode <> 0 
	begin
	select @msg = @errmsg, @rcode = 1
	goto bspexit
	end

goto next_detail_record





---------------------------------------------------------------
------ for delimited file 'D' only record type '3' or 'C' valid
------ since the record type column can be any column will need
------ to parse until counter = @recordtypecol
---------------------------------------------------------------
delimited_file:
select @retstring = @datarow, @complete = 0, @counter = 1
if isnull(@retstring,'') = '' goto process_loop
while @complete = 0
BEGIN
--	if substring(@retstring,1,1) = '"'
--		begin
--		exec dbo.vspPMImportParseString @retstring, @char1, @charpos output, @field output, @retstringlist output, @errmsg output
--		select @retstring = substring(@retstringlist,2,len(@retstringlist))
--		end
--	else
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
	if @counter = @recordtypecol and @field not in ('3','C') goto process_loop
	if @counter = @recordtypecol and @field in ('3','C') goto parse_columns
	------ increment counter and check for end of string
	select @counter = @counter + 1
	if @endcharpos = 0 set @complete = 1
END
----- if we made it here we have a problem in the delimited file where column count never equals record type column
select @msg = 'Unable to parse record type column, check Record Type Column in PM Import Template Master is correct.', @rcode = 1
goto bspexit

------ parse the phase columns and load into PMWD
parse_columns:
select @complete = 0, @counter = 1
while @complete = 0
BEGIN
--	if substring(@datarow,1,1) = '"'
--		begin
--		exec dbo.vspPMImportParseString @datarow, @char1, @charpos output, @field output, @retstringlist output, @errmsg output
--		select @datarow = substring(@retstringlist,2,len(@retstringlist))
--		end
--	else
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
		------ "C","    1.035","                              ","SUB",11202002,0.00,"",5000.00,,1,"",""
		if @counter = 2 set @xphase = @field
		if @counter = 3 set @xmisc1 = @field
		if @counter = 4 set @xcosttype = @field
		if @counter = 5 set @xmisc2 = @field
		if @counter = 6 set @xunits = @field
		if @counter = 7 set @xum = @field
		if @counter = 8 set @xcosts = @field
		select @xitem = '', @xmisc3 = ''
		IF @xunits = '0.00' set @xunits = ''
		end
	else
		begin
		if @counter = 3 set @xitem = @field
		if @counter = 4 set @xphase = @field
		if @counter = 5 set @xcosttype = @field
		if @counter = 6 set @xunits = @field
		if @counter = 7 set @xum = @field
		if @counter = 8 set @xhours = @field
		if @counter = 9 set @xcosts = @field
		if @counter = 10 set @xbillflag = @field
		if @counter = 10 and isnull(@xbillflag, '') <> '' set @keepflags = 'Y'
		if @counter = 11 set @xitemunitflag = @field
		if @counter = 11 and isnull(@xitemunitflag, '') <> '' set @keepflags = 'Y'
		if @counter = 12 set @xphaseunitflag = @field
		if @counter = 12 and isnull(@xphaseunitflag, '') <> '' set @keepflags = 'Y'
		if @counter = 13 set @xnotes = @field
		if isnull(@xum,'') = '' set @xum = 'LS'
		end
	------ increment counter and check for end of string
	select @counter = @counter + 1
	if @endcharpos = 0 set @complete = 1
END

---- set empty strings to null
if @xnotes = '' set @xnotes = null
if @keepflags = 'Y' set @xmisc3 = 'KeepFlags'
if isnull(@xhours,'') = '' set @xhours = '0'

---- #133531
select @xhours = replace(@xhours,',','')
select @xunits = replace(@xunits,',','')
select @xcosts = replace(@xcosts,',','')

---- execute stored proc to insert cost type record
exec @rcode = dbo.bspPMWDAdd @pmco, @importid, @phasegroup, @xitem, @xphase, @xcosttype, @xum, @xbillflag, @xitemunitflag,
					@xphaseunitflag, @xhours, @xunits, @xcosts, @xmisc1, @xmisc2, @xmisc3, @xnotes, @errmsg output
if @rcode <> 0 
	begin
	select @msg = @errmsg, @rcode = 1
	goto bspexit
	end

goto next_detail_record



	


next_detail_record:
select @xitem = '', @xphase = '', @xcosttype = '', @xum = '', @xbillflag = '', @xitemunitflag = '',
	   @xphaseunitflag = '', @xhours = '', @xunits = '', @xcosts = '', @xmisc1 = '',
	   @xmisc2 = '', @xmisc3 = '', @xnotes = '', @keepflags = 'N'
goto process_loop


process_loop_end:
---- get PMWD record count
select @validcnt = count(*) from PMWD where PMCo=@pmco and ImportId=@importid
select @msg = 'Cost Type records: ' + convert(varchar(6),@validcnt) + '. '


























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
GRANT EXECUTE ON  [dbo].[vspPMImportDataDetail] TO [public]
GO
