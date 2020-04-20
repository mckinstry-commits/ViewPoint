CREATE TABLE [dbo].[vDDLH]
(
[Lookup] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Title] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[FromClause] [varchar] (256) COLLATE Latin1_General_BIN NULL,
[WhereClause] [varchar] (512) COLLATE Latin1_General_BIN NULL,
[JoinClause] [varchar] (512) COLLATE Latin1_General_BIN NULL,
[OrderByColumn] [tinyint] NULL,
[Memo] [varchar] (1024) COLLATE Latin1_General_BIN NULL,
[GroupByClause] [varchar] (256) COLLATE Latin1_General_BIN NULL,
[Version] [tinyint] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE  trigger [dbo].[vtDDLHd] on [dbo].[vDDLH] for DELETE as


/*-----------------------------------------------------------------
* CREATED: MJ 4/12/05
* MODIFIED: 
*
* This trigger rejects delete in vDDLH (Lookup Header) if
* the following error condition exists:
*
*	Lookup Detail entries exist
*	Lookup being used on a field
*   Lookup being used in a datatype
*
* Posts deleted records to vDDDA
*/----------------------------------------------------------------
declare @errmsg varchar(255)
 
if @@rowcount = 0 return
set nocount on

/* check DD Lookup Detail */
if exists (select top 1 1 from deleted d join dbo.vDDLD l with (nolock) on l.Lookup = d.Lookup)
	begin
	select @errmsg = 'Lookup Detail entries exist (vDDLD)'
	goto error
	end

/* Check for use in DDFL */
if exists (select top 1 1 from deleted d join dbo.vDDFL l with (nolock) on l.Lookup = d.Lookup)
	begin
	select @errmsg = 'Lookup being used on one or more form inputs (vDDFL)'
	goto error
	end

/* Check for use in DDDT */  --added on 4/12/05 for issue number 28378
if exists (select top 1 1 from deleted d join dbo.vDDDT t with (nolock) on t.Lookup = d.Lookup)
	begin
	select @errmsg = 'Lookup being used on one or more Datatypes (vDDDT)'
	goto error
	end
 

-- DD Audit
insert dbo.vDDDA (TableName, Action, KeyString, FieldName, OldValue, NewValue,
	RevDate, UserName, HostName)
select 'vDDLH', 'D', 'Lookup: ' + rtrim(Lookup), null, null, null,
	getdate(), SUSER_SNAME(), host_name()
from deleted
 
return
 
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot delete Lookup Header!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
 
 
 
 
 
 
 
 







GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtDDLHd_Audit] ON [dbo].[vDDLH]
 AFTER DELETE
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 14 2009  9:56AM

 BEGIN TRY 
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDLH' , '<KeyString Lookup = "' + REPLACE(CAST(deleted.Lookup AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'D' , NULL , NULL , NULL , GETDATE() , HOST_NAME() , 'DELETE FROM vDDLH WHERE Lookup = ''' + CAST(deleted.Lookup AS VARCHAR(MAX)) + ''''
	FROM deleted
 END TRY 
 BEGIN CATCH 
   RAISERROR('Error in [dbo].[dbo.vtDDLHi_Audit] trigger', 16, 1 ) with log
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtDDLHd_Audit]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE  trigger [dbo].[vtDDLHi] on [dbo].[vDDLH] for INSERT
/*****************************
* Created: GG 06/10/05
* Modified:
*
* Insert trigger on vDDLH (DD Lookup Header)
*
* Rejects insert if the following conditions exist:
*	Invalid Version
*
* Adds DD Audit entry
*
*************************************/

as


declare @errmsg varchar(255), @numrows int, @validcnt int
  
select @numrows = @@rowcount
if @numrows = 0 return

set nocount on

-- validate Version
if exists(select top 1 1 from inserted where Version not in (5,6))
	begin
	select @errmsg = 'Invalid Version - must be 5 or 6.'
	goto error
	end

  
