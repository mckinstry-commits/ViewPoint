CREATE TABLE [dbo].[vDDLT]
(
[PrimaryTable] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[LinkedTable] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtDDLTd_Audit] ON [dbo].[vDDLT]
 AFTER DELETE
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 14 2009  9:56AM

 BEGIN TRY 
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDLT' , '<KeyString PrimaryTable = "' + REPLACE(CAST(deleted.PrimaryTable AS VARCHAR(MAX)),'"', '&quot;') + '" LinkedTable = "' + REPLACE(CAST(deleted.LinkedTable AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'D' , NULL , NULL , NULL , GETDATE() , HOST_NAME() , 'DELETE FROM vDDLT WHERE PrimaryTable = ''' + CAST(deleted.PrimaryTable AS VARCHAR(MAX)) + '''' + ' AND LinkedTable = ''' + CAST(deleted.LinkedTable AS VARCHAR(MAX)) + ''''
	FROM deleted
 END TRY 
 BEGIN CATCH 
   RAISERROR('Error in [dbo].[dbo.vtDDLTi_Audit] trigger', 16, 1 ) with log
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtDDLTd_Audit]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtDDLTi_Audit] ON [dbo].[vDDLT]
 AFTER INSERT
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 14 2009  9:56AM

 BEGIN TRY 
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDLT' , '<KeyString PrimaryTable = "' + REPLACE(CAST(inserted.PrimaryTable AS VARCHAR(MAX)),'"', '&quot;') + '" LinkedTable = "' + REPLACE(CAST(inserted.LinkedTable AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'A' , NULL , NULL , NULL , GETDATE() , HOST_NAME() , 'INSERT INTO dbo.[vDDLT] ([PrimaryTable], [LinkedTable]) VALUES (' + ISNULL('''' + REPLACE(CAST(PrimaryTable AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL('''' + REPLACE(CAST(LinkedTable AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL')  + ')'
	FROM inserted
 END TRY 
 BEGIN CATCH 
   RAISERROR('Error in [dbo].[dbo.vtDDLTi_Audit] trigger', 16, 1 ) with log
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtDDLTi_Audit]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtDDLTu_Audit] ON [dbo].[vDDLT]
 AFTER UPDATE 
 NOT FOR REPLICATION AS 
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 14 2009  9:56AM

 BEGIN TRY 
 IF UPDATE([PrimaryTable])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDLT' , '<KeyString PrimaryTable = "' + REPLACE(CAST(inserted.PrimaryTable AS VARCHAR(MAX)),'"', '&quot;') + '" LinkedTable = "' + REPLACE(CAST(inserted.LinkedTable AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'PrimaryTable' ,  CONVERT(VARCHAR(MAX), deleted.[PrimaryTable]) ,  Convert(VARCHAR(MAX), inserted.[PrimaryTable]) , GETDATE() , HOST_NAME() , 'UPDATE vDDLT SET PrimaryTable = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[PrimaryTable]), '''' , ''''''), 'NULL') + ''' WHERE PrimaryTable = ''' + CAST(inserted.PrimaryTable AS VARCHAR(MAX)) + '''' + ' AND LinkedTable = ''' + CAST(inserted.LinkedTable AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[PrimaryTable] = deleted.[PrimaryTable]  AND  inserted.[LinkedTable] = deleted.[LinkedTable] 
         AND ISNULL(inserted.[PrimaryTable],'') <> ISNULL(deleted.[PrimaryTable],'')

 IF UPDATE([LinkedTable])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDLT' , '<KeyString PrimaryTable = "' + REPLACE(CAST(inserted.PrimaryTable AS VARCHAR(MAX)),'"', '&quot;') + '" LinkedTable = "' + REPLACE(CAST(inserted.LinkedTable AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'LinkedTable' ,  CONVERT(VARCHAR(MAX), deleted.[LinkedTable]) ,  Convert(VARCHAR(MAX), inserted.[LinkedTable]) , GETDATE() , HOST_NAME() , 'UPDATE vDDLT SET LinkedTable = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[LinkedTable]), '''' , ''''''), 'NULL') + ''' WHERE PrimaryTable = ''' + CAST(inserted.PrimaryTable AS VARCHAR(MAX)) + '''' + ' AND LinkedTable = ''' + CAST(inserted.LinkedTable AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[PrimaryTable] = deleted.[PrimaryTable]  AND  inserted.[LinkedTable] = deleted.[LinkedTable] 
         AND ISNULL(inserted.[LinkedTable],'') <> ISNULL(deleted.[LinkedTable],'')

 END TRY 
 BEGIN CATCH 
   RAISERROR('Error in [dbo].[dbo.vtDDLTi_Audit] trigger', 16, 1 ) with log
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtDDLTu_Audit]', 'last', 'update', null
GO
CREATE UNIQUE CLUSTERED INDEX [viDDLT] ON [dbo].[vDDLT] ([PrimaryTable], [LinkedTable]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO