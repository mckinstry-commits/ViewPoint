SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMImmportDataJob   Script Date: 05/22/2006 ******/
CREATE proc [dbo].[vspPMImportDataJob]
/*************************************
 * Created By:	GF 06/17/2006 6.x only
 * Modified By:	GF 03/12/2008 - issue #127076 changed state to varchar(4)
*				GF 10/10/2008 - issue #130158 make sure empty string are set to null
*				GF 12/01/2008 - issue #131256
*
 *
 * Called from PM Import Data stored procedure to load job data into PMWH for import id.
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
(@pmco bCompany = 0, @template varchar(10) = null, @importid varchar(10) = null, @username bVPUserName = null,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @validcnt int, @c1 varchar(7500), @errmsg varchar(255)

declare @importroutine varchar(20), @filetype varchar(1), @delimiter varchar(1), @otherdelim varchar(2),
		@defaultsiregion varchar(6), @char varchar(2), @char1 varchar(3), @charpos int, @retstring varchar(max),
		@retstringlist varchar(max), @field varchar(max), @complete tinyint, @counter int,
		@endcharpos int, @recordtypecol int, @begrectypepos int, @endrectypepos int, @rectypelen int

declare @jobcode varchar(30), @jobdesc bDesc, @jobphone bPhone, @jobfax bPhone, @mailaddress1 varchar(60),
		@mailaddress2 varchar(60), @mailcity varchar(30), @mailstate varchar(4), @mailzip bZip,
		@shipaddress1 varchar(60), @shipaddress2 varchar(60), @shipcity varchar(30), @shipstate varchar(4),
		@shipzip bZip, @jobnotes varchar(7000), @datarow varchar(8000)

select @rcode = 0, @complete = 0, @counter = 0

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
	   @otherdelim=OtherDelim, @defaultsiregion=DefaultSIRegion, @recordtypecol=RecordTypeCol,
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

------ when import routine = 'HCSS' and File Type = 'F' fixed length this is the old HCSS format.
------ no job record available, so load the estimate code into PMWH
if @importroutine = 'HCSS' and @filetype='F'
	begin
	update PMWH set EstimateCode=substring(a.DataRow,3,10), SIRegion=@defaultsiregion
	from PMWX a where a.PMCo=@pmco and a.ImportId=@importid and substring(a.DataRow, @begrectypepos, @rectypelen) = '1'
	and substring(a.DataRow,3,1) <> ' ' and PMWH.PMCo=@pmco and PMWH.ImportId=@importid
	goto bspexit
	end

------ for fixed length and record type '6' job data exists
if @filetype = 'F'
	begin
	if exists(select * from PMWX where PMCo=@pmco and ImportId=@importid and substring(DataRow, @begrectypepos, @rectypelen) = '6')
		begin
		select @datarow = a.DataRow
		from PMWX a where PMCo=@pmco and ImportId=@importid and substring(DataRow, @begrectypepos, @rectypelen) = '6'
		if @@rowcount = 0 goto bspexit
		------ trim spaces
		set @datarow = ltrim(rtrim(@datarow))
		if len(@datarow) = 0 goto bspexit
		------ fill with spaces to at least 411 characters for parsing substrings
		if len(@datarow) < 412 select @datarow = @datarow + SPACE(411)
		------parse fixed length data row
		set @jobcode = ltrim(rtrim(substring(@datarow,3,10)))
		set @jobdesc = ltrim(rtrim(substring(@datarow,13,30)))
		set @jobphone = ltrim(rtrim(substring(@datarow,43,20)))
		set @jobfax = ltrim(rtrim(substring(@datarow,63,20)))
		set @mailaddress1 = ltrim(rtrim(substring(@datarow,83,60)))
		set @mailaddress2 = ltrim(rtrim(substring(@datarow,143,60)))
		set @mailcity = ltrim(rtrim(substring(@datarow,203,30)))
		set @mailstate = ltrim(rtrim(substring(@datarow,233,2)))
		set @mailzip = ltrim(rtrim(substring(@datarow,235,12)))
		set @shipaddress1 = ltrim(rtrim(substring(@datarow,247,60)))
		set @shipaddress2 = ltrim(rtrim(substring(@datarow,307,60)))
		set @shipcity = ltrim(rtrim(substring(@datarow,367,30)))
		set @shipstate = ltrim(rtrim(substring(@datarow,397,2)))
		set @shipzip = ltrim(rtrim(substring(@datarow,399,12)))
		set @jobnotes = ltrim(rtrim(substring(@datarow,411,len(@datarow))))

		---- set empty strings to null
		if @jobdesc = '' set @jobdesc = null
		if @jobphone = '' set @jobphone = null
		if @jobfax = '' set @jobfax = null
		if @mailaddress1 = '' set @mailaddress1 = null
		if @mailaddress2 = '' set @mailaddress2 = null
		if @mailcity = '' set @mailcity = null
		if @mailstate = '' set @mailstate = null
		if @mailzip = '' set @mailzip = null
		if @shipaddress1 = '' set @shipaddress1 = null
		if @shipaddress2 = '' set @shipaddress2 = null
		if @shipcity = '' set @shipcity = null
		if @shipstate = '' set @shipstate = null
		if @shipzip = '' set @shipzip = null
		if @jobnotes = '' set @jobnotes = null

		------ update PMWH
		update PMWH set EstimateCode=@jobcode, Description=@jobdesc, JobPhone=@jobphone, JobFax=@jobfax,
				MailAddress=@mailaddress1, MailCity=@mailcity, MailState=@mailstate, MailZip=@mailzip,
				MailAddress2=@mailaddress2, ShipAddress=@shipaddress1, ShipCity=@shipcity, ShipState=@shipstate,
				ShipZip=@shipzip, ShipAddress2=@shipaddress2, SIRegion=@defaultsiregion, Notes=@jobnotes
		where PMCo=@pmco and ImportId=@importid
		goto bspexit
		end
	else
		begin
		update PMWH set EstimateCode=substring(a.DataRow,3,10), SIRegion=@defaultsiregion
		from PMWX a where a.PMCo=@pmco and a.ImportId=@importid and substring(a.DataRow, @begrectypepos, @rectypelen) = '1'
		and substring(a.DataRow,3,1) <> ' ' and PMWH.PMCo=@pmco and PMWH.ImportId=@importid
		goto bspexit
		end
	end

------ process delimited text file for timberline record type value '*'
if @filetype = 'D' and @importroutine = 'Timberline'
	begin
	select @datarow = DataRow
	from PMWX where PMCo=@pmco and ImportId=@importid and substring(DataRow,1,1) = '*'
	if @@rowcount = 0 goto bspexit
	------ parse data row column 1 - record type
	exec dbo.vspPMImportParseString @datarow, @char, @charpos output, @field output, @retstringlist output, @errmsg output
	set @datarow=@retstringlist
	------ check if more data exists
	if @charpos = 0 goto bspexit

	------ @complete = 0 then more columns to parse
	while @complete = 0
	BEGIN
----		if substring(@datarow,1,1) = '"'
----			begin
----			exec dbo.vspPMImportParseString @datarow, @char1, @charpos output, @field output, @retstringlist output, @errmsg output
----			select @datarow = substring(@retstringlist,2,len(@retstringlist))
----			end
----		else
			begin
			exec dbo.vspPMImportParseString @datarow, @char, @charpos output, @field output, @retstringlist output, @errmsg output
			select @datarow=@retstringlist
			end

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
		------ set PMWH columns
		------ "*","1357","1357 Greenland-Viewpoint","","","","","","","","","",53413,"sf",1,"",""
		if @counter = 0 select @jobcode = @field
		if @counter = 1 select @jobdesc = @field
		if @counter = 2 select @jobphone = @field
		if @counter = 3 select @mailaddress1 = @field
		if @counter = 4 select @mailcity = @field
		if @counter = 5 select @mailstate = @field
		if @counter = 6 select @mailzip = @field

		select @counter = @counter + 1
		if @endcharpos = 0 set @complete = 1
	END

	---- set empty strings to null
	if @jobdesc = '' set @jobdesc = null
	if @jobphone = '' set @jobphone = null
	if @jobfax = '' set @jobfax = null
	if @mailaddress1 = '' set @mailaddress1 = null
	if @mailaddress2 = '' set @mailaddress2 = null
	if @mailcity = '' set @mailcity = null
	if @mailstate = '' set @mailstate = null
	if @mailzip = '' set @mailzip = null
	if @shipaddress1 = '' set @shipaddress1 = null
	if @shipaddress2 = '' set @shipaddress2 = null
	if @shipcity = '' set @shipcity = null
	if @shipstate = '' set @shipstate = null
	if @shipzip = '' set @shipzip = null
	if @jobnotes = '' set @jobnotes = null

	------ update PMWH
	update PMWH set EstimateCode=@jobcode, Description=@jobdesc, JobPhone=@jobphone, JobFax=@jobfax,
				MailAddress=@mailaddress1, MailCity=@mailcity, MailState=@mailstate, MailZip=@mailzip,
				MailAddress2=@mailaddress2, ShipAddress=@shipaddress1, ShipCity=@shipcity, ShipState=@shipstate,
				ShipZip=@shipzip, ShipAddress2=@shipaddress2, SIRegion=@defaultsiregion, Notes=@jobnotes
	where PMCo=@pmco and ImportId=@importid
	goto bspexit
	end



------ process delimited text file with no job record (6)
if @filetype='D'
	begin
	if not exists(select * from PMWX where PMCo=@pmco and ImportId=@importid and substring(DataRow,1,1) = '6')
		begin
		select @datarow = min(DataRow)
		from PMWX where PMCo=@pmco and ImportId=@importid and substring(DataRow,1,1) in(1,2,3)
		if @@rowcount = 0 goto bspexit
		------ parse data row column 1 - record type
		exec dbo.vspPMImportParseString @datarow, @char, @charpos output, @jobcode output, @retstringlist output, @errmsg output
		set @datarow=@retstringlist
		if len(ltrim(rtrim(@jobcode))) > 0 and substring(ltrim(@jobcode),1,1) = '"'
			begin
			set @jobcode = ltrim(rtrim(@jobcode))
			set @jobcode = substring(@jobcode, 2, len(@jobcode))
			end
		---- parse data row - job code
		exec dbo.vspPMImportParseString @datarow, @char, @charpos output, @jobcode output, @retstringlist output, @errmsg output
		if len(ltrim(rtrim(@jobcode))) > 0 and substring(ltrim(@jobcode),1,1) = '"'
			begin
			set @jobcode = ltrim(rtrim(@jobcode))
			set @jobcode = substring(@jobcode, 2, len(@jobcode))
			end
		---- update PMWH
		update PMWH set EstimateCode=@jobcode, SIRegion=@defaultsiregion
		where PMWH.PMCo=@pmco and PMWH.ImportId=@importid
		goto bspexit
		end
	end

------ process delimited text file with job record (6)
if @filetype = 'D'
	begin
	select @datarow = DataRow
	from PMWX where PMCo=@pmco and ImportId=@importid and substring(DataRow,1,1) = '6'
	if @@rowcount = 0 goto bspexit
	------ parse data row column 1 - record type
	exec dbo.vspPMImportParseString @datarow, @char, @charpos output, @field output, @retstringlist output, @errmsg output
	set @datarow=@retstringlist
	------ check if more data exists
	if @charpos = 0 goto bspexit

	------ @complete = 0 then more columns to parse
	while @complete = 0
	BEGIN
----		if substring(@datarow,1,1) = '"'
----			begin
----			exec dbo.vspPMImportParseString @datarow, @char1, @charpos output, @field output, @retstringlist output, @errmsg output
----			select @datarow = substring(@retstringlist,2,len(@retstringlist))
----			end
----		else
			begin
			exec dbo.vspPMImportParseString @datarow, @char, @charpos output, @field output, @retstringlist output, @errmsg output
			select @datarow=@retstringlist
			end

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
		------ set PMWH columns
		if @counter = 0 select @jobcode = @field
		if @counter = 1 select @jobdesc = @field
		if @counter = 2 select @jobphone = @field
		if @counter = 3 select @jobfax = @field
		if @counter = 4 select @mailaddress1 = @field
		if @counter = 5 select @mailaddress2 = @field
		if @counter = 6 select @mailcity = @field
		if @counter = 7 select @mailstate = @field
		if @counter = 8 select @mailzip = @field
		if @counter = 9 select @shipaddress1 = @field
		if @counter = 10 select @shipaddress2 = @field
		if @counter = 11 select @shipcity = @field
		if @counter = 12 select @shipstate = @field
		if @counter = 13 select @shipzip = @field
		if @counter = 14 select @jobnotes = @field

		select @counter = @counter + 1
		if @endcharpos = 0 set @complete = 1
	END

	---- set empty strings to null
	if @jobdesc = '' set @jobdesc = null
	if @jobphone = '' set @jobphone = null
	if @jobfax = '' set @jobfax = null
	if @mailaddress1 = '' set @mailaddress1 = null
	if @mailaddress2 = '' set @mailaddress2 = null
	if @mailcity = '' set @mailcity = null
	if @mailstate = '' set @mailstate = null
	if @mailzip = '' set @mailzip = null
	if @shipaddress1 = '' set @shipaddress1 = null
	if @shipaddress2 = '' set @shipaddress2 = null
	if @shipcity = '' set @shipcity = null
	if @shipstate = '' set @shipstate = null
	if @shipzip = '' set @shipzip = null
	if @jobnotes = '' set @jobnotes = null

	------ update PMWH
	update PMWH set EstimateCode=@jobcode, Description=@jobdesc, JobPhone=@jobphone, JobFax=@jobfax,
				MailAddress=@mailaddress1, MailCity=@mailcity, MailState=@mailstate, MailZip=@mailzip,
				MailAddress2=@mailaddress2, ShipAddress=@shipaddress1, ShipCity=@shipcity, ShipState=@shipstate,
				ShipZip=@shipzip, ShipAddress2=@shipaddress2, SIRegion=@defaultsiregion, Notes=@jobnotes
	where PMCo=@pmco and ImportId=@importid
	goto bspexit
	end





















bspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'') 
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMImportDataJob] TO [public]
GO