-- DD Audit  
insert vDDDA (TableName, Action, KeyString, FieldName, OldValue, 
  	NewValue, RevDate, UserName, HostName)
select 'vDDLH', 'I', 'Lookup: ' + rtrim(Lookup), null, null,
	null, getdate(), SUSER_SNAME(), host_name()
from inserted 
  	 	 	 
return

error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot insert Lookup Header!'
  	RAISERROR(@errmsg, 11, -1);
  	rollback transaction
  
    







GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtDDLHi_Audit] ON [dbo].[vDDLH]
 AFTER INSERT
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 14 2009  9:56AM

 BEGIN TRY 
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDLH' , '<KeyString Lookup = "' + REPLACE(CAST(inserted.Lookup AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'A' , NULL , NULL , NULL , GETDATE() , HOST_NAME() , 'INSERT INTO dbo.[vDDLH] ([Lookup], [Title], [FromClause], [WhereClause], [JoinClause], [OrderByColumn], [Memo], [GroupByClause], [Version]) VALUES (' + ISNULL('''' + REPLACE(CAST(Lookup AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL('''' + REPLACE(CAST(Title AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL('''' + REPLACE(CAST(FromClause AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL('''' + REPLACE(CAST(WhereClause AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL('''' + REPLACE(CAST(JoinClause AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL(CAST(OrderByColumn AS NVARCHAR(MAX)), 'NULL') +  ',' + ISNULL('''' + REPLACE(CAST(Memo AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL('''' + REPLACE(CAST(GroupByClause AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL(CAST(Version AS NVARCHAR(MAX)), 'NULL') + + ')'
	FROM inserted
 END TRY 
 BEGIN CATCH 
   RAISERROR('Error in [dbo].[dbo.vtDDLHi_Audit] trigger', 16, 1 ) with log
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtDDLHi_Audit]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



create trigger [dbo].[vtDDLHu] on [dbo].[vDDLH] for UPDATE
/************************************
* Created: GG 06/10/05
* Modified: 
*
* Update trigger on vDDLH (DD Lookup Header)
*
* Rejects update if any of the following conditions exist:
*	Change Lookup name
*	Invalid Version
*
* Adds DD Audit entries for changed values
*
************************************/

as


declare @errmsg varchar(255), @numrows int, @validcnt int 
  
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on
  
-- check for key changes 
if update(Lookup)
	begin
	select @validcnt = count(*) from inserted i join deleted d	on i.Lookup = d.Lookup
	if @validcnt <> @numrows
		begin
  		select @errmsg = 'Cannot change Form name'
  		goto error
  		end
	end

if update(Version)
	begin
	if exists(select top 1 1 from inserted where Version not in (5,6))
		begin
  		select @errmsg = 'Invalid Version, must be 5 or 6'
  		goto error
  		end
	end

  	
-- DD Audit
if update(Title)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDLH', 'U', 'Lookup: ' + rtrim(i.Lookup), 'Title',
		d.Title, i.Title, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Lookup = d.Lookup 
  	where isnull(i.Title,'') <> isnull(d.Title,'')

if update(FromClause)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDLH', 'U', 'Lookup: ' + rtrim(i.Lookup), 'FromClause',
		d.FromClause, i.FromClause, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Lookup = d.Lookup 
  	where isnull(i.FromClause,'') <> isnull(d.FromClause,'')

if update(WhereClause)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDLH', 'U', 'Lookup: ' + rtrim(i.Lookup), 'WhereClause',
		d.WhereClause, i.WhereClause, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Lookup = d.Lookup 
  	where isnull(i.WhereClause,'') <> isnull(d.WhereClause,'')

if update(JoinClause)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDLH', 'U', 'Lookup: ' + rtrim(i.Lookup), 'JoinClause',
		d.JoinClause, i.JoinClause, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Lookup = d.Lookup 
  	where isnull(i.JoinClause,'') <> isnull(d.JoinClause,'')

