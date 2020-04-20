CREATE TABLE [dbo].[budxrefPRLaborCat]
(
[CategoryLevel] [varchar] (1000) COLLATE Latin1_General_BIN NULL,
[ClassLevel] [varchar] (1000) COLLATE Latin1_General_BIN NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudxrefPRLaborCat_Audit_Delete ON dbo.budxrefPRLaborCat
 AFTER DELETE
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on Mar 31 2014 12:07PM

 BEGIN TRY 

   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budxrefPRLaborCat' , '<KeyString ClassLevel = "' + REPLACE(CAST(deleted.[ClassLevel] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'D' , NULL , NULL , NULL , GETDATE() , SUSER_SNAME()
	FROM deleted

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudxrefPRLaborCat_Audit_Delete] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudxrefPRLaborCat_Audit_Delete]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudxrefPRLaborCat_Audit_Insert ON dbo.budxrefPRLaborCat
 AFTER INSERT
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on Mar 31 2014 12:07PM

 BEGIN TRY 

   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budxrefPRLaborCat' , '<KeyString ClassLevel = "' + REPLACE(CAST(inserted.[ClassLevel] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'A' , NULL , NULL , NULL , GETDATE() , SUSER_SNAME()
	FROM inserted

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudxrefPRLaborCat_Audit_Insert] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudxrefPRLaborCat_Audit_Insert]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudxrefPRLaborCat_Audit_Update ON dbo.budxrefPRLaborCat
 AFTER UPDATE 
 NOT FOR REPLICATION AS 
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on Mar 31 2014 12:07PM

 BEGIN TRY 

 IF UPDATE([CategoryLevel])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budxrefPRLaborCat' , '<KeyString ClassLevel = "' + REPLACE(CAST(inserted.[ClassLevel] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[CategoryLevel]' ,  CONVERT(VARCHAR(MAX), deleted.[CategoryLevel]) ,  CONVERT(VARCHAR(MAX), inserted.[CategoryLevel]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[CategoryLevel] <> deleted.[CategoryLevel]) OR (inserted.[CategoryLevel] IS NULL AND deleted.[CategoryLevel] IS NOT NULL) OR (inserted.[CategoryLevel] IS NOT NULL AND deleted.[CategoryLevel] IS NULL))



 END 

 IF UPDATE([ClassLevel])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budxrefPRLaborCat' , '<KeyString ClassLevel = "' + REPLACE(CAST(inserted.[ClassLevel] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[ClassLevel]' ,  CONVERT(VARCHAR(MAX), deleted.[ClassLevel]) ,  CONVERT(VARCHAR(MAX), inserted.[ClassLevel]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[ClassLevel] <> deleted.[ClassLevel]) OR (inserted.[ClassLevel] IS NULL AND deleted.[ClassLevel] IS NOT NULL) OR (inserted.[ClassLevel] IS NOT NULL AND deleted.[ClassLevel] IS NULL))



 END 

 IF UPDATE([UniqueAttchID])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budxrefPRLaborCat' , '<KeyString ClassLevel = "' + REPLACE(CAST(inserted.[ClassLevel] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[UniqueAttchID]' ,  CONVERT(VARCHAR(MAX), deleted.[UniqueAttchID]) ,  CONVERT(VARCHAR(MAX), inserted.[UniqueAttchID]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[UniqueAttchID] <> deleted.[UniqueAttchID]) OR (inserted.[UniqueAttchID] IS NULL AND deleted.[UniqueAttchID] IS NOT NULL) OR (inserted.[UniqueAttchID] IS NOT NULL AND deleted.[UniqueAttchID] IS NULL))



 END 

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudxrefPRLaborCat_Audit_Update] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudxrefPRLaborCat_Audit_Update]', 'last', 'update', null
GO
CREATE UNIQUE CLUSTERED INDEX [biudxrefPRLaborCat] ON [dbo].[budxrefPRLaborCat] ([ClassLevel]) ON [PRIMARY]
GO