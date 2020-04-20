alter FUNCTION dbo.mfnGetPrimaryKeyColumnString 
(
	-- Add the parameters for the function here
	@TableName	sysname
,	@CompareTable sysname = 'INSERTED'
)
RETURNS varchar(255)
AS
BEGIN

	declare idxcolcur cursor for

	Select idx.index_id, col.name From 
	sys.objects obj 
	Join sys.columns col on col.[object_id] = obj.[object_id]
	Join sys.index_columns idx_cols on idx_cols.[column_id] = col.[column_id] and idx_cols.[object_id] = col.[object_id]
	Join sys.indexes idx on idx_cols.[index_id] = idx.[index_id] and idx.[object_id] = col.[object_id]
	where obj.name = @TableName
	and idx.is_unique = 1
	order by 1, 2
	for read only

	declare @id int
	declare @name sysname

	declare @curid int

	declare @pk_string varchar(255)
	set @pk_string =''

	open idxcolcur
	fetch idxcolcur into @id, @name

	select @curid=@id
	while @@fetch_status=0
	begin
		if @id = @curid
		begin
			select @pk_string=@pk_string + @TableName + '.' + @name + '=' + @CompareTable + '.' + @name + ' AND ' 
		end

		fetch idxcolcur into @id, @name
	end

	close idxcolcur
	deallocate idxcolcur

	select @pk_string=left(@pk_string, len(@pk_string)-4)


	RETURN ltrim(rtrim(@pk_string))

END
GO
--select dbo.mfnGetPrimaryKeyColumnString('bJCJM','INSERTED')

alter function dbo.mfnGetNextFormControlPosition
(
	@FormName sysname
,	@ViewName sysname
)
RETURNS varchar(255) as
begin

	declare @X int
	declare @Y int
	declare @Width int
	declare @LabelWidth int
	declare @newControlPos varchar(20);

	with fpos as (
	SELECT ColumnName,ControlPosition,
		cast(PARSENAME(REPLACE(ControlPosition,',','.'),1) as int) 'LabelWidth' ,
		cast(PARSENAME(REPLACE(ControlPosition,',','.'),2) as int) 'Width',
		cast(PARSENAME(REPLACE(ControlPosition,',','.'),3) as int) 'X',
		cast(PARSENAME(REPLACE(ControlPosition,',','.'),4) as int) 'Y'
	FROM DDFIShared where Form=@FormName and ViewName=@ViewName and ControlPosition is not null 
	)
	select top 1 @X=coalesce(X,20), @Y=coalesce(Y+30,400) ,@Width=coalesce(Width,400) , @LabelWidth=coalesce(LabelWidth,20)  from fpos order by X DESC ,Y DESC

	select @newControlPos=  cast(@Y  as varchar(10)) + ',' + cast(@X  as varchar(10)) + ',' + cast(@Width  as varchar(10)) + ',' + cast(@LabelWidth  as varchar(10))

	return @newControlPos
end
go
--select dbo.mfnGetNextFormControlPosition('JCMP','JCMP')

if not exists (select 1 from vDDDT where Datatype='mckDateTime')
begin

/****** Object:  UserDefinedDataType [dbo].[bDate]    Script Date: 4/1/2016 1:28:41 PM ******/
CREATE TYPE [dbo].[mckDateTime] FROM [datetime] NOT NULL

insert vDDDT (Datatype,Description,InputType,InputMask,InputLength,Prec,MasterTable,MasterColumn,MasterDescColumn,QualifierColumn,Lookup,SetupForm,ReportLookup,SQLDatatype,ReportOnly,TextID)
select
	'mckDateTime','Full Date Time',2,'MM/dd/yyyy hh:mm:ss',20,Prec,MasterTable,MasterColumn,MasterDescColumn,QualifierColumn,Lookup,SetupForm,ReportLookup,SQLDatatype,ReportOnly,TextID
from 
	DDDT
where Datatype='bLongDate'
end
go

declare @pk varchar(255)

declare @schema sysname
declare @tableName sysname
declare @viewName sysname
declare @formName sysname
select @schema = 'dbo'
select @tableName='bJCMP'

--Get View and Form Name for Base table
select @viewName=right(@tableName,len(@tableName)-1)
select @formName=Form from DDFH where ViewName=@viewName

declare @newControlPos varchar(20)

declare @sqlToRun	varchar(max)

/* FOR Viewpoint STANDARD TABLES */

