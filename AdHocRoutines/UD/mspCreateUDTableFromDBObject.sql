use Viewpoint
go

/*
select * from bUDTH where TableName=@udTable	-- UD Table Header
select * from bUDTC where TableName=@udTable	-- UD Table Columns
select * from bUDTM where TableName=@udTable	-- UD Table Modules (not used)

select * from vDDFHc where Form = @udTable		-- UD Table Form Header
select * from vDDFIc where Form = @udTable		-- UD Table Form Fields
select * from vDDFLc where Form = @udTable		-- UD Table Form Field Lookups
select * from vDDFTc where Form = @udTable		-- UD Table Form Tabs
select * from vDDFormButtonsCustom where Form = @udTable		-- UD Table Form Custom Button
select * from vDDFormButtonParametersCustom where Form = @udTable		-- UD Table Form Custom Button Parameters
*/
--select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA='dbo' and TABLE_NAME='budCompanyRates'

if exists ( select 1 from sysobjects where name='mspCreateUDTableFromDBObject' and type='P' )
begin
	print 'DROP PROCEDURE mspCreateUDTableFromDBObject'
	DROP PROCEDURE mspCreateUDTableFromDBObject
end
go

print 'CREATE PROCEDURE mspCreateUDTableFromDBObject'
go

CREATE PROCEDURE mspCreateUDTableFromDBObject
(
	@udTable varchar(50)
,	@udTableSchema varchar(20) = 'dbo'
,	@udTableDesc varchar(30)
)

as

declare	@udTableView varchar(20)

declare	@col_id		smallint
declare	@col_name	sysname
declare	@col_typename	sysname
declare	@col_length smallint
declare	@col_prec	smallint	
declare	@col_scale	smallint
declare @isnullable	bYN

declare @ix_name sysname
declare @colix_colname sysname
declare @colix_column_id smallint

if len(@udTable) > 20
begin
	print 'Database table name must be <= 20 characters (with a "bud" prefix).'
	return -1
end

if @udTable not like 'bud%'
begin
	print 'Database table must have a "bud" prefix to conform to Viewpoint standards.'
	return -1
end

select @udTableView = right(@udTable,len(@udTable)-1)

print @udTableSchema + '.' + @udTable + ' (' + @udTableView + ')'
	
if not exists (select 1 from INFORMATION_SCHEMA.TABLES where TABLE_NAME=@udTable and TABLE_SCHEMA=@udTableSchema AND TABLE_TYPE='BASE TABLE' )
begin
	print 'Table ' + @udTableSchema + '.' + @udTable + ' does not exist.'
	return -1
