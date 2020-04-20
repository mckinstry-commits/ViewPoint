CREATE TABLE [dbo].[vDDMO]
(
[Mod] [char] (2) COLLATE Latin1_General_BIN NOT NULL,
[Title] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Active] [dbo].[bYN] NOT NULL,
[LicLevel] [tinyint] NOT NULL,
[HelpKeyword] [varchar] (60) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE  trigger [dbo].[vtDDMOd] on [dbo].[vDDMO] for delete 
/*-----------------------------------------------------------------
 *	Created: GG 08/01/03
 *	Modified:
 *
 *	This trigger rejects delete in vDDMO (Modules) if any of the
 *	following error conditions exist:
 *
 *		Forms assigned to Module
 *		Reports assigned to Module
 *
 * 	Adds DD Audit entry
 *
 *
 */----------------------------------------------------------------
 
as



declare @errmsg varchar(255)
if @@rowcount = 0 return

set nocount on
 
-- check DD Module Forms 
if exists (select top 1 1 from deleted d
			join DDMFShared f on f.Mod = d.Mod)
 	begin
 	select @errmsg = 'Forms assigned to Module'
 	goto error
 	end

-- check RP Module Reports 
if exists (select top 1 1 from deleted d
			join RPRMShared f on f.Mod = d.Mod)
 	begin
 	select @errmsg = 'Reports assigned to Module'
 	goto error
 	end

-- DD Audit 
insert dbo.vDDDA (TableName, Action, KeyString, FieldName,
	OldValue, NewValue, RevDate, UserName, HostName)
select 'vDDMO', 'D', 'Module: ' + Mod, null,
	null, null, getdate(), SUSER_SNAME(), host_name()
from deleted
 
return
 
error:
	select @errmsg = @errmsg + ' - cannot delete Module!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
 
 





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtDDMOd_Audit] ON [dbo].[vDDMO]
 AFTER DELETE
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 14 2009  9:56AM

 BEGIN TRY 
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDMO' , '<KeyString Module = "' + REPLACE(CAST(deleted.Mod AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'D' , NULL , NULL , NULL , GETDATE() , HOST_NAME() , 'DELETE FROM vDDMO WHERE Mod = ''' + CAST(deleted.Mod AS VARCHAR(MAX)) + ''''
	FROM deleted
 END TRY 
 BEGIN CATCH 
   RAISERROR('Error in [dbo].[dbo.vtDDMOi_Audit] trigger', 16, 1 ) with log
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtDDMOd_Audit]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE   trigger [dbo].[vtDDMOi] on [dbo].[vDDMO] for INSERT 
/*-----------------------------------------------------------------
 *	Created: GG 08/01/03
 *	Modified:
 *
 *	This trigger rejects insertion in vDDMO (Module) if
 *	any of the following error conditions exist:
 *
 *		Invalid Active flag
 *
 *	Adds audit records to vDDDA
 */----------------------------------------------------------------

as
 


declare @errmsg varchar(255)

if @@rowcount = 0 return

set nocount on
 
-- check Active flag
if exists(select top 1 1 from inserted where Active not in ('Y','N'))
 	begin
 	select @errmsg = 'Invalid Active flag, must be ''Y'' or ''N'''
 	goto error
 	end

-- DD Audit  
insert vDDDA (TableName, Action, KeyString, FieldName, OldValue, 
  	NewValue, RevDate, UserName, HostName)
select 'vDDMO', 'I', 'Module: ' + Mod, null, null,
	null, getdate(), SUSER_SNAME(), host_name()
from inserted 
  	 	 	 
return
 
error:
    select @errmsg = @errmsg + ' - cannot insert Module!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
 
 






GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtDDMOi_Audit] ON [dbo].[vDDMO]
 AFTER INSERT
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 14 2009  9:56AM

 BEGIN TRY 
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDMO' , '<KeyString Module = "' + REPLACE(CAST(inserted.Mod AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'A' , NULL , NULL , NULL , GETDATE() , HOST_NAME() , 'INSERT INTO dbo.[vDDMO] ([Mod], [Title], [Active], [LicLevel]) VALUES (' + ISNULL('''' + REPLACE(CAST(Mod AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL('''' + REPLACE(CAST(Title AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL('''' + REPLACE(CAST(Active AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL(CAST(LicLevel AS NVARCHAR(MAX)), 'NULL') + + ')'
	FROM inserted
 END TRY 
 BEGIN CATCH 
   RAISERROR('Error in [dbo].[dbo.vtDDMOi_Audit] trigger', 16, 1 ) with log
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtDDMOi_Audit]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE    trigger [dbo].[vtDDMOu] on [dbo].[vDDMO] for UPDATE 
/*-----------------------------------------------------------------
 * 	Created: GG 08/01/03
 *	Modified: GG 04/10/06 - mods for LicLevel
 *
 *	This trigger rejects update in vDDMO (Modules) if the
 *	following error condition exists:
 *
 *		Cannot change Module abbreviation
 *
 * Adds DD Audit entries for changed values
 *
 */----------------------------------------------------------------
