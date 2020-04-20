SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************************
* CREATED BY:  Charles Courchaine 1/29/2008
* MODIFIED By : 
*
* USAGE:
* 	Gets a comma delmited column list for a table
*
* INPUT PARAMETERS
*   @TableName		Name of the table to retrieve columns for
*	@MaxCol			Name of the column to start getting additional columns from.
*
* OUTPUT PARAMETERS
*   @Columns      comma delimited list of columns
*
*
*****************************************************/
CREATE PROCEDURE [dbo].[vspWFGetColumns] 
	-- Add the parameters for the stored procedure here
	@TableName as varchar(200) = null,
	@MaxCol as varchar(50) = null,
	@Columns varchar(max) OUTPUT
	AS
BEGIN
declare @Field int ,
		@MaxField int ,
		@FieldName varchar(128) ,
		@DataType varchar(1000),
		@InvalidDataType bit

select @Field = (select min(ORDINAL_POSITION) from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = @TableName and COLUMN_NAME = @MaxCol), @MaxField = max(ORDINAL_POSITION) from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = @TableName
while @Field < @MaxField
	begin
		select @Field = min(ORDINAL_POSITION) from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = @TableName and ORDINAL_POSITION > @Field
		select @DataType = DATA_TYPE from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = @TableName and ORDINAL_POSITION = @Field
		IF @DataType <> 'text' AND @DataType <> 'ntext' AND @DataType <> 'image'
			BEGIN 
				select @FieldName = COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = @TableName and ORDINAL_POSITION = @Field
				select @Columns = ISNULL(@Columns,',') + ' [' + @FieldName + ']' + ', '
			END
		ELSE
			BEGIN
			SET @InvalidDataType = 1
			END
	end	
IF @InvalidDataType = 0 
	BEGIN
	SET @Columns = '*'
	END
ELSE
	BEGIN
	SET @Columns = LTRIM(RTRIM(@Columns))
	select @Columns = LEFT(@Columns, LEN(@Columns) - 1)
	END
END

GO
GRANT EXECUTE ON  [dbo].[vspWFGetColumns] TO [public]
GO
