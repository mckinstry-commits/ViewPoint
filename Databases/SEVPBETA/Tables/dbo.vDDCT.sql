CREATE TABLE [dbo].[vDDCT]
(
[CultureID] [int] NOT NULL,
[TextID] [int] NOT NULL,
[CultureText] [varchar] (250) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtDDCTd_Audit] ON [dbo].[vDDCT]
 AFTER DELETE
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 14 2009  9:56AM

 BEGIN TRY 
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDCT' , '<KeyString CultureID = "' + REPLACE(CAST(deleted.CultureID AS VARCHAR(MAX)),'"', '&quot;') + '" TextID = "' + REPLACE(CAST(deleted.TextID AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'D' , NULL , NULL , NULL , GETDATE() , HOST_NAME() , 'DELETE FROM vDDCT WHERE CultureID = ''' + CAST(deleted.CultureID AS VARCHAR(MAX)) + '''' + ' AND TextID = ''' + CAST(deleted.TextID AS VARCHAR(MAX)) + ''''
	FROM deleted
 END TRY 
 BEGIN CATCH 
   RAISERROR('Error in [dbo].[dbo.vtDDCTi_Audit] trigger', 16, 1 ) with log
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtDDCTd_Audit]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtDDCTi_Audit] ON [dbo].[vDDCT]
 AFTER INSERT
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 14 2009  9:56AM

 BEGIN TRY 
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDCT' , '<KeyString CultureID = "' + REPLACE(CAST(inserted.CultureID AS VARCHAR(MAX)),'"', '&quot;') + '" TextID = "' + REPLACE(CAST(inserted.TextID AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'A' , NULL , NULL , NULL , GETDATE() , HOST_NAME() , 'INSERT INTO dbo.[vDDCT] ([CultureID], [TextID], [CultureText]) VALUES (' + ISNULL(CAST(CultureID AS NVARCHAR(MAX)), 'NULL') +  ',' + ISNULL(CAST(TextID AS NVARCHAR(MAX)), 'NULL') +  ',' + ISNULL('''' + REPLACE(CAST(CultureText AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL')  + ')'
	FROM inserted
 END TRY 
 BEGIN CATCH 
   RAISERROR('Error in [dbo].[dbo.vtDDCTi_Audit] trigger', 16, 1 ) with log
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtDDCTi_Audit]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtDDCTu_Audit] ON [dbo].[vDDCT]
 AFTER UPDATE 
 NOT FOR REPLICATION AS 
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 14 2009  9:56AM

 BEGIN TRY 
 IF UPDATE([CultureID])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDCT' , '<KeyString CultureID = "' + REPLACE(CAST(inserted.CultureID AS VARCHAR(MAX)),'"', '&quot;') + '" TextID = "' + REPLACE(CAST(inserted.TextID AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'CultureID' ,  CONVERT(VARCHAR(MAX), deleted.[CultureID]) ,  Convert(VARCHAR(MAX), inserted.[CultureID]) , GETDATE() , HOST_NAME() , 'UPDATE vDDCT SET CultureID = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[CultureID]), '''' , ''''''), 'NULL') + ''' WHERE CultureID = ''' + CAST(inserted.CultureID AS VARCHAR(MAX)) + '''' + ' AND TextID = ''' + CAST(inserted.TextID AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[CultureID] = deleted.[CultureID]  AND  inserted.[TextID] = deleted.[TextID] 
         AND ISNULL(inserted.[CultureID],'') <> ISNULL(deleted.[CultureID],'')

 IF UPDATE([TextID])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDCT' , '<KeyString CultureID = "' + REPLACE(CAST(inserted.CultureID AS VARCHAR(MAX)),'"', '&quot;') + '" TextID = "' + REPLACE(CAST(inserted.TextID AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'TextID' ,  CONVERT(VARCHAR(MAX), deleted.[TextID]) ,  Convert(VARCHAR(MAX), inserted.[TextID]) , GETDATE() , HOST_NAME() , 'UPDATE vDDCT SET TextID = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[TextID]), '''' , ''''''), 'NULL') + ''' WHERE CultureID = ''' + CAST(inserted.CultureID AS VARCHAR(MAX)) + '''' + ' AND TextID = ''' + CAST(inserted.TextID AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[CultureID] = deleted.[CultureID]  AND  inserted.[TextID] = deleted.[TextID] 
         AND ISNULL(inserted.[TextID],'') <> ISNULL(deleted.[TextID],'')

 IF UPDATE([CultureText])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDCT' , '<KeyString CultureID = "' + REPLACE(CAST(inserted.CultureID AS VARCHAR(MAX)),'"', '&quot;') + '" TextID = "' + REPLACE(CAST(inserted.TextID AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'CultureText' ,  CONVERT(VARCHAR(MAX), deleted.[CultureText]) ,  Convert(VARCHAR(MAX), inserted.[CultureText]) , GETDATE() , HOST_NAME() , 'UPDATE vDDCT SET CultureText = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[CultureText]), '''' , ''''''), 'NULL') + ''' WHERE CultureID = ''' + CAST(inserted.CultureID AS VARCHAR(MAX)) + '''' + ' AND TextID = ''' + CAST(inserted.TextID AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[CultureID] = deleted.[CultureID]  AND  inserted.[TextID] = deleted.[TextID] 
         AND ISNULL(inserted.[CultureText],'') <> ISNULL(deleted.[CultureText],'')

 END TRY 
 BEGIN CATCH 
   RAISERROR('Error in [dbo].[dbo.vtDDCTi_Audit] trigger', 16, 1 ) with log
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtDDCTu_Audit]', 'last', 'update', null
GO
ALTER TABLE [dbo].[vDDCT] ADD CONSTRAINT [PK_vDDCT] PRIMARY KEY CLUSTERED  ([CultureID], [TextID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vDDCT] WITH NOCHECK ADD CONSTRAINT [FK_vDDCT_vDDCL] FOREIGN KEY ([CultureID]) REFERENCES [dbo].[vDDCL] ([KeyID])
GO
ALTER TABLE [dbo].[vDDCT] WITH NOCHECK ADD CONSTRAINT [FK_vDDCT_vDDTT] FOREIGN KEY ([TextID]) REFERENCES [dbo].[vDDTM] ([TextID])
GO
