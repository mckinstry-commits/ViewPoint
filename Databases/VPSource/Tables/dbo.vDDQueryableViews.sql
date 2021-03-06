CREATE TABLE [dbo].[vDDQueryableViews]
(
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Title] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[QueryView] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[AllowAttachments] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vDDQueryableViews_AllowAttachments] DEFAULT ('Y'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[AttachmentCompanyColumn] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[AttachmentFormName] [varchar] (30) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



create   trigger [dbo].[vtDDQueryableViewsd] on [dbo].[vDDQueryableViews] for DELETE
/************************************
* Created: JonathanP 08/21/2008 - adapted from delete trigger on vDDFH
* Modified: 
*
* Delete trigger on vDDQueryableViews
*
* Rejects deletion based on various criteria.
*
* Adds DD Audit entry
*
************************************/
as

declare @errorMessage varchar(255)
  
if @@rowcount = 0 return
set nocount on
  
-- check Form Inputs 
if exists (select top 1 1 from deleted d join dbo.DDQueryableColumns i (nolock) on i.Form = d.Form)
  	begin
  	select @errorMessage = 'DD Queryable Columns entries exist'
  	goto error
  	end
  	
-- DD Audit 
insert dbo.vDDDA (TableName, Action, KeyString, FieldName,
	OldValue, NewValue, RevDate, UserName, HostName)
select 'vDDQueryableViews', 'D', 'Form: ' + rtrim(Form), null,
	null, null, getdate(), SUSER_SNAME(), host_name()
from deleted
  
return
  
error:
	select @errorMessage = isnull(@errorMessage,'') + ' - cannot delete DD Queryable Form Header!'
    RAISERROR(@errorMessage, 11, -1);
    rollback transaction
  
  
  
  
 







GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtDDQueryableViewsd_Audit] ON [dbo].[vDDQueryableViews]
 AFTER DELETE
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 14 2009  9:56AM

 BEGIN TRY 
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDQueryableViews' , '<KeyString Form = "' + REPLACE(CAST(deleted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'D' , NULL , NULL , NULL , GETDATE() , HOST_NAME() , 'DELETE FROM vDDQueryableViews WHERE Form = ''' + CAST(deleted.Form AS VARCHAR(MAX)) + ''''
	FROM deleted
 END TRY 
 BEGIN CATCH 
   RAISERROR('Error in [dbo].[dbo.vtDDQueryableViewsi_Audit] trigger', 16, 1 ) with log
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtDDQueryableViewsd_Audit]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[vtDDQueryableViewsi] on [dbo].[vDDQueryableViews] for INSERT
/*****************************
* Created: JonathanP 08/21/2008
* Modified: CG 12/09/2010 - Issue #140507 - Changed to no longer require column named "KeyID" to indicate identity column
*
* Insert trigger on vDDFH (DD Form Header)
*
* Rejects insert if the inserted record does not meet certain criteria.
*
* Adds DD Audit entry
*
*************************************/

as

declare @errorMessage varchar(255), @numberOfRows int, @validCount int
  
select @numberOfRows = @@rowcount
if @numberOfRows = 0 return

set nocount on

-- Check if the Form name already exists.
if exists(select top 1 1 from DDFHShared f join inserted i on f.Form = i.Form)
begin
	begin
  	select @errorMessage = 'Form name already exists in DDFHShared. Please choose a different name.'
  	goto error
  	end
end

-- Get the identity column of the table
declare @queryView varchar(128)
select @queryView = i.QueryView from inserted i
declare @identityColumn varchar(128)
exec vspDDGetIdentityColumn @queryView, @identityColumn output

-- Make sure the Query View has a Identity column. This is a requirement.
if @identityColumn is null
begin
	select @errorMessage = 'An identity column does not exist for the view(s). Queryable views must have an identity column.'	
    goto error
end
	
-- DD Audit  
insert vDDDA (TableName, Action, KeyString, FieldName, OldValue, 
  	NewValue, RevDate, UserName, HostName)
