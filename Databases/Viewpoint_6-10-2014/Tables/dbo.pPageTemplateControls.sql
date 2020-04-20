CREATE TABLE [dbo].[pPageTemplateControls]
(
[PageTemplateControlID] [int] NOT NULL IDENTITY(1, 1),
[PageTemplateID] [int] NOT NULL,
[PortalControlID] [int] NOT NULL,
[ControlPosition] [int] NULL,
[ControlIndex] [int] NOT NULL,
[RoleID] [int] NOT NULL,
[HeaderText] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[ClientModified] [bit] NOT NULL CONSTRAINT [DF_pPageTemplateControls_ClientModified] DEFAULT ((0))
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[pPageTemplateControlsAudit] on [dbo].[pPageTemplateControls] for insert, update, delete
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
	
	select @TableName = 'pPageTemplateControls'

	-- date and user
	select 	@UserName = system_user ,
		@UpdateDate = convert(varchar(8), getdate(), 112) + ' ' + convert(varchar(12), getdate(), 114)

	-- Action
	if exists (select * from inserted)
		if exists (select * from deleted)
			select @Type = 'U'
		else
			select @Type = 'I'
	else
		select @Type = 'D'
	

	-- get list of columns
	select * into #ins from inserted
	select * into #del from deleted

	-- Get primary key columns for full outer join
	select	@PKCols = coalesce(@PKCols + ' and', ' on') + ' i.' + c.COLUMN_NAME + ' = d.' + c.COLUMN_NAME
	from	INFORMATION_SCHEMA.TABLE_CONSTRAINTS pk ,
		INFORMATION_SCHEMA.KEY_COLUMN_USAGE c
	where 	pk.TABLE_NAME = @TableName
	and	CONSTRAINT_TYPE = 'PRIMARY KEY'
	and	c.TABLE_NAME = pk.TABLE_NAME
	and	c.CONSTRAINT_NAME = pk.CONSTRAINT_NAME
	
	-- Get primary key select for insert
	select @PKSelect = coalesce(@PKSelect+'+','') + '''<' + COLUMN_NAME + '=''+convert(varchar(100),coalesce(i.' + COLUMN_NAME +',d.' + COLUMN_NAME + '))+''>''' 
	from	INFORMATION_SCHEMA.TABLE_CONSTRAINTS pk ,
		INFORMATION_SCHEMA.KEY_COLUMN_USAGE c
	where 	pk.TABLE_NAME = @TableName
	and	CONSTRAINT_TYPE = 'PRIMARY KEY'
	and	c.TABLE_NAME = pk.TABLE_NAME
	and	c.CONSTRAINT_NAME = pk.CONSTRAINT_NAME
	
	if @PKCols is null
	begin
		raiserror('no PK on table %s', 16, -1, @TableName)
		return
	end
	
	select @field = 0, @maxfield = max(ORDINAL_POSITION) from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = @TableName
	while @field < @maxfield
	begin
		select @field = min(ORDINAL_POSITION) from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = @TableName and ORDINAL_POSITION > @field
		select @DataType = DATA_TYPE from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = @TableName and ORDINAL_POSITION = @field
		IF @DataType <> 'text' AND @DataType <> 'ntext' AND @DataType <> 'image'
			BEGIN
			select @bit = (@field - 1 )% 8 + 1
			select @bit = power(2,@bit - 1)
			select @char = ((@field - 1) / 8) + 1
			if substring(COLUMNS_UPDATED(),@char, 1) & @bit > 0 or @Type in ('I','D')
			begin
				select @fieldname = COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = @TableName and ORDINAL_POSITION = @field
				select @sql = 		'insert pPortalAudit (Type, TableName, PrimaryKey, FieldName, OldValue, NewValue, UpdateDate, UserName)'
				select @sql = @sql + 	' select ''' + @Type + ''''
				select @sql = @sql + 	',''' + @TableName + ''''
				select @sql = @sql + 	',' + @PKSelect
				select @sql = @sql + 	',''' + @fieldname + ''''
				select @sql = @sql + 	',convert(varchar(1000),d.' + @fieldname + ')'
				select @sql = @sql + 	',convert(varchar(1000),i.' + @fieldname + ')'
				select @sql = @sql + 	',''' + @UpdateDate + ''''
				select @sql = @sql + 	',''' + @UserName + ''''
				select @sql = @sql + 	' from #ins i full outer join #del d'
				select @sql = @sql + 	@PKCols
				select @sql = @sql + 	' where i.' + @fieldname + ' <> d.' + @fieldname 
				select @sql = @sql + 	' or (i.' + @fieldname + ' is null and  d.' + @fieldname + ' is not null)' 
				select @sql = @sql + 	' or (i.' + @fieldname + ' is not null and  d.' + @fieldname + ' is null)' 
				EXECUTE sp_executesql @sql
			end
		end
	end

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE Trigger [dbo].[ptPageTemplateControlsi] on [dbo].[pPageTemplateControls] for INSERT as 
 
DECLARE @portalcontrolid int,
	@allowadd bit, @allowedit bit, @allowdelete bit, @roleid int, 
	@pagetemplatecontrolid int, @pagetemplateid int
  
SELECT @portalcontrolid = PortalControlID, @pagetemplatecontrolid = PageTemplateControlID, 
	@pagetemplateid  = PageTemplateID FROM Inserted

DECLARE pcPortalControlSecurity cursor local fast_forward for
	SELECT RoleID, AllowAdd, AllowEdit, AllowDelete
		FROM pPortalControlSecurityTemplate WHERE PortalControlID = @portalcontrolid
		
	OPEN pcPortalControlSecurity
	FETCH NEXT FROM pcPortalControlSecurity into @roleid, @allowadd, @allowedit, @allowdelete
			
	WHILE (@@FETCH_STATUS = 0)
		begin
		INSERT INTO pPageTemplateControlSecurity (PageTemplateControlID, RoleID, PageTemplateID,
			AllowAdd, AllowEdit, AllowDelete)
			VALUES (@pagetemplatecontrolid, @roleid, @pagetemplateid, @allowadd, @allowedit, @allowdelete)
			fetch next from pcPortalControlSecurity into  @roleid, @allowadd, @allowedit, @allowdelete
		end
			
		close pcPortalControlSecurity
		deallocate pcPortalControlSecurity
 
RETURN
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  TRIGGER [dbo].[ptPageTemplateControlsu] ON [dbo].[pPageTemplateControls] FOR UPDATE AS 
 
DECLARE @ID int, @PageTemplateID int
  
SELECT @ID = PageTemplateControlID, @PageTemplateID = PageTemplateID FROM Inserted

IF @ID < 50000
	BEGIN
	UPDATE pPageTemplateControls SET ClientModified = 1 WHERE PageTemplateControlID = @ID AND ClientModified <> 1
	
	UPDATE pPageTemplates SET ClientModified = 1 WHERE PageTemplateID < 50000 AND PageTemplateID = @PageTemplateID AND ClientModified <> 1	
	END


GO
ALTER TABLE [dbo].[pPageTemplateControls] ADD CONSTRAINT [PK_pPageMaster] PRIMARY KEY CLUSTERED  ([PageTemplateControlID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[pPageTemplateControls] WITH NOCHECK ADD CONSTRAINT [FK_pPageTemplateControls_pPageTemplates] FOREIGN KEY ([PageTemplateID]) REFERENCES [dbo].[pPageTemplates] ([PageTemplateID])
GO
ALTER TABLE [dbo].[pPageTemplateControls] WITH NOCHECK ADD CONSTRAINT [FK_pPageTemplateControls_pPortalControls] FOREIGN KEY ([PortalControlID]) REFERENCES [dbo].[pPortalControls] ([PortalControlID])
GO
ALTER TABLE [dbo].[pPageTemplateControls] WITH NOCHECK ADD CONSTRAINT [FK_pPageTemplateControls_pRoles] FOREIGN KEY ([RoleID]) REFERENCES [dbo].[pRoles] ([RoleID])
GO
ALTER TABLE [dbo].[pPageTemplateControls] NOCHECK CONSTRAINT [FK_pPageTemplateControls_pPageTemplates]
GO
ALTER TABLE [dbo].[pPageTemplateControls] NOCHECK CONSTRAINT [FK_pPageTemplateControls_pPortalControls]
GO
ALTER TABLE [dbo].[pPageTemplateControls] NOCHECK CONSTRAINT [FK_pPageTemplateControls_pRoles]
GO
GRANT SELECT ON  [dbo].[pPageTemplateControls] TO [VCSPortal]
GRANT INSERT ON  [dbo].[pPageTemplateControls] TO [VCSPortal]
GRANT DELETE ON  [dbo].[pPageTemplateControls] TO [VCSPortal]
GRANT UPDATE ON  [dbo].[pPageTemplateControls] TO [VCSPortal]
GRANT SELECT ON  [dbo].[pPageTemplateControls] TO [viewpointcs]
GRANT INSERT ON  [dbo].[pPageTemplateControls] TO [viewpointcs]
GRANT DELETE ON  [dbo].[pPageTemplateControls] TO [viewpointcs]
GRANT UPDATE ON  [dbo].[pPageTemplateControls] TO [viewpointcs]
GO
