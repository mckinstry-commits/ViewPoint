SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.vspPMImmportDataBulk    Script Date: 05/17/2006 ******/
CREATE proc [dbo].[vspPMImportDataBulk]
/*************************************
 * Created By:	GF 05/31/2006 6.x only
 * Modified By:	GP 03/02/2009 - 126939, needed to make the check for matching record type
 *									more dynamic.
 *				GP 10/23/2009 - 136136, remove trailing quotation mark.
 *				GP 12/14/2009 - 136451, added update to set RecType field in bPMWX.
 *				GF 02/10/2010 - issue #138042 - changes to store the import value not formatted to our data type.
 *				GF 02/16/2010 - issue #138062 - change for bulk parse to not validate data type
 *				GF 05/06/2010 - issue #140048 - change to check for single quote in data row beg/end position and cleanup
 *				GF 09/10/2010 - issue #141031 changed to use vfDateOnly
 *				GF 04/23/2011 - issue #143831 D-01660
 *				GF 01/06/2011 - TK-11537 expand ColumnName to 128 characters.
 *
 *
 *
 * Called from PM Import Data form to create PMWH record, remove old import data
 * from tables if needed, and bulk insert the text file(s) into a temp table.
 *
 *
 * Pass:
 * PMCO			PM Company
 * Template		PM Import Template
 * ImportId		PM Import ID
 * RetainPct	Default Retainage Percent
 * ImportFile1	Import file 1 name (using UNC path)
 * ImportFile2	Import file 2 name (using UNC path)
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
 @retainpct bPct = 0, @importfile1 varchar(255) = null, @importfile2 varchar(255) = null,
 @username bVPUserName = null, @importtable varchar(255), @msg varchar(500) output)
as
set nocount on

declare @rcode int, @validcnt int, @c1 varchar(max), @temptablefilename varchar(255),
		@errmsg varchar(500), @sqlstring varchar(1000), @executestring NVARCHAR(1000),
		@paramsin nvarchar(1000)

declare @importroutine varchar(128), @filetype varchar(1), @delimiter varchar(1), @otherdelim varchar(2),
		@recordtypecol int, @begrectypepos int, @endrectypepos int, @rectypelen int,
		@opencursor int, @char varchar(2), @char1 varchar(3), @charpos int, @retstring varchar(max),
		@retstringlist varchar(max), @field varchar(max), @complete tinyint, @counter int,
		@endcharpos int, @seq int, @datarow varchar(max), @phasegroup bGroup,
		@userroutine varchar(128)

declare @ReturnRecType varchar(20), @RecType varchar(20) --126939

--126939 and #138042
create table #ColumnValues ( 
	Seq int, 
	Template varchar(20),
	----TK-11537
	ColumnName varchar(128),
	Value varchar(max),
	ImportValue varchar(max))

select @rcode = 0, @complete = 0, @counter = 0, @opencursor = 0

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

if @importfile1 is null
	begin
	select @msg = 'Missing Import File One!', @rcode = 1
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
select @importroutine=ImportRoutine, @filetype=FileType, @delimiter=Delimiter, @otherdelim=OtherDelim,
	   @recordtypecol=RecordTypeCol, @begrectypepos=BegRecTypePos, @endrectypepos=EndRecTypePos,
	   @userroutine=UserRoutine
from PMUT with (nolock) where Template=@template
if @@rowcount = 0
	begin
	select @msg = 'Invalid Import Template!', @rcode = 1
	goto bspexit
	end

if @filetype NOT IN ('D','F')
	begin
	select @msg = 'Currently only (F)ixed length and (D)elimited file types can be processed.', @rcode = 1
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


---------- create temp table to bulk insert into
----create table #xPMData (c1 varchar(7500))
----
---------- bulk insert @importfile1 into xpmimportrawdata table
----select @sqlstring = '', @executestring = ''
----select @sqlstring = 'BULK INSERT #xPMData FROM ''' + @importfile1 + ''' WITH (DATAFILETYPE = ''char'', FIELDTERMINATOR = '''', ROWTERMINATOR = ''\n'' )' ------''' WITH {KEEPIDENTITY, DATAFILETYPE = ''char'', FIELDTERMINATOR = '''',ROWTERMINATOR = ''\n'' )'
----select @executestring = cast(@sqlstring as NVarchar(1000))
----exec sp_executesql @executestring
----
----
----select @sqlstring = '', @executestring = ''
---------- bulk insert @importfile2 into temp table if exists
----if isnull(@importfile2,'') <> ''
----	begin
----	select @sqlstring = 'BULK INSERT #xPMData FROM ''' + @importfile2 + ''' WITH (DATAFILETYPE = ''char'', FIELDTERMINATOR = '''',ROWTERMINATOR = ''\n'' )'
----	select @executestring = cast(@sqlstring as NVarchar(1000))
----	exec sp_executesql @executestring
----	end


---- add identity column to temp table
select @sqlstring = 'alter table '  + @importtable + ' add c2 int identity(1,1)'
select @executestring = cast(@sqlstring as NVarchar(1000))
exec sp_executesql @executestring
---- alter table @importtable add c2 int identity(1,1)

---- change identity column to not null
select @sqlstring = 'alter table ' + @importtable + ' alter column c2 int not null'
select @executestring = cast(@sqlstring as NVarchar(1000))
exec sp_executesql @executestring
----alter table @importtable alter column c2 int not null

---- check to see if Import Id exists in PMWH - delete information if exists
if exists(select * from PMWH where PMCo=@pmco and ImportId=@importid)
	begin
	delete from PMWH where PMWH.PMCo=@pmco and PMWH.ImportId=@importid
	end

---- insert new import id into PMWH
if not exists(select * from PMWH where PMCo=@pmco and ImportId=@importid)
	begin
	insert into PMWH (ImportId,Template,PMCo,ImportDate,ImportBy)
	select @importid, @template, @pmco, dbo.vfDateOnly(), @username
	end

---- before inserting data, clear out any existing data in PMWX for ImportId
if exists(select PMCo from PMWX where PMCo=@pmco and ImportId=@importid)
	begin
	delete PMWX where PMCo=@pmco and ImportId=@importid
	end

---- insert raw data from temp table into PMWX
select @sqlstring = 'insert PMWX(PMCo, ImportId, Seq, DataRow) select ' + convert(varchar(3),@pmco) + ', ' + char(39) + @importid + char(39) + ', a.c2, a.c1 from ' + @importtable + ' a where 1=1'
select @executestring = cast(@sqlstring as NVarchar(1000))
set @paramsin = N'@pmco tinyint, @importid varchar(10), @importtable varchar(255)'
EXECUTE sp_executesql @executestring, @paramsin, @pmco, @importid, @importtable
----insert into PMWX (PMCo, ImportId, Seq, DataRow)
----select @pmco, @importid, a.c2, a.c1
----from @importtable a where 1=1

---- cleanup data in PMWX
--136136 remove trailing quotation mark if quotation marks exist in beg and end pos of datarow
update PMWX set DataRow = substring(a.DataRow,1, len(a.DataRow)-1)
from PMWX a where a.PMCo=@pmco and a.ImportId=@importid and substring(a.DataRow, len(a.DataRow), 1) = '"'
----#143831 D-01660
and substring(a.DataRow, 1, 1) = '"' AND SUBSTRING(a.DataRow,3,1) <> '"'

---- check for text qualifier in first position and remove
update PMWX set DataRow = substring(a.DataRow,2, len(a.DataRow))
from PMWX a where a.PMCo=@pmco and a.ImportId=@importid and substring(a.DataRow,1,1) = '"'
---- check for text qualifier in second position and remove
update PMWX set DataRow = substring(a.DataRow,1,1) + substring(a.DataRow,3, len(a.DataRow))
from PMWX a where a.PMCo=@pmco and a.ImportId=@importid and substring(a.DataRow,2,1) = '"'

----#140048 check for single quotes
update PMWX set DataRow = substring(a.DataRow,1, len(a.DataRow)-1)
from PMWX a where a.PMCo=@pmco and a.ImportId=@importid and substring(a.DataRow, len(a.DataRow), 1) = CHAR(39)
	and substring(a.DataRow, 1, 1) = CHAR(39)
---- check for text qualifier in first position and remove
update PMWX set DataRow = substring(a.DataRow,2, len(a.DataRow))
from PMWX a where a.PMCo=@pmco and a.ImportId=@importid and substring(a.DataRow,1,1) = CHAR(39)
---- check for text qualifier in second position and remove
update PMWX set DataRow = substring(a.DataRow,1,1) + substring(a.DataRow,3, len(a.DataRow))
from PMWX a where a.PMCo=@pmco and a.ImportId=@importid and substring(a.DataRow,2,1) = CHAR(39)
----#140048

---- if record type column is not (1,2,3,4,5,6,*,P,C) then delete
if @filetype = 'F' 
	begin
	delete from PMWX where PMCo=@pmco and ImportId=@importid
	and substring(DataRow, @begrectypepos, @rectypelen) not in ('1','2','3','4','5','6','*','P','C')
	goto process_import
	end

if @filetype <> 'D' goto process_import



------ check file type for delimited and clean up text records
------ since the record type column can be any column will need
------ to parse until counter = @recordtypecol
declare bcPMWX cursor LOCAL FAST_FORWARD for select Seq, DataRow
from PMWX where PMCo=@pmco and ImportId=@importid

------ open cursor
open bcPMWX
select @opencursor = 1, @validcnt = 0

------ cycle thru cursor
process_loop:
fetch next from bcPMWX into @seq, @datarow

if (@@fetch_status <> 0) goto process_loop_end

select @retstring = @datarow, @complete = 0, @counter = 1
while @complete = 0
BEGIN
	--126939
	--Check for Item record type
	----#138062
	insert into #ColumnValues exec dbo.vspPMImportParse @retstring, @char, @template, 'Item', @errmsg output, 'Y'
	if exists(select top 1 1 from #ColumnValues where Template=@template)
	begin
		select @RecType=ContractItemID from PMUR with (nolock) where Template=@template
		select @ReturnRecType = Value from #ColumnValues where Template=@template and ColumnName='RecordType'
		if @RecType = @ReturnRecType
		begin
			set @complete = 1
				update dbo.bPMWX
				set RecType = @ReturnRecType
				where ImportId=@importid and Seq=@seq
			goto process_loop
		end
	end

	--Clean up temp table
	delete #ColumnValues

	--Check for Phase record type
	----#138062
	insert into #ColumnValues exec dbo.vspPMImportParse @retstring, @char, @template, 'Phase', @errmsg output, 'Y'
	if exists(select top 1 1 from #ColumnValues where Template=@template)
	begin
		select @RecType=PhaseID from PMUR with (nolock) where Template=@template
		select @ReturnRecType = Value from #ColumnValues where Template=@template and ColumnName='RecordType'
		if @RecType = @ReturnRecType
		begin
			set @complete = 1
				update dbo.bPMWX
				set RecType = @ReturnRecType
				where ImportId=@importid and Seq=@seq			
			goto process_loop
		end
	end

	--Clean up temp table
	delete #ColumnValues

	--Check for CostType record type
	----#138062
	insert into #ColumnValues exec dbo.vspPMImportParse @retstring, @char, @template, 'CostType', @errmsg output, 'Y'
	if exists(select top 1 1 from #ColumnValues where Template=@template)
	begin
		select @RecType=CostTypeID from PMUR with (nolock) where Template=@template
		select @ReturnRecType = Value from #ColumnValues where Template=@template and ColumnName='RecordType'
		if @RecType = @ReturnRecType
		begin
			set @complete = 1
				update dbo.bPMWX
				set RecType = @ReturnRecType
				where ImportId=@importid and Seq=@seq			
			goto process_loop
		end
	end

	--Clean up temp table
	delete #ColumnValues

	--Check for SubDetail record type
	----#138062
	insert into #ColumnValues exec dbo.vspPMImportParse @retstring, @char, @template, 'SubDetail', @errmsg output, 'Y'
	if exists(select top 1 1 from #ColumnValues where Template=@template)
	begin
		select @RecType=SubcontractDetailID from PMUR with (nolock) where Template=@template
		select @ReturnRecType = Value from #ColumnValues where Template=@template and ColumnName='RecordType'
		if @RecType = @ReturnRecType
		begin
			set @complete = 1
				update dbo.bPMWX
				set RecType = @ReturnRecType
				where ImportId=@importid and Seq=@seq			
			goto process_loop
		end
	end

	--Clean up temp table
	delete #ColumnValues

	--Check for MatlDetail record type
	----#138062
	insert into #ColumnValues exec dbo.vspPMImportParse @retstring, @char, @template, 'MatlDetail', @errmsg output, 'Y'
	if exists(select top 1 1 from #ColumnValues where Template=@template)
	begin
		select @RecType=MaterialDetailID from PMUR with (nolock) where Template=@template
		select @ReturnRecType = Value from #ColumnValues where Template=@template and ColumnName='RecordType'
		if @RecType = @ReturnRecType
		begin
			set @complete = 1
				update dbo.bPMWX
				set RecType = @ReturnRecType
				where ImportId=@importid and Seq=@seq			
			goto process_loop
		end
	end

	--Clean up temp table
	delete #ColumnValues

	--Check for Estimate record type
	----#138062
	insert into #ColumnValues exec dbo.vspPMImportParse @retstring, @char, @template, 'Estimate', @errmsg output, 'Y'
	if exists(select top 1 1 from #ColumnValues where Template=@template)
	begin
		select @RecType=EstimateInfoID from PMUR with (nolock) where Template=@template
		select @ReturnRecType = Value from #ColumnValues where Template=@template and ColumnName='RecordType'
		if @RecType = @ReturnRecType
		begin
			set @complete = 1
				update dbo.bPMWX
				set RecType = @ReturnRecType
				where ImportId=@importid and Seq=@seq			
			goto process_loop
		end
	end

	--Clean up temp table
	delete #ColumnValues

	--If record type not found
	if @complete = 0
	begin
		delete from PMWX where PMCo=@pmco and ImportId=@importid and Seq=@seq
		goto process_loop
	end

----	if substring(@retstring,1,1) = '"'
----		begin
----		exec dbo.vspPMImportParseString @retstring, @char1, @charpos output, @field output, @retstringlist output, @errmsg output
----		select @retstring = substring(@retstringlist,2,len(@retstringlist))
----		end
----	else
----		begin
----		exec dbo.vspPMImportParseString @retstring, @char, @charpos output, @field output, @retstringlist output, @errmsg output
----		select @retstring=@retstringlist
----		end
----	------ set some values
----	set @endcharpos = @charpos
----	set @field = replace(@field,'"','')
----	set @field = ltrim(rtrim(@field))
----	------ if counter = record type column verify record type value
----	if @counter = @recordtypecol 
----		begin
----		if @field in ('1','2','3','4','5','6','*','P','C')
----			goto process_loop
----		else
----			begin
----			delete from PMWX where PMCo=@pmco and ImportId=@importid and Seq=@seq
----			goto process_loop
----			end
----		end
	------ increment counter and check for end of string
	select @counter = @counter + 1
	if @endcharpos = 0 set @complete = 1
END
goto process_loop

process_loop_end:
	drop table #ColumnValues --126939

	if @opencursor = 1
		begin
		close bcPMWX
		deallocate bcPMWX
  		select @opencursor = 0
  		end







process_import:
select @rcode = 0, @validcnt = 0
select @validcnt = count(*) from PMWX where PMCo=@pmco and ImportId=@importid
select @msg = convert(varchar(10),@validcnt)





bspexit:
	----drop table #xPMData
	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMImportDataBulk] TO [public]
GO
