CREATE TABLE [dbo].[vDMAttachmentTypes]
(
[AttachmentTypeID] [int] NOT NULL IDENTITY(1, 1),
[TextID] [int] NOT NULL,
[Description] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[Active] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vDMAttachmentTypes_Active] DEFAULT ('Y')
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		JonathanP
-- Create date: 04/14/08	
-- Description:	Rejects any deletion attempts. In order to delete a standard type,
-- this trigger must be disabled. We need to be very careful when deleted standard types
-- since they might be in use by customers.
-- =============================================
CREATE TRIGGER [dbo].[vtDMAttachmentTypesd]
   ON  [dbo].[vDMAttachmentTypes]
   FOR DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	-- Standard attachment types can only be deleted if this trigger is disabled. This
	-- is to enforce the fact that we should not delete standard types since customers
	-- may be using them.  
	declare @errorMessage varchar(255)
	select @errorMessage = 'Cannot delete standard attachment types.'
	
	RAISERROR(@errorMessage, 11, -1);
	rollback transaction   

END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtDMAttachmentTypesd_Audit] ON [dbo].[vDMAttachmentTypes]
 AFTER DELETE
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 14 2009  9:56AM

 BEGIN TRY 
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDMAttachmentTypes' , '<KeyString TextID = "' + REPLACE(CAST(deleted.TextID AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'D' , NULL , NULL , NULL , GETDATE() , HOST_NAME() , 'DELETE FROM vDMAttachmentTypes WHERE TextID = ''' + CAST(deleted.TextID AS VARCHAR(MAX)) + ''''
	FROM deleted
 END TRY 
 BEGIN CATCH 
   RAISERROR('Error in [dbo].[dbo.vtDMAttachmentTypesi_Audit] trigger', 16, 1 ) with log
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtDMAttachmentTypesd_Audit]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtDMAttachmentTypesi_Audit] ON [dbo].[vDMAttachmentTypes]
 AFTER INSERT
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 14 2009  9:56AM

 BEGIN TRY 
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDMAttachmentTypes' , '<KeyString TextID = "' + REPLACE(CAST(inserted.TextID AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'A' , NULL , NULL , NULL , GETDATE() , HOST_NAME() , 'INSERT INTO dbo.[vDMAttachmentTypes] ([TextID], [Description], [Active]) VALUES (' + ISNULL(CAST(TextID AS NVARCHAR(MAX)), 'NULL') +  ',' + ISNULL('''' + REPLACE(CAST(Description AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL('''' + REPLACE(CAST(Active AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL')  + ')'
	FROM inserted
 END TRY 
 BEGIN CATCH 
   RAISERROR('Error in [dbo].[dbo.vtDMAttachmentTypesi_Audit] trigger', 16, 1 ) with log
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtDMAttachmentTypesi_Audit]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtDMAttachmentTypesu_Audit] ON [dbo].[vDMAttachmentTypes]
 AFTER UPDATE 
 NOT FOR REPLICATION AS 
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 14 2009  9:56AM

 BEGIN TRY 
 IF UPDATE([AttachmentTypeID])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDMAttachmentTypes' , '<KeyString TextID = "' + REPLACE(CAST(inserted.TextID AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'AttachmentTypeID' ,  CONVERT(VARCHAR(MAX), deleted.[AttachmentTypeID]) ,  Convert(VARCHAR(MAX), inserted.[AttachmentTypeID]) , GETDATE() , HOST_NAME() , 'UPDATE vDMAttachmentTypes SET AttachmentTypeID = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[AttachmentTypeID]), '''' , ''''''), 'NULL') + ''' WHERE TextID = ''' + CAST(inserted.TextID AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[TextID] = deleted.[TextID] 
         AND ISNULL(inserted.[AttachmentTypeID],'') <> ISNULL(deleted.[AttachmentTypeID],'')

 IF UPDATE([TextID])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDMAttachmentTypes' , '<KeyString TextID = "' + REPLACE(CAST(inserted.TextID AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'TextID' ,  CONVERT(VARCHAR(MAX), deleted.[TextID]) ,  Convert(VARCHAR(MAX), inserted.[TextID]) , GETDATE() , HOST_NAME() , 'UPDATE vDMAttachmentTypes SET TextID = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[TextID]), '''' , ''''''), 'NULL') + ''' WHERE TextID = ''' + CAST(inserted.TextID AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[TextID] = deleted.[TextID] 
         AND ISNULL(inserted.[TextID],'') <> ISNULL(deleted.[TextID],'')

 IF UPDATE([Description])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDMAttachmentTypes' , '<KeyString TextID = "' + REPLACE(CAST(inserted.TextID AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'Description' ,  CONVERT(VARCHAR(MAX), deleted.[Description]) ,  Convert(VARCHAR(MAX), inserted.[Description]) , GETDATE() , HOST_NAME() , 'UPDATE vDMAttachmentTypes SET Description = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[Description]), '''' , ''''''), 'NULL') + ''' WHERE TextID = ''' + CAST(inserted.TextID AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[TextID] = deleted.[TextID] 
         AND ISNULL(inserted.[Description],'') <> ISNULL(deleted.[Description],'')

 IF UPDATE([Active])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDMAttachmentTypes' , '<KeyString TextID = "' + REPLACE(CAST(inserted.TextID AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'Active' ,  CONVERT(VARCHAR(MAX), deleted.[Active]) ,  Convert(VARCHAR(MAX), inserted.[Active]) , GETDATE() , HOST_NAME() , 'UPDATE vDMAttachmentTypes SET Active = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[Active]), '''' , ''''''), 'NULL') + ''' WHERE TextID = ''' + CAST(inserted.TextID AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[TextID] = deleted.[TextID] 
         AND ISNULL(inserted.[Active],'') <> ISNULL(deleted.[Active],'')

 END TRY 
 BEGIN CATCH 
   RAISERROR('Error in [dbo].[dbo.vtDMAttachmentTypesi_Audit] trigger', 16, 1 ) with log
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtDMAttachmentTypesu_Audit]', 'last', 'update', null
GO
ALTER TABLE [dbo].[vDMAttachmentTypes] ADD CONSTRAINT [PK_vDMAttachmentTypes] PRIMARY KEY CLUSTERED  ([AttachmentTypeID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vDMAttachmentTypes] WITH NOCHECK ADD CONSTRAINT [FK_vDMAttachmentTypes_TextID] FOREIGN KEY ([TextID]) REFERENCES [dbo].[vDDTM] ([TextID])
GO