as


declare @errmsg varchar(255), @numrows int, @validcnt int
 	 
select @numrows = @@rowcount
if @numrows = 0 return

set nocount on
 
/* check for key change */
select @validcnt = count(*) from inserted i
	join deleted d on i.Mod = d.Mod
if @validcnt <> @numrows
 	begin
 	select @errmsg = 'Cannot change Module'
 	goto error
 	end
 
-- DD Audit
if update(Title)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDMO', 'U', 'Module: ' + i.Mod, 'Title',
		d.Title, i.Title, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Mod = d.Mod 
  	where isnull(i.Title,'') <> isnull(d.Title,'')

if update(Active)
	begin
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDMO', 'U', 'Module: ' + i.Mod, 'Active',
		d.Active, i.Active, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Mod = d.Mod 
  	where i.Active <> d.Active

	-- add HQMA audit
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'vDDMO', 'Mod: ' + i.Mod, null, 'C', 'Active', d.Active, i.Active, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.Mod = d.Mod
   	where i.Active <> d.Active
	end

if update(LicLevel)
	begin
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDMO', 'U', 'Module: ' + i.Mod, 'LicLevel',
		convert(varchar,d.LicLevel), convert(varchar,i.LicLevel), getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Mod = d.Mod 
  	where i.LicLevel <> d.LicLevel

	-- add HQMA audit
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'vDDMO', 'Mod: ' + i.Mod, null, 'C', 'LicLevel', 
		convert(varchar,d.LicLevel), convert(varchar,i.LicLevel), getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.Mod = d.Mod
   	where i.LicLevel <> d.LicLevel
	end

 
return

error:
    select @errmsg = @errmsg + ' - cannot update Module!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
 







GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtDDMOu_Audit] ON [dbo].[vDDMO]
 AFTER UPDATE 
 NOT FOR REPLICATION AS 
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 14 2009  9:56AM

 BEGIN TRY 
 IF UPDATE([Mod])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDMO' , '<KeyString Module = "' + REPLACE(CAST(inserted.Mod AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'Mod' ,  CONVERT(VARCHAR(MAX), deleted.[Mod]) ,  Convert(VARCHAR(MAX), inserted.[Mod]) , GETDATE() , HOST_NAME() , 'UPDATE vDDMO SET Mod = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[Mod]), '''' , ''''''), 'NULL') + ''' WHERE Mod = ''' + CAST(inserted.Mod AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Mod] = deleted.[Mod] 
         AND ISNULL(inserted.[Mod],'') <> ISNULL(deleted.[Mod],'')

 IF UPDATE([Title])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDMO' , '<KeyString Module = "' + REPLACE(CAST(inserted.Mod AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'Title' ,  CONVERT(VARCHAR(MAX), deleted.[Title]) ,  Convert(VARCHAR(MAX), inserted.[Title]) , GETDATE() , HOST_NAME() , 'UPDATE vDDMO SET Title = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[Title]), '''' , ''''''), 'NULL') + ''' WHERE Mod = ''' + CAST(inserted.Mod AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Mod] = deleted.[Mod] 
         AND ISNULL(inserted.[Title],'') <> ISNULL(deleted.[Title],'')

 IF UPDATE([Active])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDMO' , '<KeyString Module = "' + REPLACE(CAST(inserted.Mod AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'Active' ,  CONVERT(VARCHAR(MAX), deleted.[Active]) ,  Convert(VARCHAR(MAX), inserted.[Active]) , GETDATE() , HOST_NAME() , 'UPDATE vDDMO SET Active = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[Active]), '''' , ''''''), 'NULL') + ''' WHERE Mod = ''' + CAST(inserted.Mod AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Mod] = deleted.[Mod] 
         AND ISNULL(inserted.[Active],'') <> ISNULL(deleted.[Active],'')

 IF UPDATE([LicLevel])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDMO' , '<KeyString Module = "' + REPLACE(CAST(inserted.Mod AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'LicLevel' ,  CONVERT(VARCHAR(MAX), deleted.[LicLevel]) ,  Convert(VARCHAR(MAX), inserted.[LicLevel]) , GETDATE() , HOST_NAME() , 'UPDATE vDDMO SET LicLevel = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[LicLevel]), '''' , ''''''), 'NULL') + ''' WHERE Mod = ''' + CAST(inserted.Mod AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Mod] = deleted.[Mod] 
         AND ISNULL(inserted.[LicLevel],'') <> ISNULL(deleted.[LicLevel],'')

 END TRY 
 BEGIN CATCH 
   RAISERROR('Error in [dbo].[dbo.vtDDMOi_Audit] trigger', 16, 1 ) with log
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtDDMOu_Audit]', 'last', 'update', null
GO
CREATE UNIQUE CLUSTERED INDEX [viDDMO] ON [dbo].[vDDMO] ([Mod]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[vDDMO].[Active]'
GO
