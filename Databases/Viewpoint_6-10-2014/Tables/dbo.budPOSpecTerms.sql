CREATE TABLE [dbo].[budPOSpecTerms]
(
[Co] [dbo].[bCompany] NOT NULL,
[Code] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Sequence] [smallint] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudPOSpecTerms_Audit_Delete ON dbo.budPOSpecTerms
 AFTER DELETE
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on Jan 24 2014 12:06PM

 BEGIN TRY 

   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budPOSpecTerms' , '<KeyString PO = "' + REPLACE(CAST(deleted.[PO] AS VARCHAR(MAX)),'"', '&quot;') + '" Code = "' + REPLACE(CAST(deleted.[Code] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , deleted.Co , 'D' , NULL , NULL , NULL , GETDATE() , SUSER_SNAME()
	FROM deleted

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudPOSpecTerms_Audit_Delete] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudPOSpecTerms_Audit_Delete]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudPOSpecTerms_Audit_Insert ON dbo.budPOSpecTerms
 AFTER INSERT
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on Jan 24 2014 12:06PM

 BEGIN TRY 

   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budPOSpecTerms' , '<KeyString PO = "' + REPLACE(CAST(inserted.[PO] AS VARCHAR(MAX)),'"', '&quot;') + '" Code = "' + REPLACE(CAST(inserted.[Code] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , ISNULL(inserted.Co, '') , 'A' , NULL , NULL , NULL , GETDATE() , SUSER_SNAME()
	FROM inserted

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudPOSpecTerms_Audit_Insert] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudPOSpecTerms_Audit_Insert]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudPOSpecTerms_Audit_Update ON dbo.budPOSpecTerms
 AFTER UPDATE 
 NOT FOR REPLICATION AS 
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on Jan 24 2014 12:06PM

 BEGIN TRY 

 IF UPDATE([Co])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budPOSpecTerms' , '<KeyString PO = "' + REPLACE(CAST(inserted.[PO] AS VARCHAR(MAX)),'"', '&quot;') + '" Code = "' + REPLACE(CAST(inserted.[Code] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[Co]' ,  CONVERT(VARCHAR(MAX), deleted.[Co]) ,  CONVERT(VARCHAR(MAX), inserted.[Co]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Co] <> deleted.[Co]) OR (inserted.[Co] IS NULL AND deleted.[Co] IS NOT NULL) OR (inserted.[Co] IS NOT NULL AND deleted.[Co] IS NULL))



 END 

 IF UPDATE([Code])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budPOSpecTerms' , '<KeyString PO = "' + REPLACE(CAST(inserted.[PO] AS VARCHAR(MAX)),'"', '&quot;') + '" Code = "' + REPLACE(CAST(inserted.[Code] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[Code]' ,  CONVERT(VARCHAR(MAX), deleted.[Code]) ,  CONVERT(VARCHAR(MAX), inserted.[Code]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Code] <> deleted.[Code]) OR (inserted.[Code] IS NULL AND deleted.[Code] IS NOT NULL) OR (inserted.[Code] IS NOT NULL AND deleted.[Code] IS NULL))



 END 

 IF UPDATE([Description])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budPOSpecTerms' , '<KeyString PO = "' + REPLACE(CAST(inserted.[PO] AS VARCHAR(MAX)),'"', '&quot;') + '" Code = "' + REPLACE(CAST(inserted.[Code] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[Description]' ,  CONVERT(VARCHAR(MAX), deleted.[Description]) ,  CONVERT(VARCHAR(MAX), inserted.[Description]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Description] <> deleted.[Description]) OR (inserted.[Description] IS NULL AND deleted.[Description] IS NOT NULL) OR (inserted.[Description] IS NOT NULL AND deleted.[Description] IS NULL))



 END 

 IF UPDATE([PO])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budPOSpecTerms' , '<KeyString PO = "' + REPLACE(CAST(inserted.[PO] AS VARCHAR(MAX)),'"', '&quot;') + '" Code = "' + REPLACE(CAST(inserted.[Code] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[PO]' ,  CONVERT(VARCHAR(MAX), deleted.[PO]) ,  CONVERT(VARCHAR(MAX), inserted.[PO]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[PO] <> deleted.[PO]) OR (inserted.[PO] IS NULL AND deleted.[PO] IS NOT NULL) OR (inserted.[PO] IS NOT NULL AND deleted.[PO] IS NULL))



 END 

 IF UPDATE([Notes])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budPOSpecTerms' , '<KeyString PO = "' + REPLACE(CAST(inserted.[PO] AS VARCHAR(MAX)),'"', '&quot;') + '" Code = "' + REPLACE(CAST(inserted.[Code] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[Notes]' ,  CONVERT(VARCHAR(MAX), deleted.[Notes]) ,  CONVERT(VARCHAR(MAX), inserted.[Notes]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Notes] <> deleted.[Notes]) OR (inserted.[Notes] IS NULL AND deleted.[Notes] IS NOT NULL) OR (inserted.[Notes] IS NOT NULL AND deleted.[Notes] IS NULL))



 END 

 IF UPDATE([UniqueAttchID])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budPOSpecTerms' , '<KeyString PO = "' + REPLACE(CAST(inserted.[PO] AS VARCHAR(MAX)),'"', '&quot;') + '" Code = "' + REPLACE(CAST(inserted.[Code] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[UniqueAttchID]' ,  CONVERT(VARCHAR(MAX), deleted.[UniqueAttchID]) ,  CONVERT(VARCHAR(MAX), inserted.[UniqueAttchID]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[UniqueAttchID] <> deleted.[UniqueAttchID]) OR (inserted.[UniqueAttchID] IS NULL AND deleted.[UniqueAttchID] IS NOT NULL) OR (inserted.[UniqueAttchID] IS NOT NULL AND deleted.[UniqueAttchID] IS NULL))



 END 

 IF UPDATE([Sequence])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budPOSpecTerms' , '<KeyString PO = "' + REPLACE(CAST(inserted.[PO] AS VARCHAR(MAX)),'"', '&quot;') + '" Code = "' + REPLACE(CAST(inserted.[Code] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[Sequence]' ,  CONVERT(VARCHAR(MAX), deleted.[Sequence]) ,  CONVERT(VARCHAR(MAX), inserted.[Sequence]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Sequence] <> deleted.[Sequence]) OR (inserted.[Sequence] IS NULL AND deleted.[Sequence] IS NOT NULL) OR (inserted.[Sequence] IS NOT NULL AND deleted.[Sequence] IS NULL))



 END 

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudPOSpecTerms_Audit_Update] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudPOSpecTerms_Audit_Update]', 'last', 'update', null
GO
CREATE UNIQUE CLUSTERED INDEX [biudPOSpecTerms] ON [dbo].[budPOSpecTerms] ([Co], [PO], [Code]) ON [PRIMARY]
GO
