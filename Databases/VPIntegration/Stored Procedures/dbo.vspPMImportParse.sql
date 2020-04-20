SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Stored Procedure dbo.vspPMImmportParse   Script Date: 02/16/2009 ******/
CREATE procedure [dbo].[vspPMImportParse]
/************************************************************************
 * Created By:	GP 02/16/2009
 * Modified By:	GP 11/10/2009 - Issue 136451 validate data against it's datatype before adding
 *				GF 02/10/2010 - issue #138042 - changes to store the import value not formatted to our data type.
 *				GF 02/16/2010 - issue #138062 - change for bulk parse to not validate data type
 *				GF 05/06/2010 - issue #140048 - need to check for single quote text delimter
 *				GF 02/10/2011 - issue #143294 changed int to big int
 *				GF 01/06/2011 - TK-11537 expand ColumnName to 128 characters.
 *
 *
 *
 * PURPOSE:
 *	Parse a delimited string based on delimiter value, template, and record type.
 *	Creates a table variable that stores Column Name and Value from our import
 *	file data.
 *    
 *
 * RETURNS:
 *	0 - Success 
 *	1 - Failure
 *
 *************************************************************************/
 ----#138062
(@InputString varchar(max) = null, @Delimiter varchar(2) = null, @Template varchar(20) = null, 
 @RecordType varchar(10) = null, @msg varchar(255) = null output, @bulk_parse char(1) = 'N')
as
set nocount on

--Create temp table #138042
declare @ValuesTableVar table ( 
	Seq int identity(1,1), 
	Template varchar(20) not null,
	----TK-11537
	ColumnName varchar(128) not null,
	Value varchar(max) null, ---- changed
	ImportValue varchar(max) null )

---- #138042
declare @StringLen BIGINT, @Pattern varchar(max), @ImportPattern varchar(max), @i BIGINT, @Char char(2), 
	@DelimiterCount BIGINT, @DelimiterPos BIGINT, @QuoteFound char(1), @QuoteLoc BIGINT,
	@rcode int, @MaxSeq int,
	-- 136451 used for datatype validation
	@Column nvarchar(128), @CurrRecTypeID varchar(10), @RecTypeID varchar(10)

select @rcode = 0, @i = 1, @DelimiterPos = 0, @DelimiterCount = 0, @QuoteFound = 'N'

-- VALIDATION --
if @InputString is null
begin
	select @msg = 'Missing string list.  Nothing to parse.', @rcode = 1
	goto vspexit
end

if @Delimiter is null
begin
	select @msg = 'Missing delimiter.', @rcode = 1
	goto vspexit
end

--INSERT TEMPLATE & COLUMN NAMES
insert into @ValuesTableVar (Template, ColumnName)
select @Template, ColumnName from PMUD with (nolock) where Template=@Template and RecordType=@RecordType and 
	RecColumn is not null order by RecColumn

set @StringLen = Len(@InputString)
select @MaxSeq = max(Seq) from @ValuesTableVar

--WHILE LOOP
--Get DelimiterCount
while @i <= @StringLen
begin
	set @Char = substring(@InputString, @i, 1)

	if @Char = @Delimiter
	begin
		set @DelimiterCount = @DelimiterCount + 1
	end

	set @i = @i + 1
end

select @i = 1

