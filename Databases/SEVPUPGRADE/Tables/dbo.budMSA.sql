CREATE TABLE [dbo].[budMSA]
(
[Seq] [int] NOT NULL,
[Title] [dbo].[bDesc] NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudMSA_Audit_Delete ON dbo.budMSA
 AFTER DELETE
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on Sep 30 2013  9:24AM

 BEGIN TRY 

   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budMSA' , '<KeyString VendorGroup = "' + REPLACE(CAST(deleted.[VendorGroup] AS VARCHAR(MAX)),'"', '&quot;') + '" Vendor = "' + REPLACE(CAST(deleted.[Vendor] AS VARCHAR(MAX)),'"', '&quot;') + '" Sequence = "' + REPLACE(CAST(deleted.[Seq] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'D' , NULL , NULL , NULL , GETDATE() , SUSER_SNAME()
	FROM deleted

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudMSA_Audit_Delete] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudMSA_Audit_Delete]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudMSA_Audit_Insert ON dbo.budMSA
 AFTER INSERT
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on Sep 30 2013  9:24AM

 BEGIN TRY 

   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budMSA' , '<KeyString VendorGroup = "' + REPLACE(CAST(inserted.[VendorGroup] AS VARCHAR(MAX)),'"', '&quot;') + '" Vendor = "' + REPLACE(CAST(inserted.[Vendor] AS VARCHAR(MAX)),'"', '&quot;') + '" Sequence = "' + REPLACE(CAST(inserted.[Seq] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'A' , NULL , NULL , NULL , GETDATE() , SUSER_SNAME()
	FROM inserted

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudMSA_Audit_Insert] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudMSA_Audit_Insert]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudMSA_Audit_Update ON dbo.budMSA
 AFTER UPDATE 
 NOT FOR REPLICATION AS 
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on Sep 30 2013  9:24AM

 BEGIN TRY 

 IF UPDATE([Seq])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budMSA' , '<KeyString VendorGroup = "' + REPLACE(CAST(inserted.[VendorGroup] AS VARCHAR(MAX)),'"', '&quot;') + '" Vendor = "' + REPLACE(CAST(inserted.[Vendor] AS VARCHAR(MAX)),'"', '&quot;') + '" Sequence = "' + REPLACE(CAST(inserted.[Seq] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[Seq]' ,  CONVERT(VARCHAR(MAX), deleted.[Seq]) ,  CONVERT(VARCHAR(MAX), inserted.[Seq]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Seq] <> deleted.[Seq]) OR (inserted.[Seq] IS NULL AND deleted.[Seq] IS NOT NULL) OR (inserted.[Seq] IS NOT NULL AND deleted.[Seq] IS NULL))



 END 

 IF UPDATE([Title])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budMSA' , '<KeyString VendorGroup = "' + REPLACE(CAST(inserted.[VendorGroup] AS VARCHAR(MAX)),'"', '&quot;') + '" Vendor = "' + REPLACE(CAST(inserted.[Vendor] AS VARCHAR(MAX)),'"', '&quot;') + '" Sequence = "' + REPLACE(CAST(inserted.[Seq] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[Title]' ,  CONVERT(VARCHAR(MAX), deleted.[Title]) ,  CONVERT(VARCHAR(MAX), inserted.[Title]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Title] <> deleted.[Title]) OR (inserted.[Title] IS NULL AND deleted.[Title] IS NOT NULL) OR (inserted.[Title] IS NOT NULL AND deleted.[Title] IS NULL))



 END 

 IF UPDATE([Vendor])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budMSA' , '<KeyString VendorGroup = "' + REPLACE(CAST(inserted.[VendorGroup] AS VARCHAR(MAX)),'"', '&quot;') + '" Vendor = "' + REPLACE(CAST(inserted.[Vendor] AS VARCHAR(MAX)),'"', '&quot;') + '" Sequence = "' + REPLACE(CAST(inserted.[Seq] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[Vendor]' ,  CONVERT(VARCHAR(MAX), deleted.[Vendor]) ,  CONVERT(VARCHAR(MAX), inserted.[Vendor]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Vendor] <> deleted.[Vendor]) OR (inserted.[Vendor] IS NULL AND deleted.[Vendor] IS NOT NULL) OR (inserted.[Vendor] IS NOT NULL AND deleted.[Vendor] IS NULL))



 END 

 IF UPDATE([VendorGroup])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budMSA' , '<KeyString VendorGroup = "' + REPLACE(CAST(inserted.[VendorGroup] AS VARCHAR(MAX)),'"', '&quot;') + '" Vendor = "' + REPLACE(CAST(inserted.[Vendor] AS VARCHAR(MAX)),'"', '&quot;') + '" Sequence = "' + REPLACE(CAST(inserted.[Seq] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[VendorGroup]' ,  CONVERT(VARCHAR(MAX), deleted.[VendorGroup]) ,  CONVERT(VARCHAR(MAX), inserted.[VendorGroup]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[VendorGroup] <> deleted.[VendorGroup]) OR (inserted.[VendorGroup] IS NULL AND deleted.[VendorGroup] IS NOT NULL) OR (inserted.[VendorGroup] IS NOT NULL AND deleted.[VendorGroup] IS NULL))



 END 

 IF UPDATE([UniqueAttchID])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budMSA' , '<KeyString VendorGroup = "' + REPLACE(CAST(inserted.[VendorGroup] AS VARCHAR(MAX)),'"', '&quot;') + '" Vendor = "' + REPLACE(CAST(inserted.[Vendor] AS VARCHAR(MAX)),'"', '&quot;') + '" Sequence = "' + REPLACE(CAST(inserted.[Seq] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[UniqueAttchID]' ,  CONVERT(VARCHAR(MAX), deleted.[UniqueAttchID]) ,  CONVERT(VARCHAR(MAX), inserted.[UniqueAttchID]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[UniqueAttchID] <> deleted.[UniqueAttchID]) OR (inserted.[UniqueAttchID] IS NULL AND deleted.[UniqueAttchID] IS NOT NULL) OR (inserted.[UniqueAttchID] IS NOT NULL AND deleted.[UniqueAttchID] IS NULL))



 END 

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudMSA_Audit_Update] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudMSA_Audit_Update]', 'last', 'update', null
GO
CREATE UNIQUE CLUSTERED INDEX [biudMSA] ON [dbo].[budMSA] ([VendorGroup], [Vendor], [Seq]) ON [PRIMARY]
GO