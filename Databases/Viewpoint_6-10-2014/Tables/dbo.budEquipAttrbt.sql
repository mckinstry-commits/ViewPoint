CREATE TABLE [dbo].[budEquipAttrbt]
(
[EMGroup] [dbo].[bGroup] NOT NULL,
[Equipment] [dbo].[bEquip] NOT NULL,
[Type] [dbo].[bDesc] NOT NULL,
[Value] [dbo].[bDesc] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudEquipAttrbt_Audit_Delete ON dbo.budEquipAttrbt
 AFTER DELETE
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on Dec  4 2013 10:52AM

 BEGIN TRY 

   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budEquipAttrbt' , '<KeyString EMGroup = "' + REPLACE(CAST(deleted.[EMGroup] AS VARCHAR(MAX)),'"', '&quot;') + '" Equipment = "' + REPLACE(CAST(deleted.[Equipment] AS VARCHAR(MAX)),'"', '&quot;') + '" Type = "' + REPLACE(CAST(deleted.[Type] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'D' , NULL , NULL , NULL , GETDATE() , SUSER_SNAME()
	FROM deleted

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudEquipAttrbt_Audit_Delete] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudEquipAttrbt_Audit_Delete]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudEquipAttrbt_Audit_Insert ON dbo.budEquipAttrbt
 AFTER INSERT
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on Dec  4 2013 10:52AM

 BEGIN TRY 

   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budEquipAttrbt' , '<KeyString EMGroup = "' + REPLACE(CAST(inserted.[EMGroup] AS VARCHAR(MAX)),'"', '&quot;') + '" Equipment = "' + REPLACE(CAST(inserted.[Equipment] AS VARCHAR(MAX)),'"', '&quot;') + '" Type = "' + REPLACE(CAST(inserted.[Type] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'A' , NULL , NULL , NULL , GETDATE() , SUSER_SNAME()
	FROM inserted

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudEquipAttrbt_Audit_Insert] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudEquipAttrbt_Audit_Insert]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudEquipAttrbt_Audit_Update ON dbo.budEquipAttrbt
 AFTER UPDATE 
 NOT FOR REPLICATION AS 
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on Dec  4 2013 10:52AM

 BEGIN TRY 

 IF UPDATE([EMGroup])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budEquipAttrbt' , '<KeyString EMGroup = "' + REPLACE(CAST(inserted.[EMGroup] AS VARCHAR(MAX)),'"', '&quot;') + '" Equipment = "' + REPLACE(CAST(inserted.[Equipment] AS VARCHAR(MAX)),'"', '&quot;') + '" Type = "' + REPLACE(CAST(inserted.[Type] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[EMGroup]' ,  CONVERT(VARCHAR(MAX), deleted.[EMGroup]) ,  CONVERT(VARCHAR(MAX), inserted.[EMGroup]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[EMGroup] <> deleted.[EMGroup]) OR (inserted.[EMGroup] IS NULL AND deleted.[EMGroup] IS NOT NULL) OR (inserted.[EMGroup] IS NOT NULL AND deleted.[EMGroup] IS NULL))



 END 

 IF UPDATE([Equipment])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budEquipAttrbt' , '<KeyString EMGroup = "' + REPLACE(CAST(inserted.[EMGroup] AS VARCHAR(MAX)),'"', '&quot;') + '" Equipment = "' + REPLACE(CAST(inserted.[Equipment] AS VARCHAR(MAX)),'"', '&quot;') + '" Type = "' + REPLACE(CAST(inserted.[Type] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[Equipment]' ,  CONVERT(VARCHAR(MAX), deleted.[Equipment]) ,  CONVERT(VARCHAR(MAX), inserted.[Equipment]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Equipment] <> deleted.[Equipment]) OR (inserted.[Equipment] IS NULL AND deleted.[Equipment] IS NOT NULL) OR (inserted.[Equipment] IS NOT NULL AND deleted.[Equipment] IS NULL))



 END 

 IF UPDATE([Type])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budEquipAttrbt' , '<KeyString EMGroup = "' + REPLACE(CAST(inserted.[EMGroup] AS VARCHAR(MAX)),'"', '&quot;') + '" Equipment = "' + REPLACE(CAST(inserted.[Equipment] AS VARCHAR(MAX)),'"', '&quot;') + '" Type = "' + REPLACE(CAST(inserted.[Type] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[Type]' ,  CONVERT(VARCHAR(MAX), deleted.[Type]) ,  CONVERT(VARCHAR(MAX), inserted.[Type]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Type] <> deleted.[Type]) OR (inserted.[Type] IS NULL AND deleted.[Type] IS NOT NULL) OR (inserted.[Type] IS NOT NULL AND deleted.[Type] IS NULL))



 END 

 IF UPDATE([Value])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budEquipAttrbt' , '<KeyString EMGroup = "' + REPLACE(CAST(inserted.[EMGroup] AS VARCHAR(MAX)),'"', '&quot;') + '" Equipment = "' + REPLACE(CAST(inserted.[Equipment] AS VARCHAR(MAX)),'"', '&quot;') + '" Type = "' + REPLACE(CAST(inserted.[Type] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[Value]' ,  CONVERT(VARCHAR(MAX), deleted.[Value]) ,  CONVERT(VARCHAR(MAX), inserted.[Value]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Value] <> deleted.[Value]) OR (inserted.[Value] IS NULL AND deleted.[Value] IS NOT NULL) OR (inserted.[Value] IS NOT NULL AND deleted.[Value] IS NULL))



 END 

 IF UPDATE([Notes])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budEquipAttrbt' , '<KeyString EMGroup = "' + REPLACE(CAST(inserted.[EMGroup] AS VARCHAR(MAX)),'"', '&quot;') + '" Equipment = "' + REPLACE(CAST(inserted.[Equipment] AS VARCHAR(MAX)),'"', '&quot;') + '" Type = "' + REPLACE(CAST(inserted.[Type] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[Notes]' ,  CONVERT(VARCHAR(MAX), deleted.[Notes]) ,  CONVERT(VARCHAR(MAX), inserted.[Notes]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Notes] <> deleted.[Notes]) OR (inserted.[Notes] IS NULL AND deleted.[Notes] IS NOT NULL) OR (inserted.[Notes] IS NOT NULL AND deleted.[Notes] IS NULL))



 END 

 IF UPDATE([UniqueAttchID])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budEquipAttrbt' , '<KeyString EMGroup = "' + REPLACE(CAST(inserted.[EMGroup] AS VARCHAR(MAX)),'"', '&quot;') + '" Equipment = "' + REPLACE(CAST(inserted.[Equipment] AS VARCHAR(MAX)),'"', '&quot;') + '" Type = "' + REPLACE(CAST(inserted.[Type] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[UniqueAttchID]' ,  CONVERT(VARCHAR(MAX), deleted.[UniqueAttchID]) ,  CONVERT(VARCHAR(MAX), inserted.[UniqueAttchID]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[UniqueAttchID] <> deleted.[UniqueAttchID]) OR (inserted.[UniqueAttchID] IS NULL AND deleted.[UniqueAttchID] IS NOT NULL) OR (inserted.[UniqueAttchID] IS NOT NULL AND deleted.[UniqueAttchID] IS NULL))



 END 

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudEquipAttrbt_Audit_Update] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudEquipAttrbt_Audit_Update]', 'last', 'update', null
GO
CREATE UNIQUE CLUSTERED INDEX [biudEquipAttrbt] ON [dbo].[budEquipAttrbt] ([EMGroup], [Equipment], [Type]) ON [PRIMARY]
GO