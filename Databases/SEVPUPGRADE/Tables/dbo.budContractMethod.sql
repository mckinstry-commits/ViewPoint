CREATE TABLE [dbo].[budContractMethod]
(
[Description] [dbo].[bDesc] NULL,
[Seq] [smallint] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudContractMethod_Audit_Delete ON dbo.budContractMethod
 AFTER DELETE
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on Sep 13 2013 12:58PM

 BEGIN TRY 

   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budContractMethod' , '<KeyString Sequence = "' + REPLACE(CAST(deleted.[Seq] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'D' , NULL , NULL , NULL , GETDATE() , SUSER_SNAME()
	FROM deleted

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudContractMethod_Audit_Delete] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudContractMethod_Audit_Delete]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudContractMethod_Audit_Insert ON dbo.budContractMethod
 AFTER INSERT
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on Sep 13 2013 12:58PM

 BEGIN TRY 

   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budContractMethod' , '<KeyString Sequence = "' + REPLACE(CAST(inserted.[Seq] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'A' , NULL , NULL , NULL , GETDATE() , SUSER_SNAME()
	FROM inserted

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudContractMethod_Audit_Insert] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudContractMethod_Audit_Insert]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudContractMethod_Audit_Update ON dbo.budContractMethod
 AFTER UPDATE 
 NOT FOR REPLICATION AS 
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on Sep 13 2013 12:58PM

 BEGIN TRY 

 IF UPDATE([Description])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budContractMethod' , '<KeyString Sequence = "' + REPLACE(CAST(inserted.[Seq] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[Description]' ,  CONVERT(VARCHAR(MAX), deleted.[Description]) ,  CONVERT(VARCHAR(MAX), inserted.[Description]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Description] <> deleted.[Description]) OR (inserted.[Description] IS NULL AND deleted.[Description] IS NOT NULL) OR (inserted.[Description] IS NOT NULL AND deleted.[Description] IS NULL))



 END 

 IF UPDATE([Seq])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budContractMethod' , '<KeyString Sequence = "' + REPLACE(CAST(inserted.[Seq] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[Seq]' ,  CONVERT(VARCHAR(MAX), deleted.[Seq]) ,  CONVERT(VARCHAR(MAX), inserted.[Seq]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Seq] <> deleted.[Seq]) OR (inserted.[Seq] IS NULL AND deleted.[Seq] IS NOT NULL) OR (inserted.[Seq] IS NOT NULL AND deleted.[Seq] IS NULL))



 END 

 IF UPDATE([UniqueAttchID])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budContractMethod' , '<KeyString Sequence = "' + REPLACE(CAST(inserted.[Seq] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[UniqueAttchID]' ,  CONVERT(VARCHAR(MAX), deleted.[UniqueAttchID]) ,  CONVERT(VARCHAR(MAX), inserted.[UniqueAttchID]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[UniqueAttchID] <> deleted.[UniqueAttchID]) OR (inserted.[UniqueAttchID] IS NULL AND deleted.[UniqueAttchID] IS NOT NULL) OR (inserted.[UniqueAttchID] IS NOT NULL AND deleted.[UniqueAttchID] IS NULL))



 END 

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudContractMethod_Audit_Update] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudContractMethod_Audit_Update]', 'last', 'update', null
GO
CREATE UNIQUE CLUSTERED INDEX [biudContractMethod] ON [dbo].[budContractMethod] ([Seq]) ON [PRIMARY]
GO
