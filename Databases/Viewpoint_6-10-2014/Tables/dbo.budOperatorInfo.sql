CREATE TABLE [dbo].[budOperatorInfo]
(
[Co] [dbo].[bCompany] NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[FCPIN] [bigint] NULL,
[PRCo] [dbo].[bCompany] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudOperatorInfo_Audit_Delete ON dbo.budOperatorInfo
 AFTER DELETE
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on Jan 27 2014  8:52AM

 BEGIN TRY 
DECLARE @HQMAKeys TABLE
	(
		  AuditID		bigint
		, KeyString		varchar(max)
	);
   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budOperatorInfo' , '<KeyString PRCo = "' + REPLACE(CAST(deleted.[PRCo] AS VARCHAR(MAX)),'"', '&quot;') + '" Employee = "' + REPLACE(CAST(deleted.[Employee] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , deleted.Co , 'D' , NULL , NULL , NULL , GETDATE() , SUSER_SNAME()
	FROM deleted
 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bEmployee', d.PRCo, CAST(d.Employee AS VARCHAR(30)), 'budOperatorInfo'
				FROM deleted AS d
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString PRCo = "' + REPLACE(CAST(d.[PRCo] AS VARCHAR(MAX)),'"', '&quot;') + '" Employee = "' + REPLACE(CAST(d.[Employee] AS VARCHAR(MAX)),'"', '&quot;') + '" />'
 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bPRCo', d.PRCo, CAST(d.PRCo AS VARCHAR(30)), 'budOperatorInfo'
				FROM deleted AS d
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString PRCo = "' + REPLACE(CAST(d.[PRCo] AS VARCHAR(MAX)),'"', '&quot;') + '" Employee = "' + REPLACE(CAST(d.[Employee] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudOperatorInfo_Audit_Delete] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudOperatorInfo_Audit_Delete]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudOperatorInfo_Audit_Insert ON dbo.budOperatorInfo
 AFTER INSERT
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on Jan 27 2014  8:52AM

 BEGIN TRY 
DECLARE @HQMAKeys TABLE
	(
		  AuditID		bigint
		, KeyString		varchar(max)
	);
   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budOperatorInfo' , '<KeyString PRCo = "' + REPLACE(CAST(inserted.[PRCo] AS VARCHAR(MAX)),'"', '&quot;') + '" Employee = "' + REPLACE(CAST(inserted.[Employee] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , ISNULL(inserted.Co, '') , 'A' , NULL , NULL , NULL , GETDATE() , SUSER_SNAME()
	FROM inserted
 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bEmployee', i.PRCo, CAST(i.Employee AS VARCHAR(30)), 'budOperatorInfo'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString PRCo = "' + REPLACE(CAST(i.[PRCo] AS VARCHAR(MAX)),'"', '&quot;') + '" Employee = "' + REPLACE(CAST(i.[Employee] AS VARCHAR(MAX)),'"', '&quot;') + '" />'
 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bPRCo', i.PRCo, CAST(i.PRCo AS VARCHAR(30)), 'budOperatorInfo'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString PRCo = "' + REPLACE(CAST(i.[PRCo] AS VARCHAR(MAX)),'"', '&quot;') + '" Employee = "' + REPLACE(CAST(i.[Employee] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudOperatorInfo_Audit_Insert] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudOperatorInfo_Audit_Insert]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudOperatorInfo_Audit_Update ON dbo.budOperatorInfo
 AFTER UPDATE 
 NOT FOR REPLICATION AS 
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on Jan 27 2014  8:52AM

 BEGIN TRY 
DECLARE @HQMAKeys TABLE
	(
		  AuditID		bigint
		, KeyString		varchar(max)
	);
 IF UPDATE([Co])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budOperatorInfo' , '<KeyString PRCo = "' + REPLACE(CAST(inserted.[PRCo] AS VARCHAR(MAX)),'"', '&quot;') + '" Employee = "' + REPLACE(CAST(inserted.[Employee] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[Co]' ,  CONVERT(VARCHAR(MAX), deleted.[Co]) ,  CONVERT(VARCHAR(MAX), inserted.[Co]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Co] <> deleted.[Co]) OR (inserted.[Co] IS NULL AND deleted.[Co] IS NOT NULL) OR (inserted.[Co] IS NOT NULL AND deleted.[Co] IS NULL))

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bEmployee', i.PRCo, CAST(i.Employee AS VARCHAR(30)), 'budOperatorInfo'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString PRCo = "' + REPLACE(CAST(i.[PRCo] AS VARCHAR(MAX)),'"', '&quot;') + '" Employee = "' + REPLACE(CAST(i.[Employee] AS VARCHAR(MAX)),'"', '&quot;') + '" />'
 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bPRCo', i.PRCo, CAST(i.PRCo AS VARCHAR(30)), 'budOperatorInfo'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString PRCo = "' + REPLACE(CAST(i.[PRCo] AS VARCHAR(MAX)),'"', '&quot;') + '" Employee = "' + REPLACE(CAST(i.[Employee] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 DELETE FROM @HQMAKeys; 
 END 

 IF UPDATE([Employee])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budOperatorInfo' , '<KeyString PRCo = "' + REPLACE(CAST(inserted.[PRCo] AS VARCHAR(MAX)),'"', '&quot;') + '" Employee = "' + REPLACE(CAST(inserted.[Employee] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[Employee]' ,  CONVERT(VARCHAR(MAX), deleted.[Employee]) ,  CONVERT(VARCHAR(MAX), inserted.[Employee]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Employee] <> deleted.[Employee]) OR (inserted.[Employee] IS NULL AND deleted.[Employee] IS NOT NULL) OR (inserted.[Employee] IS NOT NULL AND deleted.[Employee] IS NULL))

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bEmployee', i.PRCo, CAST(i.Employee AS VARCHAR(30)), 'budOperatorInfo'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString PRCo = "' + REPLACE(CAST(i.[PRCo] AS VARCHAR(MAX)),'"', '&quot;') + '" Employee = "' + REPLACE(CAST(i.[Employee] AS VARCHAR(MAX)),'"', '&quot;') + '" />'
 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bPRCo', i.PRCo, CAST(i.PRCo AS VARCHAR(30)), 'budOperatorInfo'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString PRCo = "' + REPLACE(CAST(i.[PRCo] AS VARCHAR(MAX)),'"', '&quot;') + '" Employee = "' + REPLACE(CAST(i.[Employee] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 DELETE FROM @HQMAKeys; 
 END 

 IF UPDATE([FCPIN])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budOperatorInfo' , '<KeyString PRCo = "' + REPLACE(CAST(inserted.[PRCo] AS VARCHAR(MAX)),'"', '&quot;') + '" Employee = "' + REPLACE(CAST(inserted.[Employee] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[FCPIN]' ,  CONVERT(VARCHAR(MAX), deleted.[FCPIN]) ,  CONVERT(VARCHAR(MAX), inserted.[FCPIN]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[FCPIN] <> deleted.[FCPIN]) OR (inserted.[FCPIN] IS NULL AND deleted.[FCPIN] IS NOT NULL) OR (inserted.[FCPIN] IS NOT NULL AND deleted.[FCPIN] IS NULL))

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bEmployee', i.PRCo, CAST(i.Employee AS VARCHAR(30)), 'budOperatorInfo'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString PRCo = "' + REPLACE(CAST(i.[PRCo] AS VARCHAR(MAX)),'"', '&quot;') + '" Employee = "' + REPLACE(CAST(i.[Employee] AS VARCHAR(MAX)),'"', '&quot;') + '" />'
 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bPRCo', i.PRCo, CAST(i.PRCo AS VARCHAR(30)), 'budOperatorInfo'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString PRCo = "' + REPLACE(CAST(i.[PRCo] AS VARCHAR(MAX)),'"', '&quot;') + '" Employee = "' + REPLACE(CAST(i.[Employee] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 DELETE FROM @HQMAKeys; 
 END 

 IF UPDATE([PRCo])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budOperatorInfo' , '<KeyString PRCo = "' + REPLACE(CAST(inserted.[PRCo] AS VARCHAR(MAX)),'"', '&quot;') + '" Employee = "' + REPLACE(CAST(inserted.[Employee] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[PRCo]' ,  CONVERT(VARCHAR(MAX), deleted.[PRCo]) ,  CONVERT(VARCHAR(MAX), inserted.[PRCo]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[PRCo] <> deleted.[PRCo]) OR (inserted.[PRCo] IS NULL AND deleted.[PRCo] IS NOT NULL) OR (inserted.[PRCo] IS NOT NULL AND deleted.[PRCo] IS NULL))

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bEmployee', i.PRCo, CAST(i.Employee AS VARCHAR(30)), 'budOperatorInfo'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString PRCo = "' + REPLACE(CAST(i.[PRCo] AS VARCHAR(MAX)),'"', '&quot;') + '" Employee = "' + REPLACE(CAST(i.[Employee] AS VARCHAR(MAX)),'"', '&quot;') + '" />'
 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bPRCo', i.PRCo, CAST(i.PRCo AS VARCHAR(30)), 'budOperatorInfo'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString PRCo = "' + REPLACE(CAST(i.[PRCo] AS VARCHAR(MAX)),'"', '&quot;') + '" Employee = "' + REPLACE(CAST(i.[Employee] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 DELETE FROM @HQMAKeys; 
 END 

 IF UPDATE([Notes])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budOperatorInfo' , '<KeyString PRCo = "' + REPLACE(CAST(inserted.[PRCo] AS VARCHAR(MAX)),'"', '&quot;') + '" Employee = "' + REPLACE(CAST(inserted.[Employee] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[Notes]' ,  CONVERT(VARCHAR(MAX), deleted.[Notes]) ,  CONVERT(VARCHAR(MAX), inserted.[Notes]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Notes] <> deleted.[Notes]) OR (inserted.[Notes] IS NULL AND deleted.[Notes] IS NOT NULL) OR (inserted.[Notes] IS NOT NULL AND deleted.[Notes] IS NULL))

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bEmployee', i.PRCo, CAST(i.Employee AS VARCHAR(30)), 'budOperatorInfo'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString PRCo = "' + REPLACE(CAST(i.[PRCo] AS VARCHAR(MAX)),'"', '&quot;') + '" Employee = "' + REPLACE(CAST(i.[Employee] AS VARCHAR(MAX)),'"', '&quot;') + '" />'
 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bPRCo', i.PRCo, CAST(i.PRCo AS VARCHAR(30)), 'budOperatorInfo'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString PRCo = "' + REPLACE(CAST(i.[PRCo] AS VARCHAR(MAX)),'"', '&quot;') + '" Employee = "' + REPLACE(CAST(i.[Employee] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 DELETE FROM @HQMAKeys; 
 END 

 IF UPDATE([UniqueAttchID])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budOperatorInfo' , '<KeyString PRCo = "' + REPLACE(CAST(inserted.[PRCo] AS VARCHAR(MAX)),'"', '&quot;') + '" Employee = "' + REPLACE(CAST(inserted.[Employee] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[UniqueAttchID]' ,  CONVERT(VARCHAR(MAX), deleted.[UniqueAttchID]) ,  CONVERT(VARCHAR(MAX), inserted.[UniqueAttchID]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[UniqueAttchID] <> deleted.[UniqueAttchID]) OR (inserted.[UniqueAttchID] IS NULL AND deleted.[UniqueAttchID] IS NOT NULL) OR (inserted.[UniqueAttchID] IS NOT NULL AND deleted.[UniqueAttchID] IS NULL))

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bEmployee', i.PRCo, CAST(i.Employee AS VARCHAR(30)), 'budOperatorInfo'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString PRCo = "' + REPLACE(CAST(i.[PRCo] AS VARCHAR(MAX)),'"', '&quot;') + '" Employee = "' + REPLACE(CAST(i.[Employee] AS VARCHAR(MAX)),'"', '&quot;') + '" />'
 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bPRCo', i.PRCo, CAST(i.PRCo AS VARCHAR(30)), 'budOperatorInfo'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString PRCo = "' + REPLACE(CAST(i.[PRCo] AS VARCHAR(MAX)),'"', '&quot;') + '" Employee = "' + REPLACE(CAST(i.[Employee] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 DELETE FROM @HQMAKeys; 
 END 

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudOperatorInfo_Audit_Update] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudOperatorInfo_Audit_Update]', 'last', 'update', null
GO
CREATE UNIQUE CLUSTERED INDEX [biudOperatorInfo] ON [dbo].[budOperatorInfo] ([Co], [PRCo], [Employee]) ON [PRIMARY]
GO