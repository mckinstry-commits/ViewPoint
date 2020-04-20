CREATE TABLE [dbo].[budDeptReg]
(
[Dept] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[GLCo] [dbo].[bCompany] NULL,
[Region] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[RespPerson] [dbo].[bEmployee] NULL,
[Seq] [int] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[PMCo] [dbo].[bCompany] NULL,
[Type] [varchar] (1) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudDeptReg_Audit_Delete ON dbo.budDeptReg
 AFTER DELETE
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on Apr 25 2014  2:07PM

 BEGIN TRY 
DECLARE @HQMAKeys TABLE
	(
		  AuditID		bigint
		, KeyString		varchar(max)
	);
   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budDeptReg' , '<KeyString Seq = "' + REPLACE(CAST(deleted.[Seq] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'D' , NULL , NULL , NULL , GETDATE() , SUSER_SNAME()
	FROM deleted
 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bGLCo', d.GLCo, CAST(d.GLCo AS VARCHAR(30)), 'budDeptReg'
				FROM deleted AS d
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString Seq = "' + REPLACE(CAST(d.[Seq] AS VARCHAR(MAX)),'"', '&quot;') + '" />'
 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bPMCo', d.PMCo, CAST(d.PMCo AS VARCHAR(30)), 'budDeptReg'
				FROM deleted AS d
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString Seq = "' + REPLACE(CAST(d.[Seq] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudDeptReg_Audit_Delete] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudDeptReg_Audit_Delete]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudDeptReg_Audit_Insert ON dbo.budDeptReg
 AFTER INSERT
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on Apr 25 2014  2:07PM

 BEGIN TRY 
DECLARE @HQMAKeys TABLE
	(
		  AuditID		bigint
		, KeyString		varchar(max)
	);
   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budDeptReg' , '<KeyString Seq = "' + REPLACE(CAST(inserted.[Seq] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'A' , NULL , NULL , NULL , GETDATE() , SUSER_SNAME()
	FROM inserted
 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bGLCo', i.GLCo, CAST(i.GLCo AS VARCHAR(30)), 'budDeptReg'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString Seq = "' + REPLACE(CAST(i.[Seq] AS VARCHAR(MAX)),'"', '&quot;') + '" />'
 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bPMCo', i.PMCo, CAST(i.PMCo AS VARCHAR(30)), 'budDeptReg'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString Seq = "' + REPLACE(CAST(i.[Seq] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudDeptReg_Audit_Insert] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudDeptReg_Audit_Insert]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudDeptReg_Audit_Update ON dbo.budDeptReg
 AFTER UPDATE 
 NOT FOR REPLICATION AS 
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on Apr 25 2014  2:07PM

 BEGIN TRY 
DECLARE @HQMAKeys TABLE
	(
		  AuditID		bigint
		, KeyString		varchar(max)
	);
 IF UPDATE([Dept])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budDeptReg' , '<KeyString Seq = "' + REPLACE(CAST(inserted.[Seq] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[Dept]' ,  CONVERT(VARCHAR(MAX), deleted.[Dept]) ,  CONVERT(VARCHAR(MAX), inserted.[Dept]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Dept] <> deleted.[Dept]) OR (inserted.[Dept] IS NULL AND deleted.[Dept] IS NOT NULL) OR (inserted.[Dept] IS NOT NULL AND deleted.[Dept] IS NULL))

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bGLCo', i.GLCo, CAST(i.GLCo AS VARCHAR(30)), 'budDeptReg'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString Seq = "' + REPLACE(CAST(i.[Seq] AS VARCHAR(MAX)),'"', '&quot;') + '" />'
 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bPMCo', i.PMCo, CAST(i.PMCo AS VARCHAR(30)), 'budDeptReg'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString Seq = "' + REPLACE(CAST(i.[Seq] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 DELETE FROM @HQMAKeys; 
 END 

 IF UPDATE([GLCo])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budDeptReg' , '<KeyString Seq = "' + REPLACE(CAST(inserted.[Seq] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[GLCo]' ,  CONVERT(VARCHAR(MAX), deleted.[GLCo]) ,  CONVERT(VARCHAR(MAX), inserted.[GLCo]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[GLCo] <> deleted.[GLCo]) OR (inserted.[GLCo] IS NULL AND deleted.[GLCo] IS NOT NULL) OR (inserted.[GLCo] IS NOT NULL AND deleted.[GLCo] IS NULL))

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bGLCo', i.GLCo, CAST(i.GLCo AS VARCHAR(30)), 'budDeptReg'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString Seq = "' + REPLACE(CAST(i.[Seq] AS VARCHAR(MAX)),'"', '&quot;') + '" />'
 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bPMCo', i.PMCo, CAST(i.PMCo AS VARCHAR(30)), 'budDeptReg'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString Seq = "' + REPLACE(CAST(i.[Seq] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 DELETE FROM @HQMAKeys; 
 END 

 IF UPDATE([Region])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budDeptReg' , '<KeyString Seq = "' + REPLACE(CAST(inserted.[Seq] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[Region]' ,  CONVERT(VARCHAR(MAX), deleted.[Region]) ,  CONVERT(VARCHAR(MAX), inserted.[Region]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Region] <> deleted.[Region]) OR (inserted.[Region] IS NULL AND deleted.[Region] IS NOT NULL) OR (inserted.[Region] IS NOT NULL AND deleted.[Region] IS NULL))

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bGLCo', i.GLCo, CAST(i.GLCo AS VARCHAR(30)), 'budDeptReg'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString Seq = "' + REPLACE(CAST(i.[Seq] AS VARCHAR(MAX)),'"', '&quot;') + '" />'
 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bPMCo', i.PMCo, CAST(i.PMCo AS VARCHAR(30)), 'budDeptReg'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString Seq = "' + REPLACE(CAST(i.[Seq] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 DELETE FROM @HQMAKeys; 
 END 

 IF UPDATE([RespPerson])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budDeptReg' , '<KeyString Seq = "' + REPLACE(CAST(inserted.[Seq] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[RespPerson]' ,  CONVERT(VARCHAR(MAX), deleted.[RespPerson]) ,  CONVERT(VARCHAR(MAX), inserted.[RespPerson]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[RespPerson] <> deleted.[RespPerson]) OR (inserted.[RespPerson] IS NULL AND deleted.[RespPerson] IS NOT NULL) OR (inserted.[RespPerson] IS NOT NULL AND deleted.[RespPerson] IS NULL))

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bGLCo', i.GLCo, CAST(i.GLCo AS VARCHAR(30)), 'budDeptReg'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString Seq = "' + REPLACE(CAST(i.[Seq] AS VARCHAR(MAX)),'"', '&quot;') + '" />'
 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bPMCo', i.PMCo, CAST(i.PMCo AS VARCHAR(30)), 'budDeptReg'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString Seq = "' + REPLACE(CAST(i.[Seq] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 DELETE FROM @HQMAKeys; 
 END 

 IF UPDATE([Seq])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budDeptReg' , '<KeyString Seq = "' + REPLACE(CAST(inserted.[Seq] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[Seq]' ,  CONVERT(VARCHAR(MAX), deleted.[Seq]) ,  CONVERT(VARCHAR(MAX), inserted.[Seq]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Seq] <> deleted.[Seq]) OR (inserted.[Seq] IS NULL AND deleted.[Seq] IS NOT NULL) OR (inserted.[Seq] IS NOT NULL AND deleted.[Seq] IS NULL))

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bGLCo', i.GLCo, CAST(i.GLCo AS VARCHAR(30)), 'budDeptReg'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString Seq = "' + REPLACE(CAST(i.[Seq] AS VARCHAR(MAX)),'"', '&quot;') + '" />'
 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bPMCo', i.PMCo, CAST(i.PMCo AS VARCHAR(30)), 'budDeptReg'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString Seq = "' + REPLACE(CAST(i.[Seq] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 DELETE FROM @HQMAKeys; 
 END 

 IF UPDATE([UniqueAttchID])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budDeptReg' , '<KeyString Seq = "' + REPLACE(CAST(inserted.[Seq] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[UniqueAttchID]' ,  CONVERT(VARCHAR(MAX), deleted.[UniqueAttchID]) ,  CONVERT(VARCHAR(MAX), inserted.[UniqueAttchID]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[UniqueAttchID] <> deleted.[UniqueAttchID]) OR (inserted.[UniqueAttchID] IS NULL AND deleted.[UniqueAttchID] IS NOT NULL) OR (inserted.[UniqueAttchID] IS NOT NULL AND deleted.[UniqueAttchID] IS NULL))

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bGLCo', i.GLCo, CAST(i.GLCo AS VARCHAR(30)), 'budDeptReg'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString Seq = "' + REPLACE(CAST(i.[Seq] AS VARCHAR(MAX)),'"', '&quot;') + '" />'
 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bPMCo', i.PMCo, CAST(i.PMCo AS VARCHAR(30)), 'budDeptReg'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString Seq = "' + REPLACE(CAST(i.[Seq] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 DELETE FROM @HQMAKeys; 
 END 

 IF UPDATE([PMCo])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budDeptReg' , '<KeyString Seq = "' + REPLACE(CAST(inserted.[Seq] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[PMCo]' ,  CONVERT(VARCHAR(MAX), deleted.[PMCo]) ,  CONVERT(VARCHAR(MAX), inserted.[PMCo]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[PMCo] <> deleted.[PMCo]) OR (inserted.[PMCo] IS NULL AND deleted.[PMCo] IS NOT NULL) OR (inserted.[PMCo] IS NOT NULL AND deleted.[PMCo] IS NULL))

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bGLCo', i.GLCo, CAST(i.GLCo AS VARCHAR(30)), 'budDeptReg'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString Seq = "' + REPLACE(CAST(i.[Seq] AS VARCHAR(MAX)),'"', '&quot;') + '" />'
 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bPMCo', i.PMCo, CAST(i.PMCo AS VARCHAR(30)), 'budDeptReg'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString Seq = "' + REPLACE(CAST(i.[Seq] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 DELETE FROM @HQMAKeys; 
 END 

 IF UPDATE([Type])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budDeptReg' , '<KeyString Seq = "' + REPLACE(CAST(inserted.[Seq] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[Type]' ,  CONVERT(VARCHAR(MAX), deleted.[Type]) ,  CONVERT(VARCHAR(MAX), inserted.[Type]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Type] <> deleted.[Type]) OR (inserted.[Type] IS NULL AND deleted.[Type] IS NOT NULL) OR (inserted.[Type] IS NOT NULL AND deleted.[Type] IS NULL))

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bGLCo', i.GLCo, CAST(i.GLCo AS VARCHAR(30)), 'budDeptReg'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString Seq = "' + REPLACE(CAST(i.[Seq] AS VARCHAR(MAX)),'"', '&quot;') + '" />'
 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bPMCo', i.PMCo, CAST(i.PMCo AS VARCHAR(30)), 'budDeptReg'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString Seq = "' + REPLACE(CAST(i.[Seq] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 DELETE FROM @HQMAKeys; 
 END 

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudDeptReg_Audit_Update] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudDeptReg_Audit_Update]', 'last', 'update', null
GO
CREATE UNIQUE CLUSTERED INDEX [biudDeptReg] ON [dbo].[budDeptReg] ([Seq]) ON [PRIMARY]
GO