end
else
begin
	print 'Table ' + @udTableSchema + '.' + @udTable + ' exists exist.'

	if exists ( select 1 from bUDTH where TableName=@udTableView ) 
	begin
		print 'View ' + @udTableSchema + '.' + @udTableView + ' already exists in bUDTH for table ' + @udTable
		print 'Update of existing UD table ( --- LATER --- )'
		return -1
	end
	else
	begin
		print 'View ' + @udTableSchema + '.' + @udTableView + ' does not exist in bUDTH for table ' + @udTable
		print 'Time to create a new UD table.'

		print ''
		print replicate('-',120)
		print
			cast('' as char(5))
		+	cast(coalesce(@udTableSchema + '.' + @udTableView,'') as char(30))		--smallint
		+	cast(coalesce('"' + @udTableDesc + '"','') as char(30))	--sysname
		+	cast(coalesce('(' + @udTableView + ')','') as char(30))	--sysname
		print replicate('-',120)

		-- INSERT bUDTH Header Row
		/*
		INSERT INTO [dbo].[bUDTH]
           ([TableName]
           ,[Description]
           ,[FormName]
           ,[CompanyBasedYN]
           ,[CreatedBy]
           ,[DateCreated]
           ,[LastRunDate]
           ,[Notes]
           ,[Created]
           ,[Dirty]
           ,[UniqueAttchID]
           ,[UseNotesTab]
           ,[AuditTable])
		 VALUES
           (<TableName, varchar(20),>
           ,<Description, bDesc,>
           ,<FormName, bDesc,>
           ,<CompanyBasedYN, bYN,>
           ,<CreatedBy, bVPUserName,>
           ,<DateCreated, bDate,>
           ,<LastRunDate, bDate,>
           ,<Notes, varchar(max),>
           ,<Created, bYN,>
           ,<Dirty, bYN,>
           ,<UniqueAttchID, uniqueidentifier,>
           ,<UseNotesTab, int,>
           ,<AuditTable, bYN,>)
		*/



		-- INSERT vDDFHc Customer Form Header Row
		/*
		INSERT INTO [dbo].[vDDFHc]
           ([Form]
           ,[Title]
           ,[FormType]
           ,[ShowOnMenu]
           ,[IconKey]
           ,[ViewName]
           ,[JoinClause]
           ,[WhereClause]
           ,[AssemblyName]
           ,[FormClassName]
           ,[ProgressClip]
           ,[FormNumber]
           ,[NotesTab]
           ,[LoadProc]
           ,[LoadParams]
           ,[PostedTable]
           ,[AllowAttachments]
           ,[Version]
           ,[Mod]
           ,[CoColumn]
           ,[OrderByClause]
           ,[DefaultTabPage]
           ,[SecurityForm]
           ,[DetailFormSecurity]
           ,[DefaultAttachmentTypeID]
           ,[ShowFormProperties]
           ,[ShowFieldProperties]
           ,[FormattedNotesTab])
		VALUES
           (<Form, varchar(30),>
           ,<Title, varchar(30),>
           ,<FormType, tinyint,>
           ,<ShowOnMenu, bYN,>
           ,<IconKey, varchar(20),>
           ,<ViewName, varchar(257),>
           ,<JoinClause, varchar(6000),>
           ,<WhereClause, varchar(256),>
           ,<AssemblyName, varchar(50),>
           ,<FormClassName, varchar(50),>
           ,<ProgressClip, varchar(256),>
           ,<FormNumber, smallint,>
           ,<NotesTab, tinyint,>
           ,<LoadProc, varchar(30),>
           ,<LoadParams, varchar(256),>
           ,<PostedTable, varchar(30),>
           ,<AllowAttachments, bYN,>
           ,<Version, tinyint,>
           ,<Mod, char(2),>
           ,<CoColumn, varchar(30),>
           ,<OrderByClause, varchar(256),>
           ,<DefaultTabPage, tinyint,>
           ,<SecurityForm, varchar(30),>
           ,<DetailFormSecurity, bYN,>
           ,<DefaultAttachmentTypeID, int,>
           ,<ShowFormProperties, bYN,>
           ,<ShowFieldProperties, bYN,>
           ,<FormattedNotesTab, tinyint,>)
			*/

		print
			cast('' as char(10))
		+	cast('ID' as char(8))		--smallint
		+	cast('Name' as char(30))	--sysname
		+	cast('Type' as char(25))	--tinyint
		+	cast('Len' as char(8)) --smallint
		+	cast('Prec' as char(8))	--smallint	
		+	cast('Scale' as char(8))	--smallint	
		+	cast('Nullable' as char(8))	--smallint		
		print replicate('-',120)

		declare col_cur cursor for
		select 
			sc.colid	
		,	sc.name
		,	st.name
		,	sc.length
		,	sc.prec
		,	sc.scale
		,	case sc.isnullable when 0 then 'N' else 'Y' END
		from 
			sysobjects so join 
			syscolumns sc on 
				so.id=sc.id join 
			systypes st on 
				sc.xusertype=st.xusertype 
		where 
			so.name=@udTable
		and user_name(so.uid)=@udTableSchema
		order by
			sc.colid

		open col_cur
		fetch col_cur into
			@col_id		--smallint
		,	@col_name	--sysname
		,	@col_typename	--sysname
		,	@col_length --smallint
		,	@col_prec	--smallint	
		,	@col_scale	--smallint	
		,	@isnullable

		while @@fetch_status=0
		begin
		
			print
				cast('' as char(10))
			+	cast(coalesce(@col_id,'') as char(8))		--smallint
			+	cast(coalesce(@col_name,'') as char(30))	--sysname
			+	cast(coalesce(@col_typename,'') as char(25))	--tinyint
			+	cast(coalesce(@col_length,'') as char(8)) --smallint
			+	cast(coalesce(@col_prec,'') as char(8))	--smallint	
			+	cast(coalesce(@col_scale,'') as char(11))	--smallint	
			+	cast(coalesce(@isnullable,'') as char(5))	--smallint

			-- INSERT bUDTC Detail Rows
			/*
			INSERT INTO [dbo].[bUDTC]
			   ([TableName]
			   ,[ColumnName]
			   ,[Description]
			   ,[KeySeq]
			   ,[DataType]
			   ,[InputType]
			   ,[InputMask]
			   ,[InputLength]
			   ,[Prec]
			   ,[FormSeq]
			   ,[ControlType]
			   ,[OptionButtons]
			   ,[StatusText]
			   ,[Tab]
			   ,[Notes]
			   ,[DDFISeq]
			   ,[UniqueAttchID]
			   ,[AutoSeqType]
			   ,[ComboType])
			VALUES
			   (<TableName, varchar(20),>
			   ,<ColumnName, varchar(30),>
			   ,<Description, bDesc,>
			   ,<KeySeq, tinyint,>
			   ,<DataType, varchar(20),>
			   ,<InputType, tinyint,>
			   ,<InputMask, varchar(20),>
			   ,<InputLength, int,>
			   ,<Prec, tinyint,>
			   ,<FormSeq, int,>
			   ,<ControlType, tinyint,>
			   ,<OptionButtons, int,>
			   ,<StatusText, varchar(60),>
			   ,<Tab, tinyint,>
			   ,<Notes, varchar(max),>
			   ,<DDFISeq, int,>
			   ,<UniqueAttchID, uniqueidentifier,>
			   ,<AutoSeqType, tinyint,>
			   ,<ComboType, varchar(20),>)
				*/

			-- INSERT vDDFIc Custom Form Fields Rows
			/*
			INSERT INTO [dbo].[vDDFIc]
					   ([Form]
					   ,[Seq]
					   ,[ViewName]
					   ,[ColumnName]
					   ,[Description]
					   ,[Datatype]
					   ,[InputType]
					   ,[InputMask]
					   ,[InputLength]
					   ,[Prec]
					   ,[ActiveLookup]
					   ,[LookupParams]
					   ,[LookupLoadSeq]
					   ,[SetupForm]
					   ,[SetupParams]
					   ,[StatusText]
					   ,[Tab]
					   ,[TabIndex]
					   ,[Req]
					   ,[ValProc]
					   ,[ValParams]
					   ,[ValLevel]
					   ,[UpdateGroup]
					   ,[ControlType]
					   ,[ControlPosition]
					   ,[FieldType]
					   ,[DefaultType]
					   ,[DefaultValue]
					   ,[InputSkip]
					   ,[Label]
					   ,[ShowGrid]
					   ,[ShowForm]
					   ,[GridCol]
					   ,[AutoSeqType]
					   ,[MinValue]
					   ,[MaxValue]
					   ,[ValExpression]
					   ,[ValExpError]
					   ,[ComboType]
					   ,[GridColHeading]
					   ,[HeaderLinkSeq]
					   ,[CustomControlSize]
					   ,[Computed]
					   ,[ShowDesc]
					   ,[ColWidth]
					   ,[DescriptionColWidth]
					   ,[IsFormFilter]
					   ,[ExcludeFromAggregation])
				 VALUES
					   (<Form, varchar(30),>
					   ,<Seq, smallint,>
					   ,<ViewName, varchar(257),>
					   ,<ColumnName, varchar(500),>
					   ,<Description, varchar(60),>
					   ,<Datatype, varchar(30),>
					   ,<InputType, tinyint,>
					   ,<InputMask, varchar(30),>
					   ,<InputLength, smallint,>
					   ,<Prec, tinyint,>
					   ,<ActiveLookup, bYN,>
					   ,<LookupParams, varchar(256),>
					   ,<LookupLoadSeq, tinyint,>
					   ,<SetupForm, varchar(30),>
					   ,<SetupParams, varchar(256),>
					   ,<StatusText, varchar(256),>
					   ,<Tab, tinyint,>
					   ,<TabIndex, smallint,>
					   ,<Req, bYN,>
					   ,<ValProc, varchar(60),>
					   ,<ValParams, varchar(256),>
					   ,<ValLevel, tinyint,>
					   ,<UpdateGroup, tinyint,>
					   ,<ControlType, tinyint,>
					   ,<ControlPosition, varchar(20),>
					   ,<FieldType, tinyint,>
					   ,<DefaultType, tinyint,>
					   ,<DefaultValue, varchar(256),>
					   ,<InputSkip, bYN,>
					   ,<Label, varchar(30),>
					   ,<ShowGrid, bYN,>
					   ,<ShowForm, bYN,>
					   ,<GridCol, smallint,>
					   ,<AutoSeqType, tinyint,>
					   ,<MinValue, varchar(20),>
					   ,<MaxValue, varchar(20),>
					   ,<ValExpression, varchar(256),>
					   ,<ValExpError, varchar(256),>
					   ,<ComboType, varchar(20),>
					   ,<GridColHeading, varchar(30),>
					   ,<HeaderLinkSeq, smallint,>
					   ,<CustomControlSize, varchar(20),>
					   ,<Computed, bYN,>
					   ,<ShowDesc, tinyint,>
					   ,<ColWidth, smallint,>
					   ,<DescriptionColWidth, smallint,>
					   ,<IsFormFilter, bYN,>
					   ,<ExcludeFromAggregation, bYN,>)
					*/


			fetch col_cur into
				@col_id		--smallint
			,	@col_name	--sysname
			,	@col_typename	--sysname
			,	@col_length --smallint
			,	@col_prec	--smallint	
			,	@col_scale	--smallint	
			,	@isnullable		
		end
		
		close col_cur
		deallocate col_cur
				
		-- GET UNIQUE INDEX COLUMNS TO SET UD DEFINITION
		
		declare ix_cur cursor for
		select i.name, c.name, c.column_id
		 from sys.tables t
		inner join sys.schemas s on t.schema_id = s.schema_id
		inner join sys.indexes i on i.object_id = t.object_id
		inner join sys.index_columns ic on ic.object_id = t.object_id
			inner join sys.columns c on c.object_id = t.object_id and
				ic.column_id = c.column_id
		where i.index_id > 0    
		and i.type in (1, 2) -- clustered & nonclustered only
		and i.is_primary_key = 0 -- do not include PK indexes
		and i.is_unique_constraint = 0 -- do not include UQ
		and i.is_disabled = 0
		and i.is_hypothetical = 0
		and ic.key_ordinal > 0
		and i.is_unique=1
		and s.name=@udTableSchema
		and t.name=@udTable
		for read only

		open ix_cur
		fetch ix_cur into @ix_name, @colix_colname,@colix_column_id
	
		print ''
		print 	cast('' as char(18)) + replicate('-',60)
		print 
			cast('' as char(18))
		+	cast('Unique Clustered Index: ' + coalesce(@ix_name,'') as char(70))		--smallint
		print 	cast('' as char(18)) + replicate('-',60)

		print
			cast('' as char(18))
		+	cast('ColName' as char(30))	--sysname
		+	cast('ColId' as char(8))		--smallint
		print 	cast('' as char(18)) + replicate('-',60)

		while @@fetch_status=0
		begin
			
			print
				cast('' as char(18))
			+	cast(coalesce(@colix_colname,'') as char(30))	--sysname
			+	cast(coalesce(@colix_column_id,'') as char(8))		--smallint

			--UPATE bUDTC to set Key Fields based on Index
			fetch ix_cur into @ix_name, @colix_colname,@colix_column_id
		end

		close ix_cur
		deallocate ix_cur


	end

	-- GRANT PERMISSIONS TO NEW UD FORM to DEFAULT ADMIN GROUP

	print ''
