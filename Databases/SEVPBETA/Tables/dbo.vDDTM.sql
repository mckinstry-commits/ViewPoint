CREATE TABLE [dbo].[vDDTM]
(
[TextID] [int] NOT NULL,
[CultureText] [varchar] (250) COLLATE Latin1_General_BIN NOT NULL,
[TextType] [int] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtDDTMd_Audit] ON [dbo].[vDDTM]
 AFTER DELETE
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 14 2009  9:56AM

 BEGIN TRY 
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDTM' , '<KeyString TextID = "' + REPLACE(CAST(deleted.TextID AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'D' , NULL , NULL , NULL , GETDATE() , HOST_NAME() , 'DELETE FROM vDDTM WHERE TextID = ''' + CAST(deleted.TextID AS VARCHAR(MAX)) + ''''
	FROM deleted
 END TRY 
 BEGIN CATCH 
   RAISERROR('Error in [dbo].[dbo.vtDDTMi_Audit] trigger', 16, 1 ) with log
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtDDTMd_Audit]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtDDTMi_Audit] ON [dbo].[vDDTM]
 AFTER INSERT
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 14 2009  9:56AM

 BEGIN TRY 
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDTM' , '<KeyString TextID = "' + REPLACE(CAST(inserted.TextID AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'A' , NULL , NULL , NULL , GETDATE() , HOST_NAME() , 'INSERT INTO dbo.[vDDTM] ([TextID], [CultureText], [TextType]) VALUES (' + ISNULL(CAST(TextID AS NVARCHAR(MAX)), 'NULL') +  ',' + ISNULL('''' + REPLACE(CAST(CultureText AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL(CAST(TextType AS NVARCHAR(MAX)), 'NULL') + + ')'
	FROM inserted
 END TRY 
 BEGIN CATCH 
   RAISERROR('Error in [dbo].[dbo.vtDDTMi_Audit] trigger', 16, 1 ) with log
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtDDTMi_Audit]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtDDTMu_Audit] ON [dbo].[vDDTM]
 AFTER UPDATE 
 NOT FOR REPLICATION AS 
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 14 2009  9:56AM

 BEGIN TRY 
 IF UPDATE([TextID])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDTM' , '<KeyString TextID = "' + REPLACE(CAST(inserted.TextID AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'TextID' ,  CONVERT(VARCHAR(MAX), deleted.[TextID]) ,  Convert(VARCHAR(MAX), inserted.[TextID]) , GETDATE() , HOST_NAME() , 'UPDATE vDDTM SET TextID = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[TextID]), '''' , ''''''), 'NULL') + ''' WHERE TextID = ''' + CAST(inserted.TextID AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[TextID] = deleted.[TextID] 
         AND ISNULL(inserted.[TextID],'') <> ISNULL(deleted.[TextID],'')

 IF UPDATE([CultureText])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDTM' , '<KeyString TextID = "' + REPLACE(CAST(inserted.TextID AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'CultureText' ,  CONVERT(VARCHAR(MAX), deleted.[CultureText]) ,  Convert(VARCHAR(MAX), inserted.[CultureText]) , GETDATE() , HOST_NAME() , 'UPDATE vDDTM SET CultureText = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[CultureText]), '''' , ''''''), 'NULL') + ''' WHERE TextID = ''' + CAST(inserted.TextID AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[TextID] = deleted.[TextID] 
         AND ISNULL(inserted.[CultureText],'') <> ISNULL(deleted.[CultureText],'')

 IF UPDATE([TextType])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDTM' , '<KeyString TextID = "' + REPLACE(CAST(inserted.TextID AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'TextType' ,  CONVERT(VARCHAR(MAX), deleted.[TextType]) ,  Convert(VARCHAR(MAX), inserted.[TextType]) , GETDATE() , HOST_NAME() , 'UPDATE vDDTM SET TextType = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[TextType]), '''' , ''''''), 'NULL') + ''' WHERE TextID = ''' + CAST(inserted.TextID AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[TextID] = deleted.[TextID] 
         AND ISNULL(inserted.[TextType],'') <> ISNULL(deleted.[TextType],'')

 END TRY 
 BEGIN CATCH 
   RAISERROR('Error in [dbo].[dbo.vtDDTMi_Audit] trigger', 16, 1 ) with log
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtDDTMu_Audit]', 'last', 'update', null
GO
ALTER TABLE [dbo].[vDDTM] ADD CONSTRAINT [PK_vDDTM] PRIMARY KEY NONCLUSTERED  ([TextID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vDDTM_TextID_TextType] ON [dbo].[vDDTM] ([TextID], [TextType]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
