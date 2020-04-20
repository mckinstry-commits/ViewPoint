CREATE TABLE [dbo].[budLegalGuide]
(
[Guideline] [varchar] (8000) COLLATE Latin1_General_BIN NULL,
[Issue] [dbo].[bDesc] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudLegalGuide_Audit_Delete ON dbo.budLegalGuide
 AFTER DELETE
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on Mar  4 2014 12:46PM

 BEGIN TRY 

   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budLegalGuide' , '<KeyString Issue = "' + REPLACE(CAST(deleted.[Issue] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'D' , NULL , NULL , NULL , GETDATE() , SUSER_SNAME()
	FROM deleted

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudLegalGuide_Audit_Delete] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudLegalGuide_Audit_Delete]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudLegalGuide_Audit_Insert ON dbo.budLegalGuide
 AFTER INSERT
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on Mar  4 2014 12:46PM

 BEGIN TRY 

   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budLegalGuide' , '<KeyString Issue = "' + REPLACE(CAST(inserted.[Issue] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'A' , NULL , NULL , NULL , GETDATE() , SUSER_SNAME()
	FROM inserted

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudLegalGuide_Audit_Insert] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudLegalGuide_Audit_Insert]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudLegalGuide_Audit_Update ON dbo.budLegalGuide
 AFTER UPDATE 
 NOT FOR REPLICATION AS 
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on Mar  4 2014 12:46PM

 BEGIN TRY 

 IF UPDATE([Guideline])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budLegalGuide' , '<KeyString Issue = "' + REPLACE(CAST(inserted.[Issue] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[Guideline]' ,  CONVERT(VARCHAR(MAX), deleted.[Guideline]) ,  CONVERT(VARCHAR(MAX), inserted.[Guideline]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Guideline] <> deleted.[Guideline]) OR (inserted.[Guideline] IS NULL AND deleted.[Guideline] IS NOT NULL) OR (inserted.[Guideline] IS NOT NULL AND deleted.[Guideline] IS NULL))



 END 

 IF UPDATE([Issue])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budLegalGuide' , '<KeyString Issue = "' + REPLACE(CAST(inserted.[Issue] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[Issue]' ,  CONVERT(VARCHAR(MAX), deleted.[Issue]) ,  CONVERT(VARCHAR(MAX), inserted.[Issue]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Issue] <> deleted.[Issue]) OR (inserted.[Issue] IS NULL AND deleted.[Issue] IS NOT NULL) OR (inserted.[Issue] IS NOT NULL AND deleted.[Issue] IS NULL))



 END 

 IF UPDATE([UniqueAttchID])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budLegalGuide' , '<KeyString Issue = "' + REPLACE(CAST(inserted.[Issue] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[UniqueAttchID]' ,  CONVERT(VARCHAR(MAX), deleted.[UniqueAttchID]) ,  CONVERT(VARCHAR(MAX), inserted.[UniqueAttchID]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[UniqueAttchID] <> deleted.[UniqueAttchID]) OR (inserted.[UniqueAttchID] IS NULL AND deleted.[UniqueAttchID] IS NOT NULL) OR (inserted.[UniqueAttchID] IS NOT NULL AND deleted.[UniqueAttchID] IS NULL))



 END 

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudLegalGuide_Audit_Update] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudLegalGuide_Audit_Update]', 'last', 'update', null
GO
CREATE UNIQUE CLUSTERED INDEX [biudLegalGuide] ON [dbo].[budLegalGuide] ([Issue]) ON [PRIMARY]
GO
