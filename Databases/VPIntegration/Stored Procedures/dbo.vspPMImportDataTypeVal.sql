SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspPMImportDataTypeVal]
/***********************************************************
* CREATED BY:	GP 11/12/2009 - Issue 136451
* MODIFIED BY:	GF 02/10/2010 - issue #138042 - changes to store the import value not formatted to our data type.
*				GP 04/04/2011 - changed @MaxLen from smallint to bigint to handle length of varchar(max) fields.
*
* USAGE:
* 	Returns Pattern (value) for imports after
*	making sure it can be cast as it's specified
*	data type. If not, it is set to "0" or "null"
*	depending on data type.
*
* INPUT PARAMETERS:
*   DataType - data type of field to import
*   PatternIn - value imported by user
*
* OUTPUT PARAMETERS:
*	PatternOut - value to import
*
*****************************************************/
---- #138042
(@Template varchar(20) = null, @RecordType varchar(10) = null, @Column varchar(128) = null, 
	@PatternIn varchar(max) = null, @PatternOut varchar(max) = null output,
	@ImportPatternOut varchar(max) output)
as

declare @rcode int, @Table varchar(20), @UserDataType varchar(20), @DataType varchar(128), @MaxLen bigint
select @rcode = 0, @DataType = null

---- #138042
---- set the ImportPatterOut to hold values for columns we may be cross-referencing
---- the maximum column width for ImportItem, Phase, CostType, UM, Vendor is 30 characters
set @ImportPatternOut = substring(rtrim(@PatternIn),1,30)

------------------
-- GET DATATYPE --
------------------
select @Table = Form, @UserDataType = Datatype from dbo.PMUD with (nolock) where Template=@Template and RecordType=@RecordType and ColumnName=@Column

select @DataType = DATA_TYPE, @MaxLen = CHARACTER_MAXIMUM_LENGTH from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = @Table and COLUMN_NAME = @Column
if @DataType is null
begin
	select @DataType = DATA_TYPE, @MaxLen = CHARACTER_MAXIMUM_LENGTH from INFORMATION_SCHEMA.DOMAINS where DOMAIN_NAME = @UserDataType
end

--------------
-- Truncate --
--------------
if @MaxLen is not null and @MaxLen <> -1 select @PatternIn = substring(@PatternIn, 1, @MaxLen)

-----------------------
-- Numeric DataTypes --
-----------------------
if @DataType in ('tinyint','int','smallint','bigint','numeric','decimal','float','money','bit','smallmoney','real') and @Column<>'CostType'
begin

	--check if value is numeric and not denoted as decimal w/ 'D'
	if isnumeric(@PatternIn) = 1 and charindex('D', @PatternIn) = 0
	begin
	
		--int values
		if @DataType in ('int','tinyint','smallint','bigint')
		begin
			select @PatternIn = convert(numeric, round(@PatternIn, 0))
			select @PatternOut = case 
				when @DataType = 'tinyint' and @PatternIn between 0 and 255 then @PatternIn
				when @DataType = 'smallint' and @PatternIn between -32768 and 32767 then @PatternIn
				when @DataType = 'int' and @PatternIn between -2147483648 and 2147483647 then @PatternIn
				else 0 end
		end
		--bit
		else if @DataType = 'bit'
		begin
			if len(@PatternIn) > 1 set @PatternOut = 0 else set @PatternOut = @PatternIn
		end
	end
	else 
	begin
		set @PatternOut = ''	
	end
	
end	
else
begin

	if @UserDataType = 'bYN' and @PatternIn not in ('Y','N') 
	begin
		set @PatternOut = ''
	end
	else
	begin
		select @PatternOut = @PatternIn
	end	
	
end


vspexit:
 	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPMImportDataTypeVal] TO [public]
GO
