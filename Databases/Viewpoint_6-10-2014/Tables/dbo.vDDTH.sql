CREATE TABLE [dbo].[vDDTH]
(
[TableName] [varchar] (256) COLLATE Latin1_General_BIN NOT NULL,
[Description] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[TableType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtDDTHd_Audit] ON [dbo].[vDDTH]
 AFTER DELETE
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 14 2009  9:56AM

 BEGIN TRY 
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDTH' , '<KeyString TableName = "' + REPLACE(CAST(deleted.TableName AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'D' , NULL , NULL , NULL , GETDATE() , HOST_NAME() , 'DELETE FROM vDDTH WHERE TableName = ''' + CAST(deleted.TableName AS VARCHAR(MAX)) + ''''
	FROM deleted
 END TRY 
 BEGIN CATCH 
   RAISERROR('Error in [dbo].[dbo.vtDDTHi_Audit] trigger', 16, 1 ) with log
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtDDTHd_Audit]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtDDTHi_Audit] ON [dbo].[vDDTH]
 AFTER INSERT
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 14 2009  9:56AM

 BEGIN TRY 
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDTH' , '<KeyString TableName = "' + REPLACE(CAST(inserted.TableName AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'A' , NULL , NULL , NULL , GETDATE() , HOST_NAME() , 'INSERT INTO dbo.[vDDTH] ([TableName], [Description], [TableType], [Notes]) VALUES (' + ISNULL('''' + REPLACE(CAST(TableName AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL('''' + REPLACE(CAST(Description AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL('''' + REPLACE(CAST(TableType AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL')  + ')'
	FROM inserted
 END TRY 
 BEGIN CATCH 
   RAISERROR('Error in [dbo].[dbo.vtDDTHi_Audit] trigger', 16, 1 ) with log
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtDDTHi_Audit]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtDDTHu_Audit] ON [dbo].[vDDTH]
 AFTER UPDATE 
 NOT FOR REPLICATION AS 
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 14 2009  9:56AM

 BEGIN TRY 
 IF UPDATE([TableName])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDTH' , '<KeyString TableName = "' + REPLACE(CAST(inserted.TableName AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'TableName' ,  CONVERT(VARCHAR(MAX), deleted.[TableName]) ,  Convert(VARCHAR(MAX), inserted.[TableName]) , GETDATE() , HOST_NAME() , 'UPDATE vDDTH SET TableName = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[TableName]), '''' , ''''''), 'NULL') + ''' WHERE TableName = ''' + CAST(inserted.TableName AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[TableName] = deleted.[TableName] 
         AND ISNULL(inserted.[TableName],'') <> ISNULL(deleted.[TableName],'')

 IF UPDATE([Description])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDTH' , '<KeyString TableName = "' + REPLACE(CAST(inserted.TableName AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'Description' ,  CONVERT(VARCHAR(MAX), deleted.[Description]) ,  Convert(VARCHAR(MAX), inserted.[Description]) , GETDATE() , HOST_NAME() , 'UPDATE vDDTH SET Description = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[Description]), '''' , ''''''), 'NULL') + ''' WHERE TableName = ''' + CAST(inserted.TableName AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[TableName] = deleted.[TableName] 
         AND ISNULL(inserted.[Description],'') <> ISNULL(deleted.[Description],'')

 IF UPDATE([TableType])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDTH' , '<KeyString TableName = "' + REPLACE(CAST(inserted.TableName AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'TableType' ,  CONVERT(VARCHAR(MAX), deleted.[TableType]) ,  Convert(VARCHAR(MAX), inserted.[TableType]) , GETDATE() , HOST_NAME() , 'UPDATE vDDTH SET TableType = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[TableType]), '''' , ''''''), 'NULL') + ''' WHERE TableName = ''' + CAST(inserted.TableName AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[TableName] = deleted.[TableName] 
         AND ISNULL(inserted.[TableType],'') <> ISNULL(deleted.[TableType],'')

 END TRY 
 BEGIN CATCH 
   RAISERROR('Error in [dbo].[dbo.vtDDTHi_Audit] trigger', 16, 1 ) with log
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtDDTHu_Audit]', 'last', 'update', null
GO
CREATE UNIQUE CLUSTERED INDEX [viDDTH] ON [dbo].[vDDTH] ([TableName]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