select 'vDDQueryableViews', 'I', 'Form: ' + rtrim(Form), null, null,
	null, getdate(), SUSER_SNAME(), host_name()
from inserted 
  	 	 	 
return

error:
	select @errorMessage = isnull(@errorMessage,'') + ' - cannot insert DD Queryable Form!'
  	RAISERROR(@errorMessage, 11, -1);
  	rollback transaction






/****** Object:  Trigger [dbo].[vtDDQueryableViewsu]    Script Date: 12/09/2010 10:09:18 ******/
SET ANSI_NULLS ON

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtDDQueryableViewsi_Audit] ON [dbo].[vDDQueryableViews]
 AFTER INSERT
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 14 2009  9:56AM

 BEGIN TRY 
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDQueryableViews' , '<KeyString Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'A' , NULL , NULL , NULL , GETDATE() , HOST_NAME() , 'INSERT INTO dbo.[vDDQueryableViews] ([Form], [Title], [QueryView], [AllowAttachments], [AttachmentCompanyColumn]) VALUES (' + ISNULL('''' + REPLACE(CAST(Form AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL('''' + REPLACE(CAST(Title AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL('''' + REPLACE(CAST(QueryView AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL('''' + REPLACE(CAST(AllowAttachments AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL('''' + REPLACE(CAST(AttachmentCompanyColumn AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL')  + ')'
	FROM inserted
 END TRY 
 BEGIN CATCH 
   RAISERROR('Error in [dbo].[dbo.vtDDQueryableViewsi_Audit] trigger', 16, 1 ) with log
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtDDQueryableViewsi_Audit]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[vtDDQueryableViewsu] on [dbo].[vDDQueryableViews] for UPDATE
/************************************
* Created: JonathanP 08/21/2008 - adapted from the update trigger on vDDFH
* Modified: CG 12/09/2010 - Issue #140507 - Changed to no longer require column named "KeyID" to indicate identity column
*
* Update trigger on vDDQueryableViews
*
* Rejects update based on various criteria.
*
* Adds DD Audit entries for changed values
*
************************************/

as

declare @errorMessage varchar(255), @numberOfRows int, @validCount int 
  
select @numberOfRows = @@rowcount
if @numberOfRows = 0 return
set nocount on

-- check for key changes 
select @validCount = count(*) from inserted i join deleted d on i.Form = d.Form
if @validCount <> @numberOfRows
	begin
  	select @errorMessage = 'Cannot change Form name.'
  	goto error
  	end
  	
-- Get the identity column of the table
declare @queryView varchar(128)
select @queryView = i.QueryView from inserted i
declare @identityColumn varchar(128)
exec vspDDGetIdentityColumn @queryView, @identityColumn output
  	
-- Make sure the Query View has a Identity column. This is a requirement.
if @identityColumn is null
begin
	select @errorMessage = 'An identity column does not exist for the view(s). Queryable views must have an identity column.'	
    goto error
end
  	
-- DD Audit
if update(Title)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDQueryableViews', 'U', 'Form: ' + rtrim(i.Form), 'Title',
		d.Title, i.Title, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Form = d.Form 
  	where isnull(i.Title,'') <> isnull(d.Title,'')

if update(QueryView)
	insert vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select 'vDDQueryableViews', 'U', 'Form: ' + rtrim(i.Form), 'QueryView',
		d.QueryView, i.QueryView, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Form = d.Form
  	where isnull(i.QueryView,'') <> isnull(d.QueryView,'')

if update(AllowAttachments)
	insert vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select 'vDDQueryableViews', 'U', 'Form: ' + rtrim(i.Form), 'AllowAttachments',
		d.AllowAttachments, i.AllowAttachments, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Form = d.Form
  	where i.AllowAttachments <> d.AllowAttachments
	
return
  
error:
	select @errorMessage = isnull(@errorMessage,'') + ' - cannot update DD Queryable Form!'
    RAISERROR(@errorMessage, 11, -1);
    rollback transaction
  
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtDDQueryableViewsu_Audit] ON [dbo].[vDDQueryableViews]
 AFTER UPDATE 
 NOT FOR REPLICATION AS 
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 14 2009  9:56AM

 BEGIN TRY 
 IF UPDATE([Form])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDQueryableViews' , '<KeyString Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'Form' ,  CONVERT(VARCHAR(MAX), deleted.[Form]) ,  Convert(VARCHAR(MAX), inserted.[Form]) , GETDATE() , HOST_NAME() , 'UPDATE vDDQueryableViews SET Form = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[Form]), '''' , ''''''), 'NULL') + ''' WHERE Form = ''' + CAST(inserted.Form AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Form] = deleted.[Form] 
         AND ISNULL(inserted.[Form],'') <> ISNULL(deleted.[Form],'')

 IF UPDATE([Title])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDQueryableViews' , '<KeyString Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'Title' ,  CONVERT(VARCHAR(MAX), deleted.[Title]) ,  Convert(VARCHAR(MAX), inserted.[Title]) , GETDATE() , HOST_NAME() , 'UPDATE vDDQueryableViews SET Title = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[Title]), '''' , ''''''), 'NULL') + ''' WHERE Form = ''' + CAST(inserted.Form AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Form] = deleted.[Form] 
         AND ISNULL(inserted.[Title],'') <> ISNULL(deleted.[Title],'')

 IF UPDATE([QueryView])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDQueryableViews' , '<KeyString Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'QueryView' ,  CONVERT(VARCHAR(MAX), deleted.[QueryView]) ,  Convert(VARCHAR(MAX), inserted.[QueryView]) , GETDATE() , HOST_NAME() , 'UPDATE vDDQueryableViews SET QueryView = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[QueryView]), '''' , ''''''), 'NULL') + ''' WHERE Form = ''' + CAST(inserted.Form AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Form] = deleted.[Form] 
         AND ISNULL(inserted.[QueryView],'') <> ISNULL(deleted.[QueryView],'')

 IF UPDATE([AllowAttachments])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDQueryableViews' , '<KeyString Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'AllowAttachments' ,  CONVERT(VARCHAR(MAX), deleted.[AllowAttachments]) ,  Convert(VARCHAR(MAX), inserted.[AllowAttachments]) , GETDATE() , HOST_NAME() , 'UPDATE vDDQueryableViews SET AllowAttachments = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[AllowAttachments]), '''' , ''''''), 'NULL') + ''' WHERE Form = ''' + CAST(inserted.Form AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Form] = deleted.[Form] 
         AND ISNULL(inserted.[AllowAttachments],'') <> ISNULL(deleted.[AllowAttachments],'')

 IF UPDATE([AttachmentCompanyColumn])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDQueryableViews' , '<KeyString Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'AttachmentCompanyColumn' ,  CONVERT(VARCHAR(MAX), deleted.[AttachmentCompanyColumn]) ,  Convert(VARCHAR(MAX), inserted.[AttachmentCompanyColumn]) , GETDATE() , HOST_NAME() , 'UPDATE vDDQueryableViews SET AttachmentCompanyColumn = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[AttachmentCompanyColumn]), '''' , ''''''), 'NULL') + ''' WHERE Form = ''' + CAST(inserted.Form AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Form] = deleted.[Form] 
         AND ISNULL(inserted.[AttachmentCompanyColumn],'') <> ISNULL(deleted.[AttachmentCompanyColumn],'')

 END TRY 
 BEGIN CATCH 
   RAISERROR('Error in [dbo].[dbo.vtDDQueryableViewsi_Audit] trigger', 16, 1 ) with log
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtDDQueryableViewsu_Audit]', 'last', 'update', null
GO
ALTER TABLE [dbo].[vDDQueryableViews] ADD CONSTRAINT [PK_DDQueryableViews] PRIMARY KEY CLUSTERED  ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_DDQueryableViews] ON [dbo].[vDDQueryableViews] ([Form]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
