CREATE TABLE [dbo].[budxrefPRDept_McK]
(
[CGCCompany] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[CGCGLDeptDesc] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[CGCGLDeptNumber] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[CGCPRDeptDesc] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[CGCPRDeptNumber] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[VPGLDeptDesc] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[VPGLDeptNumber] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[VPPRDeptDesc] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[VPPRDeptNumber] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[VPProductionCompany] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[VPTestCompany] [varchar] (10) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudxrefPRDept_McK_Audit_Delete ON dbo.budxrefPRDept_McK
 AFTER DELETE
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on Nov 20 2013 11:46AM

 BEGIN TRY 

   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budxrefPRDept_McK' , '<KeyString CGCCompany = "' + REPLACE(CAST(deleted.[CGCCompany] AS VARCHAR(MAX)),'"', '&quot;') + '" CGCPRDeptNumber = "' + REPLACE(CAST(deleted.[CGCPRDeptNumber] AS VARCHAR(MAX)),'"', '&quot;') + '" VPProductionCompany = "' + REPLACE(CAST(deleted.[VPProductionCompany] AS VARCHAR(MAX)),'"', '&quot;') + '" VPPRDeptNumber = "' + REPLACE(CAST(deleted.[VPPRDeptNumber] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'D' , NULL , NULL , NULL , GETDATE() , SUSER_SNAME()
	FROM deleted

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudxrefPRDept_McK_Audit_Delete] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudxrefPRDept_McK_Audit_Delete]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudxrefPRDept_McK_Audit_Insert ON dbo.budxrefPRDept_McK
 AFTER INSERT
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on Nov 20 2013 11:46AM

 BEGIN TRY 

   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budxrefPRDept_McK' , '<KeyString CGCCompany = "' + REPLACE(CAST(inserted.[CGCCompany] AS VARCHAR(MAX)),'"', '&quot;') + '" CGCPRDeptNumber = "' + REPLACE(CAST(inserted.[CGCPRDeptNumber] AS VARCHAR(MAX)),'"', '&quot;') + '" VPProductionCompany = "' + REPLACE(CAST(inserted.[VPProductionCompany] AS VARCHAR(MAX)),'"', '&quot;') + '" VPPRDeptNumber = "' + REPLACE(CAST(inserted.[VPPRDeptNumber] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'A' , NULL , NULL , NULL , GETDATE() , SUSER_SNAME()
	FROM inserted

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudxrefPRDept_McK_Audit_Insert] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudxrefPRDept_McK_Audit_Insert]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudxrefPRDept_McK_Audit_Update ON dbo.budxrefPRDept_McK
 AFTER UPDATE 
 NOT FOR REPLICATION AS 
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on Nov 20 2013 11:46AM

 BEGIN TRY 

 IF UPDATE([CGCCompany])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budxrefPRDept_McK' , '<KeyString CGCCompany = "' + REPLACE(CAST(inserted.[CGCCompany] AS VARCHAR(MAX)),'"', '&quot;') + '" CGCPRDeptNumber = "' + REPLACE(CAST(inserted.[CGCPRDeptNumber] AS VARCHAR(MAX)),'"', '&quot;') + '" VPProductionCompany = "' + REPLACE(CAST(inserted.[VPProductionCompany] AS VARCHAR(MAX)),'"', '&quot;') + '" VPPRDeptNumber = "' + REPLACE(CAST(inserted.[VPPRDeptNumber] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[CGCCompany]' ,  CONVERT(VARCHAR(MAX), deleted.[CGCCompany]) ,  CONVERT(VARCHAR(MAX), inserted.[CGCCompany]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[CGCCompany] <> deleted.[CGCCompany]) OR (inserted.[CGCCompany] IS NULL AND deleted.[CGCCompany] IS NOT NULL) OR (inserted.[CGCCompany] IS NOT NULL AND deleted.[CGCCompany] IS NULL))



 END 

 IF UPDATE([CGCGLDeptDesc])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budxrefPRDept_McK' , '<KeyString CGCCompany = "' + REPLACE(CAST(inserted.[CGCCompany] AS VARCHAR(MAX)),'"', '&quot;') + '" CGCPRDeptNumber = "' + REPLACE(CAST(inserted.[CGCPRDeptNumber] AS VARCHAR(MAX)),'"', '&quot;') + '" VPProductionCompany = "' + REPLACE(CAST(inserted.[VPProductionCompany] AS VARCHAR(MAX)),'"', '&quot;') + '" VPPRDeptNumber = "' + REPLACE(CAST(inserted.[VPPRDeptNumber] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[CGCGLDeptDesc]' ,  CONVERT(VARCHAR(MAX), deleted.[CGCGLDeptDesc]) ,  CONVERT(VARCHAR(MAX), inserted.[CGCGLDeptDesc]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[CGCGLDeptDesc] <> deleted.[CGCGLDeptDesc]) OR (inserted.[CGCGLDeptDesc] IS NULL AND deleted.[CGCGLDeptDesc] IS NOT NULL) OR (inserted.[CGCGLDeptDesc] IS NOT NULL AND deleted.[CGCGLDeptDesc] IS NULL))



 END 

 IF UPDATE([CGCGLDeptNumber])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budxrefPRDept_McK' , '<KeyString CGCCompany = "' + REPLACE(CAST(inserted.[CGCCompany] AS VARCHAR(MAX)),'"', '&quot;') + '" CGCPRDeptNumber = "' + REPLACE(CAST(inserted.[CGCPRDeptNumber] AS VARCHAR(MAX)),'"', '&quot;') + '" VPProductionCompany = "' + REPLACE(CAST(inserted.[VPProductionCompany] AS VARCHAR(MAX)),'"', '&quot;') + '" VPPRDeptNumber = "' + REPLACE(CAST(inserted.[VPPRDeptNumber] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[CGCGLDeptNumber]' ,  CONVERT(VARCHAR(MAX), deleted.[CGCGLDeptNumber]) ,  CONVERT(VARCHAR(MAX), inserted.[CGCGLDeptNumber]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[CGCGLDeptNumber] <> deleted.[CGCGLDeptNumber]) OR (inserted.[CGCGLDeptNumber] IS NULL AND deleted.[CGCGLDeptNumber] IS NOT NULL) OR (inserted.[CGCGLDeptNumber] IS NOT NULL AND deleted.[CGCGLDeptNumber] IS NULL))



 END 

 IF UPDATE([CGCPRDeptDesc])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budxrefPRDept_McK' , '<KeyString CGCCompany = "' + REPLACE(CAST(inserted.[CGCCompany] AS VARCHAR(MAX)),'"', '&quot;') + '" CGCPRDeptNumber = "' + REPLACE(CAST(inserted.[CGCPRDeptNumber] AS VARCHAR(MAX)),'"', '&quot;') + '" VPProductionCompany = "' + REPLACE(CAST(inserted.[VPProductionCompany] AS VARCHAR(MAX)),'"', '&quot;') + '" VPPRDeptNumber = "' + REPLACE(CAST(inserted.[VPPRDeptNumber] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[CGCPRDeptDesc]' ,  CONVERT(VARCHAR(MAX), deleted.[CGCPRDeptDesc]) ,  CONVERT(VARCHAR(MAX), inserted.[CGCPRDeptDesc]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[CGCPRDeptDesc] <> deleted.[CGCPRDeptDesc]) OR (inserted.[CGCPRDeptDesc] IS NULL AND deleted.[CGCPRDeptDesc] IS NOT NULL) OR (inserted.[CGCPRDeptDesc] IS NOT NULL AND deleted.[CGCPRDeptDesc] IS NULL))



 END 

 IF UPDATE([CGCPRDeptNumber])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budxrefPRDept_McK' , '<KeyString CGCCompany = "' + REPLACE(CAST(inserted.[CGCCompany] AS VARCHAR(MAX)),'"', '&quot;') + '" CGCPRDeptNumber = "' + REPLACE(CAST(inserted.[CGCPRDeptNumber] AS VARCHAR(MAX)),'"', '&quot;') + '" VPProductionCompany = "' + REPLACE(CAST(inserted.[VPProductionCompany] AS VARCHAR(MAX)),'"', '&quot;') + '" VPPRDeptNumber = "' + REPLACE(CAST(inserted.[VPPRDeptNumber] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[CGCPRDeptNumber]' ,  CONVERT(VARCHAR(MAX), deleted.[CGCPRDeptNumber]) ,  CONVERT(VARCHAR(MAX), inserted.[CGCPRDeptNumber]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[CGCPRDeptNumber] <> deleted.[CGCPRDeptNumber]) OR (inserted.[CGCPRDeptNumber] IS NULL AND deleted.[CGCPRDeptNumber] IS NOT NULL) OR (inserted.[CGCPRDeptNumber] IS NOT NULL AND deleted.[CGCPRDeptNumber] IS NULL))



 END 

 IF UPDATE([VPGLDeptDesc])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budxrefPRDept_McK' , '<KeyString CGCCompany = "' + REPLACE(CAST(inserted.[CGCCompany] AS VARCHAR(MAX)),'"', '&quot;') + '" CGCPRDeptNumber = "' + REPLACE(CAST(inserted.[CGCPRDeptNumber] AS VARCHAR(MAX)),'"', '&quot;') + '" VPProductionCompany = "' + REPLACE(CAST(inserted.[VPProductionCompany] AS VARCHAR(MAX)),'"', '&quot;') + '" VPPRDeptNumber = "' + REPLACE(CAST(inserted.[VPPRDeptNumber] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[VPGLDeptDesc]' ,  CONVERT(VARCHAR(MAX), deleted.[VPGLDeptDesc]) ,  CONVERT(VARCHAR(MAX), inserted.[VPGLDeptDesc]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[VPGLDeptDesc] <> deleted.[VPGLDeptDesc]) OR (inserted.[VPGLDeptDesc] IS NULL AND deleted.[VPGLDeptDesc] IS NOT NULL) OR (inserted.[VPGLDeptDesc] IS NOT NULL AND deleted.[VPGLDeptDesc] IS NULL))



 END 

 IF UPDATE([VPGLDeptNumber])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budxrefPRDept_McK' , '<KeyString CGCCompany = "' + REPLACE(CAST(inserted.[CGCCompany] AS VARCHAR(MAX)),'"', '&quot;') + '" CGCPRDeptNumber = "' + REPLACE(CAST(inserted.[CGCPRDeptNumber] AS VARCHAR(MAX)),'"', '&quot;') + '" VPProductionCompany = "' + REPLACE(CAST(inserted.[VPProductionCompany] AS VARCHAR(MAX)),'"', '&quot;') + '" VPPRDeptNumber = "' + REPLACE(CAST(inserted.[VPPRDeptNumber] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[VPGLDeptNumber]' ,  CONVERT(VARCHAR(MAX), deleted.[VPGLDeptNumber]) ,  CONVERT(VARCHAR(MAX), inserted.[VPGLDeptNumber]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[VPGLDeptNumber] <> deleted.[VPGLDeptNumber]) OR (inserted.[VPGLDeptNumber] IS NULL AND deleted.[VPGLDeptNumber] IS NOT NULL) OR (inserted.[VPGLDeptNumber] IS NOT NULL AND deleted.[VPGLDeptNumber] IS NULL))



 END 

 IF UPDATE([VPPRDeptDesc])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budxrefPRDept_McK' , '<KeyString CGCCompany = "' + REPLACE(CAST(inserted.[CGCCompany] AS VARCHAR(MAX)),'"', '&quot;') + '" CGCPRDeptNumber = "' + REPLACE(CAST(inserted.[CGCPRDeptNumber] AS VARCHAR(MAX)),'"', '&quot;') + '" VPProductionCompany = "' + REPLACE(CAST(inserted.[VPProductionCompany] AS VARCHAR(MAX)),'"', '&quot;') + '" VPPRDeptNumber = "' + REPLACE(CAST(inserted.[VPPRDeptNumber] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[VPPRDeptDesc]' ,  CONVERT(VARCHAR(MAX), deleted.[VPPRDeptDesc]) ,  CONVERT(VARCHAR(MAX), inserted.[VPPRDeptDesc]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[VPPRDeptDesc] <> deleted.[VPPRDeptDesc]) OR (inserted.[VPPRDeptDesc] IS NULL AND deleted.[VPPRDeptDesc] IS NOT NULL) OR (inserted.[VPPRDeptDesc] IS NOT NULL AND deleted.[VPPRDeptDesc] IS NULL))



 END 

 IF UPDATE([VPPRDeptNumber])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budxrefPRDept_McK' , '<KeyString CGCCompany = "' + REPLACE(CAST(inserted.[CGCCompany] AS VARCHAR(MAX)),'"', '&quot;') + '" CGCPRDeptNumber = "' + REPLACE(CAST(inserted.[CGCPRDeptNumber] AS VARCHAR(MAX)),'"', '&quot;') + '" VPProductionCompany = "' + REPLACE(CAST(inserted.[VPProductionCompany] AS VARCHAR(MAX)),'"', '&quot;') + '" VPPRDeptNumber = "' + REPLACE(CAST(inserted.[VPPRDeptNumber] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[VPPRDeptNumber]' ,  CONVERT(VARCHAR(MAX), deleted.[VPPRDeptNumber]) ,  CONVERT(VARCHAR(MAX), inserted.[VPPRDeptNumber]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[VPPRDeptNumber] <> deleted.[VPPRDeptNumber]) OR (inserted.[VPPRDeptNumber] IS NULL AND deleted.[VPPRDeptNumber] IS NOT NULL) OR (inserted.[VPPRDeptNumber] IS NOT NULL AND deleted.[VPPRDeptNumber] IS NULL))



 END 

 IF UPDATE([VPProductionCompany])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budxrefPRDept_McK' , '<KeyString CGCCompany = "' + REPLACE(CAST(inserted.[CGCCompany] AS VARCHAR(MAX)),'"', '&quot;') + '" CGCPRDeptNumber = "' + REPLACE(CAST(inserted.[CGCPRDeptNumber] AS VARCHAR(MAX)),'"', '&quot;') + '" VPProductionCompany = "' + REPLACE(CAST(inserted.[VPProductionCompany] AS VARCHAR(MAX)),'"', '&quot;') + '" VPPRDeptNumber = "' + REPLACE(CAST(inserted.[VPPRDeptNumber] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[VPProductionCompany]' ,  CONVERT(VARCHAR(MAX), deleted.[VPProductionCompany]) ,  CONVERT(VARCHAR(MAX), inserted.[VPProductionCompany]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[VPProductionCompany] <> deleted.[VPProductionCompany]) OR (inserted.[VPProductionCompany] IS NULL AND deleted.[VPProductionCompany] IS NOT NULL) OR (inserted.[VPProductionCompany] IS NOT NULL AND deleted.[VPProductionCompany] IS NULL))



 END 

 IF UPDATE([UniqueAttchID])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budxrefPRDept_McK' , '<KeyString CGCCompany = "' + REPLACE(CAST(inserted.[CGCCompany] AS VARCHAR(MAX)),'"', '&quot;') + '" CGCPRDeptNumber = "' + REPLACE(CAST(inserted.[CGCPRDeptNumber] AS VARCHAR(MAX)),'"', '&quot;') + '" VPProductionCompany = "' + REPLACE(CAST(inserted.[VPProductionCompany] AS VARCHAR(MAX)),'"', '&quot;') + '" VPPRDeptNumber = "' + REPLACE(CAST(inserted.[VPPRDeptNumber] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[UniqueAttchID]' ,  CONVERT(VARCHAR(MAX), deleted.[UniqueAttchID]) ,  CONVERT(VARCHAR(MAX), inserted.[UniqueAttchID]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[UniqueAttchID] <> deleted.[UniqueAttchID]) OR (inserted.[UniqueAttchID] IS NULL AND deleted.[UniqueAttchID] IS NOT NULL) OR (inserted.[UniqueAttchID] IS NOT NULL AND deleted.[UniqueAttchID] IS NULL))



 END 

 IF UPDATE([VPTestCompany])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budxrefPRDept_McK' , '<KeyString CGCCompany = "' + REPLACE(CAST(inserted.[CGCCompany] AS VARCHAR(MAX)),'"', '&quot;') + '" CGCPRDeptNumber = "' + REPLACE(CAST(inserted.[CGCPRDeptNumber] AS VARCHAR(MAX)),'"', '&quot;') + '" VPProductionCompany = "' + REPLACE(CAST(inserted.[VPProductionCompany] AS VARCHAR(MAX)),'"', '&quot;') + '" VPPRDeptNumber = "' + REPLACE(CAST(inserted.[VPPRDeptNumber] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[VPTestCompany]' ,  CONVERT(VARCHAR(MAX), deleted.[VPTestCompany]) ,  CONVERT(VARCHAR(MAX), inserted.[VPTestCompany]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[VPTestCompany] <> deleted.[VPTestCompany]) OR (inserted.[VPTestCompany] IS NULL AND deleted.[VPTestCompany] IS NOT NULL) OR (inserted.[VPTestCompany] IS NOT NULL AND deleted.[VPTestCompany] IS NULL))



 END 

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudxrefPRDept_McK_Audit_Update] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudxrefPRDept_McK_Audit_Update]', 'last', 'update', null
GO
CREATE UNIQUE CLUSTERED INDEX [biudxrefPRDept_McK] ON [dbo].[budxrefPRDept_McK] ([CGCCompany], [CGCPRDeptNumber], [VPProductionCompany], [VPPRDeptNumber]) ON [PRIMARY]
GO