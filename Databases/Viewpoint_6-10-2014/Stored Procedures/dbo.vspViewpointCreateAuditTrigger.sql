SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[vspViewpointCreateAuditTrigger]
(
	@TableName as varchar(100)
)
AS

DECLARE @SQLString as nvarchar(4000),
		@ExecuteString as nvarchar(4000),
		@Field int ,
		@MaxField int ,
		@FieldName varchar(128) ,
		@DataType varchar(1000),
		@Columns varchar(1000),
		@InvalidDataType bit


--Drop the Audit Trigger if it already exists
set @SQLString = 'if exists (select * from dbo.sysobjects where id = object_id(N''[dbo].[' + @TableName + 'Audit]'') and OBJECTPROPERTY(id, N''IsTrigger'') = 1)
			drop trigger [dbo].[' + @TableName + 'Audit]'
EXECUTE sp_executesql @SQLString



SET @InvalidDataType = 0

-- get list of columns
select @Field = 0, @MaxField = max(ORDINAL_POSITION) from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = @TableName
while @Field < @MaxField
	begin
		select @Field = min(ORDINAL_POSITION) from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = @TableName and ORDINAL_POSITION > @Field
		select @DataType = DATA_TYPE from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = @TableName and ORDINAL_POSITION = @Field
		IF @DataType <> 'text' AND @DataType <> 'ntext' AND @DataType <> 'image'
			BEGIN 
				select @FieldName = COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = @TableName and ORDINAL_POSITION = @Field
				select @Columns = ISNULL(@Columns,'') + '[' + @FieldName + ']' + ', '
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

SET @SQLString = 'create trigger ' + @TableName + 'Audit on ' + @TableName + ' for insert, update, delete
as

declare @bit int ,
	@field int ,
	@maxfield int ,
	@char int ,
	@fieldname varchar(128) ,
	@TableName varchar(128) ,
	@PKCols varchar(1000) ,
	@sql nvarchar(2000), 
	@UpdateDate varchar(21) ,
	@UserName varchar(128) ,
	@Type char(1) ,
	@PKSelect varchar(1000),
	@DataType varchar(1000)
	
	select @TableName = ''' + @TableName + '''

	-- date and user
	select 	@UserName = system_user ,
		@UpdateDate = convert(varchar(8), getdate(), 112) + '' '' + convert(varchar(12), getdate(), 114)

	-- Action
	if exists (select * from inserted)
		if exists (select * from deleted)
			select @Type = ''U''
		else
			select @Type = ''I''
	else
		select @Type = ''D''
	

	-- get list of columns
	select ' + @Columns + ' into #ins from inserted
	select ' + @Columns + ' into #del from deleted

	-- Get primary key columns for full outer join
    SELECT @PKCols = '' on i.KeyID = d.KeyID''		

	-- Get primary key select for insert
	select @PKSelect = coalesce(@PKSelect+''+'','''') + ''''''<'' + ''KeyID'' + ''=''''+convert(varchar(100),coalesce(i.'' + ''KeyID'' +'',d.'' + ''KeyID'' + ''))+''''>'''''' 
		
	if @PKCols is null
	begin
		raiserror(''no PK on table %s'', 16, -1, @TableName)
		return
	end
	
	select @field = 0, @maxfield = max(ORDINAL_POSITION) from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = @TableName
	while @field < @maxfield
	begin
		select @field = min(ORDINAL_POSITION) from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = @TableName and ORDINAL_POSITION > @field
		select @DataType = DATA_TYPE from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = @TableName and ORDINAL_POSITION = @field
		IF @DataType <> ''text'' AND @DataType <> ''ntext'' AND @DataType <> ''image''
			BEGIN
			select @bit = (@field - 1 )% 8 + 1
			select @bit = power(2,@bit - 1)
			select @char = ((@field - 1) / 8) + 1
			if substring(COLUMNS_UPDATED(),@char, 1) & @bit > 0 or @Type in (''I'',''D'')
			begin
				select @fieldname = COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = @TableName and ORDINAL_POSITION = @field
				select @sql = 		''insert vViewpointAudit (Type, TableName, PrimaryKey, FieldName, OldValue, NewValue, UpdateDate, UserName)''
				select @sql = @sql + 	'' select '''''' + @Type + ''''''''
				select @sql = @sql + 	'','''''' + @TableName + ''''''''
				select @sql = @sql + 	'','' + @PKSelect
				select @sql = @sql + 	'','''''' + @fieldname + ''''''''
				select @sql = @sql + 	'',convert(varchar(1000),d.'' + @fieldname + '')''
				select @sql = @sql + 	'',convert(varchar(1000),i.'' + @fieldname + '')''
				select @sql = @sql + 	'','''''' + @UpdateDate + ''''''''
				select @sql = @sql + 	'','''''' + @UserName + ''''''''
				select @sql = @sql + 	'' from #ins i full outer join #del d ''
				select @sql = @sql + 	@PKCols
				select @sql = @sql + 	'' where i.'' + @fieldname + '' <> d.'' + @fieldname 
				select @sql = @sql + 	'' or (i.'' + @fieldname + '' is null and  d.'' + @fieldname + '' is not null)'' 
				select @sql = @sql + 	'' or (i.'' + @fieldname + '' is not null and  d.'' + @fieldname + '' is null)'' 
				EXECUTE sp_executesql @sql
			end
		end
	end
'


Select @ExecuteString = CAST(@SQLString AS NVarchar(4000))

--Create the Audit trigger for the table
exec sp_executesql @ExecuteString









GO
GRANT EXECUTE ON  [dbo].[vspViewpointCreateAuditTrigger] TO [public]
GO
