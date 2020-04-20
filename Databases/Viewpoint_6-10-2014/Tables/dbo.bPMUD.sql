CREATE TABLE [dbo].[bPMUD]
(
[Template] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[RecordType] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Identifier] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Seq] [int] NULL,
[Form] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ColumnName] [nvarchar] (30) COLLATE Latin1_General_BIN NULL,
[ColDesc] [dbo].[bDesc] NULL,
[DefaultValue] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[FormatInfo] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Required] [dbo].[bYN] NULL,
[RecColumn] [int] NULL,
[BegPos] [int] NULL,
[EndPos] [int] NULL,
[ViewpointDefault] [dbo].[bYN] NULL CONSTRAINT [DF_bPMUD_ViewpointDefault] DEFAULT ('N'),
[ViewpointDefaultValue] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Datatype] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[UserDefault] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[OverrideYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMUD_OverrideYN] DEFAULT ('N'),
[UpdateKeyYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMUD_UpdateKeyYN] DEFAULT ('N'),
[UpdateValueYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMUD_UpdateValueYN] DEFAULT ('N'),
[ImportPromptYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMUD_ImportPromptYN] DEFAULT ('N'),
[XMLTag] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Hidden] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMUD_Hidden] DEFAULT ('N')
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Created By:		GP	02/26/2009
-- Modified By:		JayR removed unused code
--		
-- Description:		Deletes user defined columns from PM work tables
--					when deleted from bPMUD. Also removes associated DDFI
--					records.
-- =============================================
CREATE trigger [dbo].[btPMUDd] on [dbo].[bPMUD] for DELETE as


declare @errmsg varchar(255), @NumRows int, @Template varchar(10), @ColumnName varchar(20), 
	@RecordType varchar(20), @SQLString nvarchar(255)

select @NumRows = @@rowcount
if @NumRows = 0 return
set nocount on

--Get inserted ColumnName and RecordType
select @Template=Template, @ColumnName=ColumnName, @RecordType=RecordType from deleted d