end
go


if exists ( select 1 from sysobjects where name='budMcKUDTable' and type='U' )
begin
	print 'DROP TABLE budMcKUDTable'
	DROP TABLE budMcKUDTable
end
go

print 'CREATE TABLE budMcKUDTable'
go

CREATE TABLE dbo.budMcKUDTable
(
	[Company]		bCompany			not null
,	[Craft]			bCraft				not null
,	[Class]			bClass				not null
,	StartDate		date				not null
,	EndDate			date				not null
,	StandardRate	bRate				not null
,	DateCreated		datetime			not null DEFAULT ( getdate() )
,	CreatedBy		varchar(30)			not null DEFAULT ( suser_sname() )
,	DateModified	datetime			not null DEFAULT ( getdate() )
,	ModifiedBy		varchar(30)			not null DEFAULT ( suser_sname() )
,	UniqueAttchID	uniqueidentifier	NULL
,	KeyID bigint	IDENTITY(1,1)		NOT NULL
)
go

-- CREATE Primary Key, Unique Indexes, Triggers, etc.

CREATE UNIQUE CLUSTERED INDEX [biudMcKUDTable] ON [dbo].[budMcKUDTable]
(
	[Company] ASC,
	[Craft] ASC,
	[Class] ASC,
	StartDate ASC
) ON [PRIMARY]
GO

if exists ( select 1 from sysobjects where name='udMcKUDTable' and type='V' )
begin
	print 'DROP VIEW udMcKUDTable'
	DROP VIEW udMcKUDTable
end
go

print 'CREATE VIEW udMcKUDTable'
go

CREATE VIEW udMcKUDTable
as
SELECT
	*
FROM
	budMcKUDTable
go

exec mspCreateUDTableFromDBObject
	@udTable = 'budMcKUDTable'
,	@udTableSchema = 'dbo'
,	@udTableDesc = 'Sample UD Table'

exec mspCreateUDTableFromDBObject
	@udTable = 'budCompanyRates'
,	@udTableSchema = 'dbo'
,	@udTableDesc = 'Company Rates'



brptARSalesTax
	@ARCo=20
,	