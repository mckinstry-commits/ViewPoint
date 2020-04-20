SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMImmportDataSubs   Script Date: 05/24/2006 ******/
CREATE proc [dbo].[vspPMImportDataSubs]
/*************************************
 * Created By:	GF 05/24/2006 6.x only
 * Modified By:	GF 10/10/2008 - issue #130158 make sure empty string are set to null
 *				GF 12/01/2008 - issue #131256
 *				GF 02/10/2011 - issue #143294 changed @xnotes to varchar(max)
 *
 *
 * Called from PM Import Data stored procedure to load subcontract detail
 * data from PMWX into PMWS for import id.
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

declare @xitem varchar(60), @xphase varchar(60), @xcosttype varchar(60), @xunits varchar(60),
		@xum varchar(60), @xunitcost varchar(60), @xwcretgpct varchar(60), @xvendor varchar(60),
		----#143294
		@xdescription varchar(60), @xnotes varchar(max), @xecm varchar(60), @xamount varchar(60),
		@xmisc1 varchar(60), @xmisc2 varchar(60), @xmisc3 varchar(60), @units decimal(16,3), 
		@unitcost decimal(16,5), @amount decimal(16,2), @phasegroup bGroup, @matlgroup bGroup,
		@vendorgroup bGroup, @apco bCompany, @pct float

select @rcode = 0, @complete = 0, @counter = 0, @opencursor = 0

select @xitem = '', @xphase = '', @xcosttype = '', @xunits = '', @xum = '', @xunitcost = '',
	   @xwcretgpct = '', @xvendor = '', @xdescription = '', @xecm = '', @xamount = '', @xmisc1 = '',
	   @xmisc2 = '', @xmisc3 = '', @xnotes = ''

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
select @phasegroup=PhaseGroup, @matlgroup=MatlGroup from HQCO where HQCo=@pmco
if @@rowcount = 0
	begin
	select @msg = 'Invalid HQ Company, cannot find phase group.', @rcode = 1
	goto bspexit
	end

------ get PMCO.APCo
select @apco = APCo from PMCO where PMCo=@pmco
if @@rowcount = 0 select @apco = @pmco

------ get vendor group from HQCO
select @vendorgroup=VendorGroup from HQCO where HQCo=@apco
if @@rowcount = 0
	begin
	select @msg = 'Invalid HQ Company, cannot find vendor group.', @rcode = 1
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
------ check file type for fixed length and skip if not type '4'
---------------------------------------------------------------
fixedlength_file:
------ skip if record type not (4)
if substring(@datarow, @begrectypepos, @rectypelen) <> '4'
	goto process_loop

------ trim spaces
set @datarow = ltrim(rtrim(@datarow))
if len(@datarow) = 0 goto process_loop
------ fill with spaces to at least 800 characters for parsing substrings
if len(@datarow) < 800 select @datarow = @datarow + SPACE(800)
------ parse fixed length data row
set @xitem = ltrim(rtrim(substring(@datarow,14,10)))
set @xphase = ltrim(rtrim(substring(@datarow,25,14)))
set @xcosttype = ltrim(rtrim(substring(@datarow,40,1)))
set @xunits = ltrim(rtrim(substring(@datarow,42,14)))
set @xum = ltrim(rtrim(substring(@datarow,57,4)))
set @xunitcost = ltrim(rtrim(substring(@datarow,62,14)))
set @xecm = 'E'
set @xvendor = ltrim(rtrim(substring(@datarow,77,6)))
set @xwcretgpct = convert(varchar(20), isnull(@retainpct,0))
------ check values
if isnull(@xum,'') = '' set @xum = 'LS'
if isnull(@xunits,'') = '' set @xunits = '0'
if isnull(@xunitcost,'') = '' set @xunitcost = '0'
------ calculate amount
select @units = convert(decimal(16,3), @xunits)
select @unitcost = convert(decimal(16,5), @xunitcost)
select @amount = @units * @unitcost
select @xamount = convert(varchar(30),@amount)

---- check for lump sum with units
if @xum='LS' and @units = 1
	begin
	select @units = 0
	end

---- set empty strings to null
if @xdescription = '' set @xdescription = null
if @xum = '' set @xum = null
if @xnotes = '' set @xnotes = null

------ execute stored proc to insert subcontract record
exec @rcode = dbo.bspPMWSAdd @pmco, @importid, @phasegroup, @vendorgroup, @xitem, @xphase, @xcosttype, @xvendor, @xum,
		@xdescription, @xunits, @xunitcost, @xecm, @xamount, @xwcretgpct, @xmisc1, @xmisc2, @xmisc3, @xnotes, @errmsg output
if @rcode <> 0 
	begin
	select @msg = @errmsg, @rcode = 1
	goto bspexit
	end

goto next_subcontract_record



---------------------------------------------------------------
------ for delimited file 'D' only record type '4' valid
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
	if @counter = @recordtypecol and @field <> '4' goto next_subcontract_record
	if @counter = @recordtypecol and @field = '4' goto parse_columns
	------ increment counter and check for end of string
	select @counter = @counter + 1
	if @endcharpos = 0 set @complete = 1
END
----- if we made it here we have a problem in the delimited file where column count never equals record type column
select @msg = 'Unable to parse record type column, check Record Type Column in PM Import Template Master is correct.', @rcode = 1
goto bspexit



parse_columns:
------ parse the subcontract columns and load into PMWS
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
	if @counter = 3 set @xitem = @field
	if @counter = 4 set @xphase = @field
	if @counter = 5 set @xcosttype = @field
	if @counter = 6 set @xunits = @field
	if @counter = 7 set @xum = @field
	if @counter = 8 set @xunitcost = @field
	if @counter = 9 set @xwcretgpct = @field
	if @counter = 10 set @xvendor = @field
	if @counter = 11 set @xdescription = @field
	if @counter = 12 set @xnotes = @field
	------ check wc retg pct
	if isnull(@xwcretgpct,'') = '' set @xwcretgpct = convert(varchar(30),@retainpct)
	------ check if wc retg pct > 1 then divide by 100
	set @pct = convert(float, @xwcretgpct)
	if @pct > 1 set @pct = @pct / 100
	set @xwcretgpct = convert(varchar(30), @pct)
	------ check values
	set @xecm = 'E'
	if isnull(@xum,'') = '' set @xum = 'LS'
	if isnull(@xecm,'') = '' set @xecm = 'E'
	if isnull(@xunits,'') = '' set @xunits = '0'
	if isnull(@xunitcost,'') = '' set @xunitcost = '0'
	------ calculate amount
	select @units = convert(decimal(16,3), @xunits)
	select @unitcost = convert(decimal(16,5), @xunitcost)
	select @amount = @units * @unitcost
	select @xamount = convert(varchar(30),@amount)
	------ increment counter and check for end of string
	select @counter = @counter + 1
	if @endcharpos = 0 set @complete = 1
END

---- set empty strings to null
if @xdescription = '' set @xdescription = null
if @xum = '' set @xum = null
if @xnotes = '' set @xnotes = null

------ execute stored proc to insert subcontract record
exec @rcode = dbo.bspPMWSAdd @pmco, @importid, @phasegroup, @vendorgroup, @xitem, @xphase, @xcosttype, @xvendor, @xum,
		@xdescription, @xunits, @xunitcost, @xecm, @xamount, @xwcretgpct, @xmisc1, @xmisc2, @xmisc3, @xnotes, @errmsg output
if @rcode <> 0 
	begin
	select @msg = @errmsg, @rcode = 1
	goto bspexit
	end

goto next_subcontract_record


	




next_subcontract_record:
select @xitem = '', @xphase = '', @xcosttype = '', @xunits = '', @xum = '', @xunitcost = '',
	   @xwcretgpct = '', @xvendor = '', @xdescription = '', @xecm = '', @xamount = '', @xmisc1 = '',
	   @xmisc2 = '', @xmisc3 = '', @xnotes = ''
goto process_loop


process_loop_end:
---- get PMWS record count
select @validcnt = count(*) from PMWS where PMCo=@pmco and ImportId=@importid
select @msg = 'Subcontract records: ' + convert(varchar(6),@validcnt) + '. '


























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
GRANT EXECUTE ON  [dbo].[vspPMImportDataSubs] TO [public]
GO