--Find user defined columns
if substring(@ColumnName, 1, 2)='ud'
begin
	--Remove UD columns from PM work tables w/ DDFI entries
	if @RecordType = 'Item'
	begin
		if not exists(select top 1 1 from PMUD where Template<>@Template and ColumnName=@ColumnName) and
			exists(select top 1 1 from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME='bPMWI' and COLUMN_NAME=@ColumnName)
		begin
			--Remove UD column from PM work table
			set @SQLString = 'alter table bPMWI drop column ' + @ColumnName
			execute dbo.vspJCPPudUpdate @SQLString
			execute dbo.vspVAViewGen 'PMWI', 'bPMWI', @errmsg

			--Delete DDFI entry
			delete vDDFIc
			where Form='PMImportEditItems' and ColumnName=@ColumnName
		end
	end

	if @RecordType = 'Phase'
	begin
		if not exists(select top 1 1 from PMUD where Template<>@Template and ColumnName=@ColumnName) and
			exists(select top 1 1 from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME='bPMWP' and COLUMN_NAME=@ColumnName)
		begin
			--Remove UD column from PM work table
			set @SQLString = 'alter table bPMWP drop column ' + @ColumnName
			execute dbo.vspJCPPudUpdate @SQLString
			execute dbo.vspVAViewGen 'PMWP', 'bPMWP', @errmsg

			--Delete DDFI entry
			delete vDDFIc
			where Form='PMImportEditPhases' and ColumnName=@ColumnName
		end
	end

	if @RecordType = 'CostType'
	begin
		if not exists(select top 1 1 from PMUD where Template<>@Template and ColumnName=@ColumnName) and
			exists(select top 1 1 from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME='bPMWD' and COLUMN_NAME=@ColumnName)
		begin
			--Remove UD column from PM work table
			set @SQLString = 'alter table bPMWD drop column ' + @ColumnName
			execute dbo.vspJCPPudUpdate @SQLString
			execute dbo.vspVAViewGen 'PMWD', 'bPMWD', @errmsg

			--Delete DDFI entry
			delete vDDFIc
			where Form='PMImportEditCostTypes' and ColumnName=@ColumnName
		end
	end

	if @RecordType = 'SubDetail'
	begin
		if not exists(select top 1 1 from PMUD where Template<>@Template and ColumnName=@ColumnName) and
			exists(select top 1 1 from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME='bPMWS' and COLUMN_NAME=@ColumnName)
		begin
			--Remove UD column from PM work table
			set @SQLString = 'alter table bPMDS drop column ' + @ColumnName
			execute dbo.vspJCPPudUpdate @SQLString
			execute dbo.vspVAViewGen 'PMWS', 'bPMWS', @errmsg

			--Delete DDFI entry
			delete vDDFIc
			where Form='PMImportEditSubs' and ColumnName=@ColumnName
		end
	end

	if @RecordType = 'MatlDetail'
	begin
		if not exists(select top 1 1 from PMUD where Template<>@Template and ColumnName=@ColumnName) and
			exists(select top 1 1 from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME='bPMWM' and COLUMN_NAME=@ColumnName)
		begin
			--Remove UD column from PM work table
			set @SQLString = 'alter table bPMWM drop column ' + @ColumnName
			execute dbo.vspJCPPudUpdate @SQLString
			execute dbo.vspVAViewGen 'PMWM', 'bPMWM', @errmsg

			--Delete DDFI entry
			delete vDDFIc
			where Form='PMImportEditMatls' and ColumnName=@ColumnName
		end
	end

	if @RecordType = 'Estimate'
	begin
		if not exists(select top 1 1 from PMUD where Template<>@Template and ColumnName=@ColumnName) and
			exists(select top 1 1 from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME='bPMWH' and COLUMN_NAME=@ColumnName)
		begin
			--Remove UD column from PM work table
			set @SQLString = 'alter table bPMWH drop column ' + @ColumnName
			execute dbo.vspJCPPudUpdate @SQLString
			execute dbo.vspVAViewGen 'PMWH', 'bPMWH', @errmsg

			--Delete DDFI entry
			delete vDDFIc
			where Form='PMImportEdit' and ColumnName=@ColumnName
		end
	end
end

return


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Created By:		GP	02/26/2009
-- Modified By:
--		
-- Description:		Inserts user defined columns into PM work tables
--					when inserted into bPMUD. Also inserts associated DDFI
--					records.
-- =============================================
CREATE trigger [dbo].[btPMUDi] on [dbo].[bPMUD] for INSERT as


declare @errmsg varchar(500), @NumRows int, @ColumnName varchar(20), @RecordType varchar(20), @SQLString nvarchar(500),
		@Datatype varchar(20), @Description varchar(60), @InputType tinyint, @InputLength smallint, @Prec tinyint, 
		@Form varchar(30), @View varchar(20), @OldView varchar(20), @Seq int

select @NumRows = @@rowcount
if @NumRows = 0 return
set nocount on

--Get inserted ColumnName and RecordType
select @ColumnName=ColumnName, @RecordType=RecordType, @Datatype=Datatype, @Description=ColDesc from inserted i