if update(OrderByColumn)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDLH', 'U', 'Lookup: ' + rtrim(i.Lookup), 'OrderByColumn',
		convert(varchar,d.OrderByColumn), convert(varchar,i.OrderByColumn), getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Lookup = d.Lookup 
  	where isnull(i.OrderByColumn,255) <> isnull(d.OrderByColumn,255)

if update(Memo)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDLH', 'U', 'Lookup: ' + rtrim(i.Lookup), 'Memo',
		d.Memo, i.Memo, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Lookup = d.Lookup 
  	where isnull(i.Memo,'') <> isnull(d.Memo,'')

if update(GroupByClause)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDLH', 'U', 'Lookup: ' + rtrim(i.Lookup), 'GroupByClause',
		d.GroupByClause, i.GroupByClause, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Lookup = d.Lookup 
  	where isnull(i.GroupByClause,'') <> isnull(d.GroupByClause,'')

if update(Version)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDLH', 'U', 'Lookup: ' + rtrim(i.Lookup), 'Version',
		convert(varchar,d.Version), convert(varchar,i.Version), getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Lookup = d.Lookup 
  	where i.Version <> d.Version

return
  
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot update Lookup Header!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
  
  
  
  
 





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtDDLHu_Audit] ON [dbo].[vDDLH]
 AFTER UPDATE 
 NOT FOR REPLICATION AS 
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 14 2009  9:56AM

 BEGIN TRY 
 IF UPDATE([Lookup])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDLH' , '<KeyString Lookup = "' + REPLACE(CAST(inserted.Lookup AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'Lookup' ,  CONVERT(VARCHAR(MAX), deleted.[Lookup]) ,  Convert(VARCHAR(MAX), inserted.[Lookup]) , GETDATE() , HOST_NAME() , 'UPDATE vDDLH SET Lookup = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[Lookup]), '''' , ''''''), 'NULL') + ''' WHERE Lookup = ''' + CAST(inserted.Lookup AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Lookup] = deleted.[Lookup] 
         AND ISNULL(inserted.[Lookup],'') <> ISNULL(deleted.[Lookup],'')

 IF UPDATE([Title])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDLH' , '<KeyString Lookup = "' + REPLACE(CAST(inserted.Lookup AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'Title' ,  CONVERT(VARCHAR(MAX), deleted.[Title]) ,  Convert(VARCHAR(MAX), inserted.[Title]) , GETDATE() , HOST_NAME() , 'UPDATE vDDLH SET Title = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[Title]), '''' , ''''''), 'NULL') + ''' WHERE Lookup = ''' + CAST(inserted.Lookup AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Lookup] = deleted.[Lookup] 
         AND ISNULL(inserted.[Title],'') <> ISNULL(deleted.[Title],'')

 IF UPDATE([FromClause])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDLH' , '<KeyString Lookup = "' + REPLACE(CAST(inserted.Lookup AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'FromClause' ,  CONVERT(VARCHAR(MAX), deleted.[FromClause]) ,  Convert(VARCHAR(MAX), inserted.[FromClause]) , GETDATE() , HOST_NAME() , 'UPDATE vDDLH SET FromClause = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[FromClause]), '''' , ''''''), 'NULL') + ''' WHERE Lookup = ''' + CAST(inserted.Lookup AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Lookup] = deleted.[Lookup] 
         AND ISNULL(inserted.[FromClause],'') <> ISNULL(deleted.[FromClause],'')

 IF UPDATE([WhereClause])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDLH' , '<KeyString Lookup = "' + REPLACE(CAST(inserted.Lookup AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'WhereClause' ,  CONVERT(VARCHAR(MAX), deleted.[WhereClause]) ,  Convert(VARCHAR(MAX), inserted.[WhereClause]) , GETDATE() , HOST_NAME() , 'UPDATE vDDLH SET WhereClause = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[WhereClause]), '''' , ''''''), 'NULL') + ''' WHERE Lookup = ''' + CAST(inserted.Lookup AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Lookup] = deleted.[Lookup] 
         AND ISNULL(inserted.[WhereClause],'') <> ISNULL(deleted.[WhereClause],'')

 IF UPDATE([JoinClause])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDLH' , '<KeyString Lookup = "' + REPLACE(CAST(inserted.Lookup AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'JoinClause' ,  CONVERT(VARCHAR(MAX), deleted.[JoinClause]) ,  Convert(VARCHAR(MAX), inserted.[JoinClause]) , GETDATE() , HOST_NAME() , 'UPDATE vDDLH SET JoinClause = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[JoinClause]), '''' , ''''''), 'NULL') + ''' WHERE Lookup = ''' + CAST(inserted.Lookup AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Lookup] = deleted.[Lookup] 
         AND ISNULL(inserted.[JoinClause],'') <> ISNULL(deleted.[JoinClause],'')

 IF UPDATE([OrderByColumn])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDLH' , '<KeyString Lookup = "' + REPLACE(CAST(inserted.Lookup AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'OrderByColumn' ,  CONVERT(VARCHAR(MAX), deleted.[OrderByColumn]) ,  Convert(VARCHAR(MAX), inserted.[OrderByColumn]) , GETDATE() , HOST_NAME() , 'UPDATE vDDLH SET OrderByColumn = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[OrderByColumn]), '''' , ''''''), 'NULL') + ''' WHERE Lookup = ''' + CAST(inserted.Lookup AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Lookup] = deleted.[Lookup] 
         AND ISNULL(inserted.[OrderByColumn],'') <> ISNULL(deleted.[OrderByColumn],'')

 IF UPDATE([Memo])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDLH' , '<KeyString Lookup = "' + REPLACE(CAST(inserted.Lookup AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'Memo' ,  CONVERT(VARCHAR(MAX), deleted.[Memo]) ,  Convert(VARCHAR(MAX), inserted.[Memo]) , GETDATE() , HOST_NAME() , 'UPDATE vDDLH SET Memo = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[Memo]), '''' , ''''''), 'NULL') + ''' WHERE Lookup = ''' + CAST(inserted.Lookup AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Lookup] = deleted.[Lookup] 
         AND ISNULL(inserted.[Memo],'') <> ISNULL(deleted.[Memo],'')

 IF UPDATE([GroupByClause])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDLH' , '<KeyString Lookup = "' + REPLACE(CAST(inserted.Lookup AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'GroupByClause' ,  CONVERT(VARCHAR(MAX), deleted.[GroupByClause]) ,  Convert(VARCHAR(MAX), inserted.[GroupByClause]) , GETDATE() , HOST_NAME() , 'UPDATE vDDLH SET GroupByClause = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[GroupByClause]), '''' , ''''''), 'NULL') + ''' WHERE Lookup = ''' + CAST(inserted.Lookup AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Lookup] = deleted.[Lookup] 
         AND ISNULL(inserted.[GroupByClause],'') <> ISNULL(deleted.[GroupByClause],'')

 IF UPDATE([Version])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDLH' , '<KeyString Lookup = "' + REPLACE(CAST(inserted.Lookup AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'Version' ,  CONVERT(VARCHAR(MAX), deleted.[Version]) ,  Convert(VARCHAR(MAX), inserted.[Version]) , GETDATE() , HOST_NAME() , 'UPDATE vDDLH SET Version = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[Version]), '''' , ''''''), 'NULL') + ''' WHERE Lookup = ''' + CAST(inserted.Lookup AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Lookup] = deleted.[Lookup] 
         AND ISNULL(inserted.[Version],'') <> ISNULL(deleted.[Version],'')

 END TRY 
 BEGIN CATCH 
   RAISERROR('Error in [dbo].[dbo.vtDDLHi_Audit] trigger', 16, 1 ) with log
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtDDLHu_Audit]', 'last', 'update', null
GO
CREATE UNIQUE CLUSTERED INDEX [viDDLH] ON [dbo].[vDDLH] ([Lookup]) ON [PRIMARY]
GO
