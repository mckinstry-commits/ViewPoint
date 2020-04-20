CREATE TABLE [dbo].[budxrefPRDeptPaySeq]
(
[PRDept] [dbo].[bDept] NOT NULL,
[PaySeq] [tinyint] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudxrefPRDeptPaySeq_Audit_Delete ON dbo.budxrefPRDeptPaySeq
 AFTER DELETE
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on Jan 27 2014  1:22PM

 BEGIN TRY 

   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budxrefPRDeptPaySeq' , '<KeyString PRDept = "' + REPLACE(CAST(deleted.[PRDept] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'D' , NULL , NULL , NULL , GETDATE() , SUSER_SNAME()
	FROM deleted

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudxrefPRDeptPaySeq_Audit_Delete] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudxrefPRDeptPaySeq_Audit_Delete]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudxrefPRDeptPaySeq_Audit_Insert ON dbo.budxrefPRDeptPaySeq
 AFTER INSERT
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on Jan 27 2014  1:22PM

 BEGIN TRY 

   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budxrefPRDeptPaySeq' , '<KeyString PRDept = "' + REPLACE(CAST(inserted.[PRDept] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'A' , NULL , NULL , NULL , GETDATE() , SUSER_SNAME()
	FROM inserted

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudxrefPRDeptPaySeq_Audit_Insert] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudxrefPRDeptPaySeq_Audit_Insert]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudxrefPRDeptPaySeq_Audit_Update ON dbo.budxrefPRDeptPaySeq
 AFTER UPDATE 
 NOT FOR REPLICATION AS 
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on Jan 27 2014  1:22PM

 BEGIN TRY 

 IF UPDATE([PRDept])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budxrefPRDeptPaySeq' , '<KeyString PRDept = "' + REPLACE(CAST(inserted.[PRDept] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[PRDept]' ,  CONVERT(VARCHAR(MAX), deleted.[PRDept]) ,  CONVERT(VARCHAR(MAX), inserted.[PRDept]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[PRDept] <> deleted.[PRDept]) OR (inserted.[PRDept] IS NULL AND deleted.[PRDept] IS NOT NULL) OR (inserted.[PRDept] IS NOT NULL AND deleted.[PRDept] IS NULL))



 END 

 IF UPDATE([PaySeq])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budxrefPRDeptPaySeq' , '<KeyString PRDept = "' + REPLACE(CAST(inserted.[PRDept] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[PaySeq]' ,  CONVERT(VARCHAR(MAX), deleted.[PaySeq]) ,  CONVERT(VARCHAR(MAX), inserted.[PaySeq]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[PaySeq] <> deleted.[PaySeq]) OR (inserted.[PaySeq] IS NULL AND deleted.[PaySeq] IS NOT NULL) OR (inserted.[PaySeq] IS NOT NULL AND deleted.[PaySeq] IS NULL))



 END 

 IF UPDATE([Notes])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budxrefPRDeptPaySeq' , '<KeyString PRDept = "' + REPLACE(CAST(inserted.[PRDept] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[Notes]' ,  CONVERT(VARCHAR(MAX), deleted.[Notes]) ,  CONVERT(VARCHAR(MAX), inserted.[Notes]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Notes] <> deleted.[Notes]) OR (inserted.[Notes] IS NULL AND deleted.[Notes] IS NOT NULL) OR (inserted.[Notes] IS NOT NULL AND deleted.[Notes] IS NULL))



 END 

 IF UPDATE([UniqueAttchID])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budxrefPRDeptPaySeq' , '<KeyString PRDept = "' + REPLACE(CAST(inserted.[PRDept] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[UniqueAttchID]' ,  CONVERT(VARCHAR(MAX), deleted.[UniqueAttchID]) ,  CONVERT(VARCHAR(MAX), inserted.[UniqueAttchID]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[UniqueAttchID] <> deleted.[UniqueAttchID]) OR (inserted.[UniqueAttchID] IS NULL AND deleted.[UniqueAttchID] IS NOT NULL) OR (inserted.[UniqueAttchID] IS NOT NULL AND deleted.[UniqueAttchID] IS NULL))



 END 

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudxrefPRDeptPaySeq_Audit_Update] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudxrefPRDeptPaySeq_Audit_Update]', 'last', 'update', null
GO
CREATE UNIQUE CLUSTERED INDEX [biudxrefPRDeptPaySeq] ON [dbo].[budxrefPRDeptPaySeq] ([PRDept]) ON [PRIMARY]
GO