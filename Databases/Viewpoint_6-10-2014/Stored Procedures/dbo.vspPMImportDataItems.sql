SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMImmportDataItems   Script Date: 05/22/2006 ******/
CREATE proc [dbo].[vspPMImportDataItems]
/*************************************
* Created:	GF 05/22/2006 6.x only
* Modified: GG 10/16/07 - #125791 - fix for DDDTShared
*			GF 06/16/2008 - issue #128644 not using retainage pct from delimited file
*			GF 10/10/2008 - issue #130158 make sure empty string are set to null
*			GF 12/01/2008 - issue #131256/#131406 problem with items when columns exist for SI but not for retg/notes
*			GF 12/30/2008 - issue #131561 need to use the delimiter when counting columns (was assuming comma)
*			GF 01/13/2008 - issue #131946 problem with item amount calc when missing
*			GF 02/10/2011 - issue #143294 changed @xnotes to varchar(max)
*
*
*
* Called from PM Import Data stored procedure to load item data from PMWX
* into PMWI for import id.
*
*
* Pass:
* PMCO			PM Company
* Template		PM Import Template
* ImportId		PM Import ID
* UserName		Viewpoint user name
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
		@recordtypecol int, @begrectypepos int, @endrectypepos int, @rectypelen int, @pct float

declare @ditem varchar(16), @itemlength varchar(10), @inputmask varchar(30)

declare @xitem varchar(60), @xdesc varchar(60), @xunits varchar(60), @xum varchar(60), @xunitcost varchar(60),
		----#143294
		@xnotes varchar(max), @xsiregion varchar(60), @xsicode varchar(60), @xretpct varchar(60),
		@xmisc1 varchar(60), @xmisc2 varchar(60), @xmisc3 varchar(60), @xamount varchar(60),
		@colcount int, @colmissing tinyint

select @rcode = 0, @complete = 0, @counter = 0, @opencursor = 0, @colcount = 0
select @xitem = '', @xdesc = '', @xunits = '', @xum = '', @xunitcost = '', @xsiregion = '',
	   @xretpct = '', @xmisc1 = '', @xmisc2 = '', @xmisc3 = '', @xnotes = ''

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

------ get input mask for bContractItem and create default item
select @inputmask = InputMask, @itemlength = convert(varchar(10), InputLength)
from dbo.DDDTShared (nolock) where Datatype = 'bContractItem'
if isnull(@inputmask,'') = '' select @inputmask = 'R'
if isnull(@itemlength,'') = '' select @itemlength = '16'
if @inputmask in ('R','L')
	begin
	select @inputmask = @itemlength + @inputmask + 'N'
	end 

exec bspHQFormatMultiPart '1', @inputmask, @ditem output

------ when Item Option = 'I' add one item
if @itemoption = 'I'
	begin
	set @xitem = isnull(@contractitem,@ditem)
	set @xdesc = isnull(@itemdesc,' Add via import process')
	set @xunits = '0'
	set @xum = 'LS'
	set @xunitcost = '0'
	set @xsiregion = @defaultsiregion
	set @xretpct = convert(varchar(15),@retainpct)
	------ check if retain pct > 1 then divide by 100
	set @pct = convert(float, @retainpct)
	if @pct > 1 set @pct = @pct / 100
	set @xretpct = convert(varchar(30), @pct)

	---- set empty strings to null
	if @xdesc = '' set @xdesc = null
	if @xum = '' set @xum = null
	if @xnotes = '' set @xnotes = null

	---- execute stored proc to insert item record
	exec @rcode = dbo.bspPMWIAdd @pmco, @importid, @xitem, @xsiregion, @xsicode, @xdesc, @xum, @xretpct,
					@xamount, @xunits, @xunitcost, @xmisc1, @xmisc2, @xmisc3, @xnotes, @errmsg output
	if @rcode <> 0 
		begin
		select @msg = @errmsg, @rcode = 1
		goto bspexit
		end
	end

if @importroutine = 'Timberline' goto bspexit

/******************************************************************************
 *
 * declare cursor to process item data rows from PMWX
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



----------------------
---- column count ----
----------------------
---- currently Poe has the only format that requires a column count
set @colcount = 0
----select @colcount = (len(@datarow)-len(replace(@datarow,@char,''))+1)





if @filetype = 'F' goto fixedlength_file
if @filetype = 'D' goto delimited_file
goto process_loop

---------------------------------------------------------------
------ check file type for fixed length and skip if not type '1'
---------------------------------------------------------------
fixedlength_file:
------ skip if record type not (1)
if substring(@datarow, @begrectypepos, @rectypelen) <> '1'
	goto process_loop

------ trim spaces
set @datarow = ltrim(rtrim(@datarow))
if len(@datarow) = 0 goto process_loop
------ fill with spaces to at least 411 characters for parsing substrings
if len(@datarow) < 200 select @datarow = @datarow + SPACE(200)
------parse fixed length data row
set @xitem = ltrim(rtrim(substring(@datarow,14,10)))
set @xdesc = ltrim(rtrim(substring(@datarow,25,30)))
set @xunits = ltrim(rtrim(substring(@datarow,56,13)))
set @xum = ltrim(rtrim(substring(@datarow,70,4)))
set @xunitcost = ltrim(rtrim(substring(@datarow,75,13)))
set @xsiregion = @defaultsiregion
set @xretpct = convert(varchar(15),@retainpct)
if isnull(@xum,'') = '' set @xum = 'LS'
------ check if retain pct > 1 then divide by 100
set @pct = convert(float, @retainpct)
if @pct > 1 set @pct = @pct / 100
set @xretpct = convert(varchar(30), @pct)
---- set empty strings to null
if @xdesc = '' set @xdesc = null
if @xum = '' set @xum = null
if @xnotes = '' set @xnotes = null
------ execute stored proc to insert item record
exec @rcode = dbo.bspPMWIAdd @pmco, @importid, @xitem, @xsiregion, @xsicode, @xdesc, @xum, @xretpct,
					@xamount, @xunits, @xunitcost, @xmisc1, @xmisc2, @xmisc3, @xnotes, @errmsg output
if @rcode <> 0 
	begin
	select @msg = @errmsg, @rcode = 1
	goto bspexit
	end

goto next_item_record



---------------------------------------------------------------
------ for delimited file 'D' only record type '1' valid
------ since the record type column can be any column will need
------ to parse until counter = @recordtypecol
---------------------------------------------------------------
delimited_file:
select @retstring = @datarow, @complete = 0, @counter = 1, @colmissing = 0
if isnull(@retstring,'') = '' goto process_loop
while @complete = 0
BEGIN
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
	------ if counter = record type column check record type
	if @counter = @recordtypecol and @field <> '1' goto process_loop
	if @counter = @recordtypecol and @field = '1' goto parse_item_columns
	------ increment counter and check for end of string
	select @counter = @counter + 1
	if @endcharpos = 0 set @complete = 1
END
----- if we made it here we have a problem in the delimited file where column count never equals record type column
select @msg = 'Unable to parse record type column, check Record Type Column in PM Import Template Master is correct.', @rcode = 1
goto bspexit

------ parse the item columns and load into PMWI
parse_item_columns:
select @complete = 0, @counter = 1, @colmissing = 0
while @complete = 0
BEGIN
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

	---- when column count = 10 then no std item and region
----	if @colcount = 9
----		begin
----		---- only certain columns are currently being used
----		if @counter = 3 set @xitem = @field
----		if @counter = 4 set @xsiregion = @field
----		if @counter = 4 and isnull(@field,'') = '' set @colmissing = 1
----		if @counter = 5 set @xdesc = @field
----		if @counter = 5 and isnull(@field,'') = '' set @colmissing = 2
----		if @counter = 6 set @xunits = @field
----		if @counter = 7 set @xum = @field
----		if @counter = 8 set @xunitcost = @field
----		if @counter = 9 set @xamount = @field
----		goto check_item_data
----		end
	---- when column count = 10 then no std item and region
	if @colcount <> 0
		begin
		---- only certain columns are currently being used
		if @counter = 3 set @xitem = @field
		if @counter = 4 set @xdesc = @field
		if @counter = 5 set @xunits = @field
		if @counter = 6 set @xum = @field
		if @counter = 7 set @xunitcost = @field
		if @counter = 8 set @xamount = @field
		if @counter = 9 set @xretpct = @field
		if @counter = 10 set @xnotes = @field
		goto check_item_data
		end
	else
		begin
		---- only certain columns are currently being used
		if @counter = 3 set @xitem = @field
		if @counter = 4 set @xsiregion = @field
		if @counter = 5 set @xsicode = @field
		if @counter = 6 set @xdesc = @field
		if @counter = 7 set @xunits = @field
		if @counter = 8 set @xum = @field
		if @counter = 9 set @xunitcost = @field
		if @counter = 10 set @xamount = @field
		if @counter = 11 set @xretpct = @field
		if @counter = 12 set @xnotes = @field
		end

check_item_data:
	if isnull(@xum,'') = '' set @xum = 'LS'
	if isnull(@xretpct,'') = '' set @xretpct = @retainpct
	if isnull(@xsiregion,'') = '' set @xsiregion = @defaultsiregion
	---- check if retain pct > 1 then divide by 100
	---- #128644
	set @pct = convert(float, @xretpct)
	----set @pct = convert(float, @retainpct)
	if @pct > 1 set @pct = @pct / 100
	set @xretpct = convert(varchar(30), @pct)
	------ increment counter and check for end of string
	select @counter = @counter + 1
	if @endcharpos = 0 set @complete = 1
END
------------------------
---- special ---- #131256
------------------------
if @colcount <> 0 and isnull(@xdesc,'') = '' and isnull(@xunits,'') = '' and isnumeric(convert(float,@xnotes)) = 1
	begin
	set @xsiregion = ''
	set @xsicode = ''
	set @xdesc = @xum
	set @xunits = @xunitcost
	set @xum = @xamount
	set @xunitcost = @xretpct
	set @xamount = @xnotes
	set @xnotes = null
	set @xretpct = @retainpct
	---- check if retain pct > 1 then divide by 100
	---- #128644
	set @pct = convert(float, @xretpct)
	----set @pct = convert(float, @retainpct)
	if @pct > 1 set @pct = @pct / 100
	set @xretpct = convert(varchar(30), @pct)
	end

----------------------------
-------- Brannan change ----
----------------------------
----if @colcount = 9 and @colmissing = 2
----	begin
----	set @xdesc = @xunits
----	set @xunits = @xum
----	set @xum = @xunitcost
----	set @xunitcost = @xamount
----	set @xamount = ''
----	end
----
-------- #128644
----set @pct = convert(float, @xretpct)
--------set @pct = convert(float, @retainpct)
----if @pct > 1 set @pct = @pct / 100
----set @xretpct = convert(varchar(30), @pct)

---- set empty strings to null
if @xdesc = '' set @xdesc = null
if @xum = '' set @xum = null
if @xnotes = '' set @xnotes = null

----select @colcount, @colmissing, @xitem, @xsiregion, @xsicode, @xdesc, @xum, @xunits, @xunitcost, @xamount
----goto next_item_record

------ execute stored proc to insert item record
exec @rcode = dbo.bspPMWIAdd @pmco, @importid, @xitem, @xsiregion, @xsicode, @xdesc, @xum, @xretpct,
					@xamount, @xunits, @xunitcost, @xmisc1, @xmisc2, @xmisc3, @xnotes, @errmsg output
if @rcode <> 0 
	begin
	select @msg = @errmsg, @rcode = 1
	goto bspexit
	end

goto next_item_record

	


next_item_record:
select @xitem = '', @xdesc = '', @xunits = '', @xum = '', @xunitcost = '', @xsiregion = '',
	   @xretpct = '', @xmisc1 = '', @xmisc2 = '', @xmisc3 = '', @xnotes = ''
goto process_loop


process_loop_end:
---- get PMWI record count
select @validcnt = count(*) from PMWI where PMCo=@pmco and ImportId=@importid
select @msg = 'Item records: ' + convert(varchar(6),@validcnt) + '. '


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
GRANT EXECUTE ON  [dbo].[vspPMImportDataItems] TO [public]
GO
