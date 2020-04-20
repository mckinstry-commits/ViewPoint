CREATE TABLE [dbo].[budEquipAttTypes]
(
[Description] [dbo].[bItemDesc] NULL,
[Type] [dbo].[bDesc] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudEquipAttTypes_Audit_Delete ON dbo.budEquipAttTypes
 AFTER DELETE
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on Dec  4 2013 10:42AM

 BEGIN TRY 

   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budEquipAttTypes' , '<KeyString Type = "' + REPLACE(CAST(deleted.[Type] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'D' , NULL , NULL , NULL , GETDATE() , SUSER_SNAME()
	FROM deleted

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudEquipAttTypes_Audit_Delete] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudEquipAttTypes_Audit_Delete]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudEquipAttTypes_Audit_Insert ON dbo.budEquipAttTypes
 AFTER INSERT
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on Dec  4 2013 10:42AM

 BEGIN TRY 

   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budEquipAttTypes' , '<KeyString Type = "' + REPLACE(CAST(inserted.[Type] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'A' , NULL , NULL , NULL , GETDATE() , SUSER_SNAME()
	FROM inserted

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudEquipAttTypes_Audit_Insert] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudEquipAttTypes_Audit_Insert]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudEquipAttTypes_Audit_Update ON dbo.budEquipAttTypes
 AFTER UPDATE 
 NOT FOR REPLICATION AS 
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on Dec  4 2013 10:42AM

 BEGIN TRY 

 IF UPDATE([Description])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budEquipAttTypes' , '<KeyString Type = "' + REPLACE(CAST(inserted.[Type] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[Description]' ,  CONVERT(VARCHAR(MAX), deleted.[Description]) ,  CONVERT(VARCHAR(MAX), inserted.[Description]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Description] <> deleted.[Description]) OR (inserted.[Description] IS NULL AND deleted.[Description] IS NOT NULL) OR (inserted.[Description] IS NOT NULL AND deleted.[Description] IS NULL))



 END 

 IF UPDATE([Type])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budEquipAttTypes' , '<KeyString Type = "' + REPLACE(CAST(inserted.[Type] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[Type]' ,  CONVERT(VARCHAR(MAX), deleted.[Type]) ,  CONVERT(VARCHAR(MAX), inserted.[Type]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Type] <> deleted.[Type]) OR (inserted.[Type] IS NULL AND deleted.[Type] IS NOT NULL) OR (inserted.[Type] IS NOT NULL AND deleted.[Type] IS NULL))



 END 

 IF UPDATE([Notes])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budEquipAttTypes' , '<KeyString Type = "' + REPLACE(CAST(inserted.[Type] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[Notes]' ,  CONVERT(VARCHAR(MAX), deleted.[Notes]) ,  CONVERT(VARCHAR(MAX), inserted.[Notes]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Notes] <> deleted.[Notes]) OR (inserted.[Notes] IS NULL AND deleted.[Notes] IS NOT NULL) OR (inserted.[Notes] IS NOT NULL AND deleted.[Notes] IS NULL))



 END 

 IF UPDATE([UniqueAttchID])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budEquipAttTypes' , '<KeyString Type = "' + REPLACE(CAST(inserted.[Type] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[UniqueAttchID]' ,  CONVERT(VARCHAR(MAX), deleted.[UniqueAttchID]) ,  CONVERT(VARCHAR(MAX), inserted.[UniqueAttchID]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[UniqueAttchID] <> deleted.[UniqueAttchID]) OR (inserted.[UniqueAttchID] IS NULL AND deleted.[UniqueAttchID] IS NOT NULL) OR (inserted.[UniqueAttchID] IS NOT NULL AND deleted.[UniqueAttchID] IS NULL))



 END 

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudEquipAttTypes_Audit_Update] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudEquipAttTypes_Audit_Update]', 'last', 'update', null
GO
CREATE UNIQUE CLUSTERED INDEX [biudEquipAttTypes] ON [dbo].[budEquipAttTypes] ([Type]) ON [PRIMARY]
GO