if not exists ( select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=@schema and TABLE_NAME=@tableName and COLUMN_NAME='udCreatedDate')
begin
	print '--udCreatedDate does not exist in ' + @schema + '.' + @tableName

	-- Add Column to Vista Table definition
	select @sqlToRun = 'declare @msg varchar(255); ' 
	select @sqlToRun = @sqlToRun + 'set @msg=NULL; ' 
	select @sqlToRun = @sqlToRun + 'exec vspHQUDAdd @formname=''' + @formName + ''',@tabnbr=1,@tablename='''+ @tableName + ''',@viewname='''+ @viewName + ''',@columnname=''udCreatedDate'',@usedatatype=''Y'',@inputtype=2,@inputlen=20,@sysdatatype=''mckDateTime'',@inputmask=NULL,@prec=NULL,@labeltext=''Date Created'',@columnhdrtext=''Date Created'',@statustext=''Date Created'',@required=''N'',@desc=''Date Created'',@controltype=6,@combotype=NULL,@vallevel=NULL,@valproc=NULL,@valparams=NULL,@valmin=NULL,@valmax=NULL,@valexpr=NULL,@valexprerror=NULL,@defaulttype=0,@defaultvalue=NULL,@activelookup=''N'',@msg=@msg output; ' 
	select @sqlToRun = @sqlToRun + 'select @msg ;' 
	print replicate(' ',10) + @sqlToRun;
	print replicate(' ',10) +'go'

	-- Recompile Vista View (called in above vspHQUDAdd
	
	select @sqlToRun = 'update vDDFIc set ControlPosition=dbo.mfnGetNextFormControlPosition(''' + @formName + ''',''' + @viewName + '''),ShowForm=''N'',ShowGrid=''N'',DisableInput=''Y'' where Form=''' + @formName +''' and ViewName=''' + @viewName + ''' and ColumnName=''udCreatedDate'';'  
	print replicate(' ',10) + @sqlToRun;
	print replicate(' ',10) +'go'
end
else
begin
	print '--udCreatedDate already exists in ' + @schema + '.' + @tableName
	select @sqlToRun = 'DECLARE	@return_value int, @msg varchar(512); ' 
	select @sqlToRun = @sqlToRun + 'EXEC	@return_value = [dbo].[vspHQUDDelete] @formname = N''' + @formName + ''',@tablename = N''' + @tableName + ''',@viewname = N''' + @viewName + ''',@columnname = N''udCreatedDate'',@msg = @msg OUTPUT ;' 
	select @sqlToRun = @sqlToRun + 'SELECT	@msg as N''@msg'' ;' 
	print replicate(' ',10) + @sqlToRun;
	print replicate(' ',10) +'go'
end
print ''

if not exists ( select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=@schema and TABLE_NAME=@tableName and COLUMN_NAME='udCreatedBy')
begin
	print '--udCreatedBy does not exist in ' + @schema + '.' + @tableName

	-- Add Column to Vista Table definition
	select @sqlToRun = 'declare @msg varchar(255) ' 
	select @sqlToRun = @sqlToRun + 'set @msg=NULL ' 
	select @sqlToRun = @sqlToRun + 'exec vspHQUDAdd @formname=''' + @formName + ''',@tabnbr=1,@tablename='''+ @tableName + ''',@viewname='''+ @viewName + ''',@columnname=''udCreatedBy'',@usedatatype=''N'',@inputtype=0,@inputlen=50,@sysdatatype=null,@inputmask=NULL,@prec=NULL,@labeltext=''Created By'',@columnhdrtext=''Created By'',@statustext=''Created By'',@required=''N'',@desc=''Created By'',@controltype=6,@combotype=NULL,@vallevel=NULL,@valproc=NULL,@valparams=NULL,@valmin=NULL,@valmax=NULL,@valexpr=NULL,@valexprerror=NULL,@defaulttype=0,@defaultvalue=NULL,@activelookup=''N'',@msg=@msg output; ' 
	select @sqlToRun = @sqlToRun + 'select @msg ;' 
	print replicate(' ',10) + @sqlToRun;
	print replicate(' ',10) +'go'

	-- Recompile Vista View (called in above vspHQUDAdd
	

	select @sqlToRun = 'update vDDFIc set ControlPosition=dbo.mfnGetNextFormControlPosition(''' + @formName + ''',''' + @viewName + '''),ShowForm=''N'',ShowGrid=''N'',DisableInput=''Y'' where Form=''' + @formName +''' and ViewName=''' + @viewName + ''' and ColumnName=''udCreatedBy'';'  
	print replicate(' ',10) + @sqlToRun;
	print replicate(' ',10) +'go'
	
end
else
begin
	print '--udCreatedBy already exists in ' + @schema + '.' + @tableName
	select @sqlToRun = 'DECLARE	@return_value int, @msg varchar(512) ' 
	select @sqlToRun = @sqlToRun + 'EXEC	@return_value = [dbo].[vspHQUDDelete] @formname = N''' + @formName + ''',@tablename = N''' + @tableName + ''',@viewname = N''' + @viewName + ''',@columnname = N''udCreatedBy'',@msg = @msg OUTPUT ;' 
	select @sqlToRun = @sqlToRun + 'SELECT	@msg as N''@msg'' ;' 
	print replicate(' ',10) + @sqlToRun;
	print replicate(' ',10) +'go'
end
print ''

if not exists ( select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=@schema and TABLE_NAME=@tableName and COLUMN_NAME='udModifiedDate')
begin
	print '--udModifiedDate does not exist in ' + @schema + '.' + @tableName

	-- Add Column to Vista Table definition
	select @sqlToRun = 'declare @msg varchar(255) ' 
	select @sqlToRun = @sqlToRun + 'set @msg=NULL ' 
	select @sqlToRun = @sqlToRun + 'exec vspHQUDAdd @formname=''' + @formName + ''',@tabnbr=1,@tablename='''+ @tableName + ''',@viewname='''+ @viewName + ''',@columnname=''udModifiedDate'',@usedatatype=''Y'',@inputtype=2,@inputlen=20,@sysdatatype=''mckDateTime'',@inputmask=NULL,@prec=NULL,@labeltext=''Modified Date'',@columnhdrtext=''Modified Date'',@statustext=''Modified Date'',@required=''N'',@desc=''Modified Date'',@controltype=6,@combotype=NULL,@vallevel=NULL,@valproc=NULL,@valparams=NULL,@valmin=NULL,@valmax=NULL,@valexpr=NULL,@valexprerror=NULL,@defaulttype=0,@defaultvalue=NULL,@activelookup=''N'',@msg=@msg output; ' 
	select @sqlToRun = @sqlToRun + 'select @msg ;' 
	print replicate(' ',10) + @sqlToRun;
	print replicate(' ',10) + 'go'

	-- Recompile Vista View (called in above vspHQUDAdd

	select @sqlToRun = 'update vDDFIc set ControlPosition=dbo.mfnGetNextFormControlPosition(''' + @formName + ''',''' + @viewName + '''),ShowForm=''N'',ShowGrid=''N'',DisableInput=''Y'' where Form=''' + @formName +''' and ViewName=''' + @viewName + ''' and ColumnName=''udModifiedDate'';'  
	print replicate(' ',10) + @sqlToRun;
	print replicate(' ',10) +'go'
	
end
else
begin
	print '--udModifiedDate already exists in ' + @schema + '.' + @tableName

	select @sqlToRun = 'DECLARE	@return_value int, @msg varchar(512) ' 
	select @sqlToRun = @sqlToRun + 'EXEC	@return_value = [dbo].[vspHQUDDelete] @formname = N''' + @formName + ''',@tablename = N''' + @tableName + ''',@viewname = N''' + @viewName + ''',@columnname = N''udModifiedDate'',@msg = @msg OUTPUT ;' 
	select @sqlToRun = @sqlToRun + 'SELECT	@msg as N''@msg'' ;' 
	print replicate(' ',10) + @sqlToRun;
	print replicate(' ',10) +'go'

end
print ''

if not exists ( select * from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=@schema and TABLE_NAME=@tableName and COLUMN_NAME='udModifiedBy')
begin
	print '--udModifiedBy does not exist in ' + @schema + '.' + @tableName

	-- Add Column to Vista Table definition
	select @sqlToRun = 'declare @msg varchar(255) ' 
	select @sqlToRun = @sqlToRun + 'set @msg=NULL ' 
	select @sqlToRun = @sqlToRun + 'exec vspHQUDAdd @formname=''' + @formName + ''',@tabnbr=1,@tablename='''+ @tableName + ''',@viewname='''+ @viewName + ''',@columnname=''udModifiedBy'',@usedatatype=''N'',@inputtype=0,@inputlen=50,@sysdatatype=null,@inputmask=NULL,@prec=NULL,@labeltext=''Modified By'',@columnhdrtext=''Modified By'',@statustext=''Modified By'',@required=''N'',@desc=''Modified By'',@controltype=6,@combotype=NULL,@vallevel=NULL,@valproc=NULL,@valparams=NULL,@valmin=NULL,@valmax=NULL,@valexpr=NULL,@valexprerror=NULL,@defaulttype=0,@defaultvalue=NULL,@activelookup=''N'',@msg=@msg output; ' 
	select @sqlToRun = @sqlToRun + 'select @msg ;' 
	print replicate(' ',10) + @sqlToRun;
	print replicate(' ',10) + 'go'

	-- Recompile Vista View (called in above vspHQUDAdd
	

	select @sqlToRun = 'update vDDFIc set ControlPosition=dbo.mfnGetNextFormControlPosition(''' + @formName + ''',''' + @viewName + '''),ShowForm=''N'',ShowGrid=''N'',DisableInput=''Y'' where Form=''' + @formName +''' and ViewName=''' + @viewName + ''' and ColumnName=''udModifiedBy'';'  
	print replicate(' ',10) + @sqlToRun;
	print replicate(' ',10) + 'go'

end
else
begin
	print '--udModifiedBy already exists in ' + @schema + '.' + @tableName

	select @sqlToRun = 'DECLARE	@return_value int, @msg varchar(512) ' 
	select @sqlToRun = @sqlToRun + 'EXEC	@return_value = [dbo].[vspHQUDDelete] @formname = N''' + @formName + ''',@tablename = N''' + @tableName + ''',@viewname = N''' + @viewName + ''',@columnname = N''udModifiedBy'',@msg = @msg OUTPUT ;' 
	select @sqlToRun = @sqlToRun + 'SELECT	@msg as N''@msg'' ;' 
	print replicate(' ',10) + @sqlToRun;
	print replicate(' ',10) + 'go'
end
print ''


/* FOR UD TABLES  */
--UDTH : UD Table Header
--UDTC: UD Table Columns

--dbo.vspDDFormInfo
--dbo.vspUDUpdateAuditTriggers
--dbo.vspUDRegetDB
--dbo.vspUDTableInsert
--dbo.vspUDTableUpdate
--dbo.vspUDUserLookupsDetailInfo
--dbo.vspUDTCIncrementFieldCheck



--Populate fields with default values before adding triggers.

if not exists ( select 1 from sysobjects where type = 'TR' and name = 'mtrI' + @tableName + 'CreatedModified')
begin
	print '--mtriI' + @tableName + 'CreatedModified does not exist for ' + @schema + '.' + @tableName

	select @pk = dbo.mfnGetPrimaryKeyColumnString(@tableName, 'inserted')

	-- Create Insert Trigger 
	select @sqlToRun = 'create trigger mtrI' + @tableName + 'CreatedModified on ' + @schema + '.' + @tableName + ' for INSERT as '
	select @sqlToRun = @sqlToRun + 'BEGIN '
	select @sqlToRun = @sqlToRun + 'UPDATE ' + @schema + '.' + @tableName + ' '
	select @sqlToRun = @sqlToRun + 'set udCreatedDate=getdate(), udCreatedBy=suser_sname(), udModifiedDate=getdate(), udModifiedBy=suser_sname() ' 
	select @sqlToRun = @sqlToRun + 'FROM inserted '
	select @sqlToRun = @sqlToRun + 'where ' + @pk + + ' '
	select @sqlToRun = @sqlToRun + 'END ;'

	print replicate(' ',10) + @sqlToRun
	print replicate(' ',10) + 'go'

end
else
begin
	print '--mtriI' + @tableName + 'CreatedModified already exists for ' + @schema + '.' + @tableName
	select @sqlToRun = 'drop trigger mtrI' + @tableName + 'CreatedModified'
	print replicate(' ',10) + @sqlToRun
	print replicate(' ',10) + 'go'
end
print ''

if not exists ( select 1 from sysobjects where type = 'TR' and name = 'mtrU' + @tableName + 'CreatedModified')
begin
	print '--mtriU' + @tableName + 'CreatedModified does not exist for ' + @schema + '.' + @tableName 

	select @pk = dbo.mfnGetPrimaryKeyColumnString(@tableName, 'inserted')

	-- Create Update Trigger 
	select @sqlToRun = 'create trigger mtrU' + @tableName + 'CreatedModified on ' + @schema + '.' + @tableName + ' for UPDATE as '
	select @sqlToRun = @sqlToRun + 'BEGIN '
	select @sqlToRun = @sqlToRun + 'UPDATE ' + @schema + '.' + @tableName + ' '
	select @sqlToRun = @sqlToRun + 'set udModifiedDate=getdate(), udModifiedBy=suser_sname() ' 
	select @sqlToRun = @sqlToRun + 'FROM inserted '
	select @sqlToRun = @sqlToRun + 'where ' + @pk + + ' '
	select @sqlToRun = @sqlToRun + 'END ;'

	print replicate(' ',10) + @sqlToRun
	print replicate(' ',10) + 'go'

end
else
begin
	print '--mtriU' + @tableName + 'CreatedModified already exists for ' + @schema + '.' + @tableName
	select @sqlToRun = 'drop trigger mtrU' + @tableName + 'CreatedModified'
	print replicate(' ',10) + @sqlToRun
	print replicate(' ',10) + 'go'

end
print ''

