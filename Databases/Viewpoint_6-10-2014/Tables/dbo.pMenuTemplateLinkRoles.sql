CREATE TABLE [dbo].[pMenuTemplateLinkRoles]
(
[MenuTemplateLinkID] [int] NOT NULL,
[MenuTemplateID] [int] NOT NULL,
[RoleID] [int] NOT NULL,
[AllowAccess] [bit] NOT NULL CONSTRAINT [DF_pMenuTemplateLinkRoles_AllowAccess] DEFAULT ((0)),
[ClientModified] [bit] NOT NULL CONSTRAINT [DF_pMenuTemplateLinkRoles_ClientModified] DEFAULT ((0))
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[pMenuTemplateLinkRolesAudit] on [dbo].[pMenuTemplateLinkRoles] for insert, update, delete
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
	
	select @TableName = 'pMenuTemplateLinkRoles'

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

CREATE  TRIGGER [dbo].[ptMenuTemplateLinkRolesu] ON [dbo].[pMenuTemplateLinkRoles] FOR UPDATE AS 
 
DECLARE @MenuTemplateLinkID int, @MenuTemplateID int, @RoleID int
  
SELECT @MenuTemplateLinkID = MenuTemplateLinkID, @MenuTemplateID = MenuTemplateID, @RoleID = RoleID FROM Inserted

IF @MenuTemplateLinkID < 50000 AND @MenuTemplateID < 50000 AND @RoleID < 50000
	BEGIN
	UPDATE pMenuTemplateLinkRoles SET ClientModified = 1 WHERE MenuTemplateLinkID = @MenuTemplateLinkID AND
		MenuTemplateID = @MenuTemplateID AND RoleID = @RoleID AND ClientModified <> 1
	END



GO
ALTER TABLE [dbo].[pMenuTemplateLinkRoles] ADD CONSTRAINT [PK_pMenuTemplateLinkRoles] PRIMARY KEY CLUSTERED  ([MenuTemplateLinkID], [MenuTemplateID], [RoleID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[pMenuTemplateLinkRoles] WITH NOCHECK ADD CONSTRAINT [FK_pMenuTemplateLinkRoles_pMenuTemplateLinks] FOREIGN KEY ([MenuTemplateLinkID], [MenuTemplateID]) REFERENCES [dbo].[pMenuTemplateLinks] ([MenuTemplateLinkID], [MenuTemplateID])
GO
ALTER TABLE [dbo].[pMenuTemplateLinkRoles] WITH NOCHECK ADD CONSTRAINT [FK_pMenuTemplateLinkRoles_pRoles] FOREIGN KEY ([RoleID]) REFERENCES [dbo].[pRoles] ([RoleID])
GO
ALTER TABLE [dbo].[pMenuTemplateLinkRoles] NOCHECK CONSTRAINT [FK_pMenuTemplateLinkRoles_pMenuTemplateLinks]
GO
ALTER TABLE [dbo].[pMenuTemplateLinkRoles] NOCHECK CONSTRAINT [FK_pMenuTemplateLinkRoles_pRoles]
GO
GRANT SELECT ON  [dbo].[pMenuTemplateLinkRoles] TO [VCSPortal]
GRANT INSERT ON  [dbo].[pMenuTemplateLinkRoles] TO [VCSPortal]
GRANT DELETE ON  [dbo].[pMenuTemplateLinkRoles] TO [VCSPortal]
GRANT UPDATE ON  [dbo].[pMenuTemplateLinkRoles] TO [VCSPortal]
GRANT SELECT ON  [dbo].[pMenuTemplateLinkRoles] TO [viewpointcs]
GRANT INSERT ON  [dbo].[pMenuTemplateLinkRoles] TO [viewpointcs]
GRANT DELETE ON  [dbo].[pMenuTemplateLinkRoles] TO [viewpointcs]
GRANT UPDATE ON  [dbo].[pMenuTemplateLinkRoles] TO [viewpointcs]
GO