--WHILE LOOP
--Get Values
while @i <= @DelimiterCount
begin
	set @DelimiterPos = charindex(@Delimiter, @InputString)
	
	if @DelimiterPos = 0 break --Break if no more delimiter

	if substring(@InputString, 1, 1) = '"' and (charindex('"'+@Delimiter,@InputString) = 0) break
	----#140048
	if substring(@InputString, 1, 1) = CHAR(39) and (charindex(CHAR(39) + @Delimiter,@InputString) = 0) break
	----#140048
	
	---- check for double quote and remove pattern
	if substring(@InputString, 1, 1) = '"'
		begin
		set @QuoteLoc = charindex('"' + @Delimiter, @InputString) --Find location of Quote & Delimiter combo
		set @Pattern = substring(@InputString, 1, @QuoteLoc - 1) --Set Pattern	
		set @Pattern = stuff(@Pattern, 1, 1, '') --Remove leading quotation mark
		set @InputString = stuff(@InputString, 1, @QuoteLoc + 1, '') --Remove Pattern from InputString
		set @QuoteFound = 'Y' --Set flag so Pattern isn't updated immediately following this statement
		end
		
	----#140048 - check for single quote and remove pattern
	if substring(@InputString, 1, 1) = CHAR(39)
		begin
		set @QuoteLoc = charindex(CHAR(39) + @Delimiter, @InputString) --Find location of Quote & Delimiter combo
		set @Pattern = substring(@InputString, 1, @QuoteLoc - 1) --Set Pattern	
		set @Pattern = stuff(@Pattern, 1, 1, '') --Remove leading quotation mark
		set @InputString = stuff(@InputString, 1, @QuoteLoc + 1, '') --Remove Pattern from InputString
		set @QuoteFound = 'Y' --Set flag so Pattern isn't updated immediately following this statement
		end
	----#140048

	if @DelimiterPos = 0 break --Break if no more delimiter

	if @QuoteFound = 'N'
	begin
		set @Pattern=substring(@InputString, 1, @DelimiterPos - 1)	
	end
	
	--------- 136451
	set @ImportPattern = null
	select @Column = ColumnName from @ValuesTableVar where Seq = @i		
	---- #138042 and #138062
	if isnull(@bulk_parse,'N') <> 'Y'
		begin
		exec dbo.vspPMImportDataTypeVal @Template, @RecordType, @Column, @Pattern, @Pattern output, @ImportPattern output
		end
	if isnull(@Pattern,'') = '' set @DelimiterCount = @DelimiterCount + 1
	---------

	update @ValuesTableVar
	set Value = @Pattern, ImportValue = @ImportPattern 	---- #138042
	where Seq = @i
	
	if @QuoteFound='N'
	begin
		set @InputString = stuff(@InputString, 1, @DelimiterPos, '')
	end

	select @i = @i + 1, @QuoteFound = 'N'
end --END WHILE


--Check if Last Value has double quotes
if substring(@InputString, 1, 1) = '"'
	begin
	set @InputString = stuff(@InputString, 1, 1, '') --Remove leading quotation mark
	set @QuoteLoc = len(@InputString) --Find last quotation mark
	set @Pattern = substring(@InputString, 1, @QuoteLoc) --Set Pattern
	set @Pattern = stuff(@Pattern, @QuoteLoc, 1, '') --Remove trailing quotation mark
	set @QuoteFound = 'Y'
	end

----#140048 - Check if Last Value has single quotes
if substring(@InputString, 1, 1) = CHAR(39)
	begin
	set @InputString = stuff(@InputString, 1, 1, '') --Remove leading quotation mark
	set @QuoteLoc = len(@InputString) --Find last quotation mark
	set @Pattern = substring(@InputString, 1, @QuoteLoc) --Set Pattern
	set @Pattern = stuff(@Pattern, @QuoteLoc, 1, '') --Remove trailing quotation mark
	set @QuoteFound = 'Y'
	end
----#140048

if @QuoteFound='N'
begin
	set @Pattern = substring(@InputString, 1, len(@InputString))
end

--------- #136451 - #138042
set @ImportPattern = null
select @Column = ColumnName from @ValuesTableVar where Seq = @i
---- #138062
if isnull(@bulk_parse,'N') <> 'Y'
	begin
	exec dbo.vspPMImportDataTypeVal @Template, @RecordType, @Column, @Pattern, @Pattern output, @ImportPattern output
	end
if isnull(@Pattern,'') = '' set @DelimiterCount = @DelimiterCount + 1
---------

--Insert Last Value into Table Variable
update @ValuesTableVar
set Value = @Pattern, ImportValue = @ImportPattern ---- #138042
where Seq = @i

--View Table Variable
select * from @ValuesTableVar


vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMImportParse] TO [public]
GO
