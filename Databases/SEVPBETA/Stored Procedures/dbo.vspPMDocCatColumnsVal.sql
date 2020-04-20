SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  PROCEDURE [dbo].[vspPMDocCatColumnsVal]
/***********************************************************
* CREATED By:	GF 07/02/2009 - issue #24641
* MODIFIED By:
*
*
* USAGE:
*   validates Override columns from PM Document Category Overrides
*
* PASS:
* Columns	Separated Value varchar of File.Column to validate existence
*
* RETURNS:
* ErrMsg if any
* 
* OUTPUT PARAMETERS
*   @msg     Error message if invalid, 
* RETURN VALUE
*   0 Success
*   1 fail
*****************************************************/ 
(@columns nvarchar(max) = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @validcnt int, @separator char(1), @separator_position int,
		@array_value varchar(255), @file_position int, @file_value varchar(30),
		@column_value varchar(100)

set @rcode = 0
set @validcnt = 0
set @separator = ';'

if isnull(@columns,'') = '' goto bspexit

---- parse out the columns and check if in INFORMATION_SCHEMA.COLUMNS
---- Loop through the string searching for separtor characters
WHILE PATINDEX('%' + @separator + '%', @columns) <> 0 
    BEGIN
		select @separator_position = 0, @array_value = null, @file_position = 0, @file_value = null, @column_value = null
        -- patindex matches the a pattern against a string
        SELECT @separator_position = PATINDEX('%' + @separator + '%',@columns)
        SELECT @array_value = LEFT(@columns, @separator_position - 1)

        ---- This is where you process the values passed.
		---- now split the @array_value into file and column values
		select @file_position = PATINDEX('%.%', @array_value)
		if @file_position > 3
			begin
			select @file_value = LEFT(@array_value, @file_position - 1)
			select @column_value = substring(@array_value, @file_position + 1, datalength(@array_value))
			
			---- validate to SCHEMA
			if not exists(select top 1 1 from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = @file_value
					and COLUMN_NAME = @column_value)
				begin
				select @msg = 'FileColumn: ' + isnull(@array_value,'') + ' does does not exist in the database.', @rcode = 1
				goto bspexit
				end
			end
			
        ---- This replaces what we just processed with and empty string
        SELECT  @columns = STUFF(@columns, 1, @separator_position, '')
    END




bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMDocCatColumnsVal] TO [public]
GO