--Find user defined columns
if substring(@ColumnName, 1, 2) = 'ud'
begin
	----------
	-- ITEM --
	----------
	if @RecordType = 'Item'
	begin
		--Find DDFI datatype if null
		if @Datatype is null
		begin
			select @Datatype=Datatype, @InputType=InputType, @InputLength=InputLength, @Prec=Prec 
			from vDDFIc with (nolock) 
			where Form='JCCI' and ColumnName=@ColumnName

			--Check if datatype is in DDDT, get SQLDatatype
			if @Datatype is not null
			begin
				if exists(select top 1 1 from DDDT where Datatype=@Datatype) 
				begin
					select @Datatype = SQLDatatype from DDDT with (nolock) where Datatype=@Datatype
				end
			end

			--Create SQLDatatype if null
			if @Datatype is null
			begin
				select @Datatype = case @InputType when 0 then 'varchar' when 1 then 'numeric'
					when 2 then 'datetime' when 3 then 'datetime' when 4 then 'datetime' when 5 then 'varchar' end
				
				if @Datatype = 'varchar' set @Datatype = @Datatype + '(' + cast(@InputLength as varchar(5)) + ')'
				if @Datatype = 'numeric' select @Datatype = case @Prec when 0 then 'tinyint' when 1 then 'smallint'
					when 2 then 'int' when 3 then 'numeric' when 4 then 'bigint' end
			end
		end

		--Add UD column to PM work table
		set @SQLString = 'alter table bPMWI add ' + @ColumnName + ' ' + @Datatype + ' null'
		if not exists(select top 1 1 from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME='bPMWI' and COLUMN_NAME=@ColumnName)
		begin
			execute dbo.vspJCPPudUpdate @SQLString
			execute dbo.vspVAViewGen 'PMWI', 'bPMWI', @errmsg
		end

		--Set Form, View, and OldView values
		select @Form='PMImportEditItems', @View='PMWI', @OldView='JCCI'
	end

	-----------
	-- Phase --
	-----------
	if @RecordType = 'Phase'
	begin
		--Find DDFI datatype if null
		if @Datatype is null
		begin
			select @Datatype=Datatype, @InputType=InputType, @InputLength=InputLength, @Prec=Prec 
			from vDDFIc with (nolock) 
			where Form='JCJP' and ColumnName=@ColumnName

			--Check if datatype is in DDDT, get SQLDatatype
			if @Datatype is not null
			begin
				if exists(select top 1 1 from DDDT where Datatype=@Datatype) 
				begin
					select @Datatype = SQLDatatype from DDDT with (nolock) where Datatype=@Datatype
				end
			end

			--Create SQL datatype if null
			if @Datatype is null
			begin
				select @Datatype = case @InputType when 0 then 'varchar' when 1 then 'numeric'
					when 2 then 'datetime' when 3 then 'datetime' when 4 then 'datetime' when 5 then 'varchar' end
				
				if @Datatype = 'varchar' set @Datatype = @Datatype + '(' + cast(@InputLength as varchar(5)) + ')'
				if @Datatype = 'numeric' select @Datatype = case @Prec when 0 then 'tinyint' when 1 then 'smallint'
					when 2 then 'int' when 3 then 'numeric' when 4 then 'bigint' end
			end
		end

		--Add UD column to PM work table
		set @SQLString = 'alter table bPMWP add ' + @ColumnName + ' ' + @Datatype + ' null'
		if not exists(select top 1 1 from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME='bPMWP' and COLUMN_NAME=@ColumnName)
		begin
			execute dbo.vspJCPPudUpdate @SQLString
			execute dbo.vspVAViewGen 'PMWP', 'bPMWP', @errmsg
		end

		--Set Form, View, and OldView values
		select @Form='PMImportEditPhases', @View='PMWP', @OldView='JCJP'		
	end

	--------------
	-- CostType --
	--------------
	if @RecordType = 'CostType'
	begin
		--Find DDFI datatype if null
		if @Datatype is null
		begin
			select @Datatype=Datatype, @InputType=InputType, @InputLength=InputLength, @Prec=Prec 
			from vDDFIc with (nolock) 
			where Form='JCJPCostTypes' and ColumnName=@ColumnName

			--Check if datatype is in DDDT, get SQLDatatype
			if @Datatype is not null
			begin
				if exists(select top 1 1 from DDDT where Datatype=@Datatype) 
				begin
					select @Datatype = SQLDatatype from DDDT with (nolock) where Datatype=@Datatype
				end
			end

			--Create SQL datatype if null
			if @Datatype is null
			begin
				select @Datatype = case @InputType when 0 then 'varchar' when 1 then 'numeric'
					when 2 then 'datetime' when 3 then 'datetime' when 4 then 'datetime' when 5 then 'varchar' end
				
				if @Datatype = 'varchar' set @Datatype = @Datatype + '(' + cast(@InputLength as varchar(5)) + ')'
				if @Datatype = 'numeric' select @Datatype = case @Prec when 0 then 'tinyint' when 1 then 'smallint'
					when 2 then 'int' when 3 then 'numeric' when 4 then 'bigint' end
			end
		end

		--Add UD column to PM work table
		set @SQLString = 'alter table bPMWD add ' + @ColumnName + ' ' + @Datatype + ' null'
		if not exists(select top 1 1 from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME='bPMWD' and COLUMN_NAME=@ColumnName)
		begin
			execute dbo.vspJCPPudUpdate @SQLString
			execute dbo.vspVAViewGen 'PMWD', 'bPMWD', @errmsg
		end

		--Set Form, View, and OldView values
		select @Form='PMImportEditCostTypes', @View='PMWD', @OldView='JCJPCostTypes'
	end

	---------------
	-- SubDetail --
	---------------
	if @RecordType = 'SubDetail'
	begin
		--Find DDFI datatype if null
		if @Datatype is null
		begin
			select @Datatype=Datatype, @InputType=InputType, @InputLength=InputLength, @Prec=Prec 
			from vDDFIc with (nolock) 
			where Form='PMSubcontractNonIntfc' and ColumnName=@ColumnName

			--Check if datatype is in DDDT, get SQLDatatype
			if @Datatype is not null
			begin
				if exists(select top 1 1 from DDDT where Datatype=@Datatype) 
				begin
					select @Datatype = SQLDatatype from DDDT with (nolock) where Datatype=@Datatype
				end
			end

			--Create SQL datatype if null
			if @Datatype is null
			begin
				select @Datatype = case @InputType when 0 then 'varchar' when 1 then 'numeric'
					when 2 then 'datetime' when 3 then 'datetime' when 4 then 'datetime' when 5 then 'varchar' end
				
				if @Datatype = 'varchar' set @Datatype = @Datatype + '(' + cast(@InputLength as varchar(5)) + ')'
				if @Datatype = 'numeric' select @Datatype = case @Prec when 0 then 'tinyint' when 1 then 'smallint'
					when 2 then 'int' when 3 then 'numeric' when 4 then 'bigint' end
			end
		end

		--Add UD column to PM work table
		set @SQLString = 'alter table bPMWS add ' + @ColumnName + ' ' + @Datatype + ' null'
		if not exists(select top 1 1 from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME='bPMWS' and COLUMN_NAME=@ColumnName)
		begin
			execute dbo.vspJCPPudUpdate @SQLString
			execute dbo.vspVAViewGen 'PMWS', 'bPMWS', @errmsg
		end

		--Set Form, View, and OldView values
		select @Form='PMImportEditSubs', @View='PMWS', @OldView='PMSubcontractNonIntfc'
	end

	----------------
	-- MatlDetail --
	----------------
	if @RecordType = 'MatlDetail'
	begin
		--Find DDFI datatype if null
		if @Datatype is null
		begin
			select @Datatype=Datatype, @InputType=InputType, @InputLength=InputLength, @Prec=Prec 
			from vDDFIc with (nolock) 
			where Form='PMMaterialNonIntfc' and ColumnName=@ColumnName

			--Check if datatype is in DDDT, get SQLDatatype
			if @Datatype is not null
			begin
				if exists(select top 1 1 from DDDT where Datatype=@Datatype) 
				begin
					select @Datatype = SQLDatatype from DDDT with (nolock) where Datatype=@Datatype
				end
			end

			--Create SQL datatype if null
			if @Datatype is null
			begin
				select @Datatype = case @InputType when 0 then 'varchar' when 1 then 'numeric'
					when 2 then 'datetime' when 3 then 'datetime' when 4 then 'datetime' when 5 then 'varchar' end
				
				if @Datatype = 'varchar' set @Datatype = @Datatype + '(' + cast(@InputLength as varchar(5)) + ')'
				if @Datatype = 'numeric' select @Datatype = case @Prec when 0 then 'tinyint' when 1 then 'smallint'
					when 2 then 'int' when 3 then 'numeric' when 4 then 'bigint' end
			end
		end

		--Add UD column to PM work table
		set @SQLString = 'alter table bPMWM add ' + @ColumnName + ' ' + @Datatype + ' null'
		if not exists(select top 1 1 from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME='bPMWM' and COLUMN_NAME=@ColumnName)
		begin
			execute dbo.vspJCPPudUpdate @SQLString
			execute dbo.vspVAViewGen 'PMWM', 'bPMWM', @errmsg
		end

		--Set Form, View, and OldView values
		select @Form='PMImportEditMatls', @View='PMWM', @OldView='PMMaterialNonIntfc'
	end

	--------------
	-- Estimate --
	--------------
	if @RecordType = 'Estimate'
	begin
		--Find DDFI datatype if null
		if @Datatype is null
		begin
			select @Datatype=Datatype, @InputType=InputType, @InputLength=InputLength, @Prec=Prec 
			from vDDFIc with (nolock) 
			where Form='PMProjects' and ColumnName=@ColumnName

			--Check if datatype is in DDDT, get SQLDatatype
			if @Datatype is not null
			begin
				if exists(select top 1 1 from DDDT where Datatype=@Datatype) 
				begin
					select @Datatype = SQLDatatype from DDDT with (nolock) where Datatype=@Datatype
				end
			end

			--Create SQL datatype if null
			if @Datatype is null
			begin
				select @Datatype = case @InputType when 0 then 'varchar' when 1 then 'numeric'
					when 2 then 'datetime' when 3 then 'datetime' when 4 then 'datetime' when 5 then 'varchar' end
				
				if @Datatype = 'varchar' set @Datatype = @Datatype + '(' + cast(@InputLength as varchar(5)) + ')'
				if @Datatype = 'numeric' select @Datatype = case @Prec when 0 then 'tinyint' when 1 then 'smallint'
					when 2 then 'int' when 3 then 'numeric' when 4 then 'bigint' end
			end
		end

		--Add UD column to PM work table
		set @SQLString = 'alter table bPMWH add ' + @ColumnName + ' ' + @Datatype + ' null'
		if not exists(select top 1 1 from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME='bPMWH' and COLUMN_NAME=@ColumnName)
		begin
			execute dbo.vspJCPPudUpdate @SQLString
			execute dbo.vspVAViewGen 'PMWH', 'bPMWH', @errmsg
		end

		--Set Form, View, and OldView values
		select @Form='PMImportEdit', @View='PMWH', @OldView='PMProjects'
	end

	--InputType, InputMask, and InputLength must be null if system datatype is valid
	if substring(@Datatype,1,1) = 'b' and substring(@Datatype,1,2) <> 'bi'
	begin
		select @InputType = null, @InputLength = null
	end

	--If Datatype is not a system datatype, set it to null
	if @Datatype is not null and substring(@Datatype,1,1) <> 'b'
	begin
		set @Datatype = null
	end 

	--Set Sequence, starting at 5000 and incrementing by 5
	select @Seq = isnull(max(Seq),0) from vDDFIc where Form=@Form and Seq < 5999
	if @Seq < 5000
	begin
		set @Seq = 5000
	end
	else --if @Seq >= 5000
	begin
		set @Seq = @Seq + 5
	end

	--Get vDDFIc values
	select * into #DDFIValues from vDDFIc 	
		where Form=@OldView and ColumnName=@ColumnName and 
			not exists(select top 1 1 from DDFI with (nolock) where Form=@Form and ColumnName=@ColumnName)

	--Update w/ correct Form, Seq, and View
	update #DDFIValues
	set Form = @Form, Seq = @Seq, ViewName = @View

	--Insert vDDFIc record
	insert into vDDFIc
	select * from #DDFIValues

	drop table #DDFIValues

end

return


error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot insert Template Detail record!'
 	RAISERROR(@errmsg, 11, -1);
 	rollback transaction


GO
CREATE UNIQUE NONCLUSTERED INDEX [PK_bPMUD] ON [dbo].[bPMUD] ([Template], [RecordType], [Seq]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMUD] WITH NOCHECK ADD CONSTRAINT [FK_bPMUD_bPMUT] FOREIGN KEY ([Template]) REFERENCES [dbo].[bPMUT] ([Template]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[bPMUD] NOCHECK CONSTRAINT [FK_bPMUD_bPMUT]
GO
