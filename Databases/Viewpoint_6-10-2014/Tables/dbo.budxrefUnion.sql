CREATE TABLE [dbo].[budxrefUnion]
(
[Company] [dbo].[bCompany] NOT NULL,
[CMSUnion] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[CMSClass] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[CMSType] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Craft] [dbo].[bCraft] NULL,
[Class] [dbo].[bClass] NULL,
[Description] [dbo].[bDesc] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudxrefUnion_Audit_Delete ON dbo.budxrefUnion
 AFTER DELETE
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on Mar 24 2014 10:17AM

 BEGIN TRY 
DECLARE @HQMAKeys TABLE
	(
		  AuditID		bigint
		, KeyString		varchar(max)
	);
   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budxrefUnion' , '<KeyString Company = "' + REPLACE(CAST(deleted.[Company] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Union = "' + REPLACE(CAST(deleted.[CMSUnion] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Class = "' + REPLACE(CAST(deleted.[CMSClass] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Type = "' + REPLACE(CAST(deleted.[CMSType] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'D' , NULL , NULL , NULL , GETDATE() , SUSER_SNAME()
	FROM deleted
 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bHQCo', d.Company, CAST(d.Company AS VARCHAR(30)), 'budxrefUnion'
				FROM deleted AS d
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString Company = "' + REPLACE(CAST(d.[Company] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Union = "' + REPLACE(CAST(d.[CMSUnion] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Class = "' + REPLACE(CAST(d.[CMSClass] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Type = "' + REPLACE(CAST(d.[CMSType] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudxrefUnion_Audit_Delete] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudxrefUnion_Audit_Delete]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudxrefUnion_Audit_Insert ON dbo.budxrefUnion
 AFTER INSERT
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on Mar 24 2014 10:17AM

 BEGIN TRY 
DECLARE @HQMAKeys TABLE
	(
		  AuditID		bigint
		, KeyString		varchar(max)
	);
   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budxrefUnion' , '<KeyString Company = "' + REPLACE(CAST(inserted.[Company] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Union = "' + REPLACE(CAST(inserted.[CMSUnion] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Class = "' + REPLACE(CAST(inserted.[CMSClass] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Type = "' + REPLACE(CAST(inserted.[CMSType] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'A' , NULL , NULL , NULL , GETDATE() , SUSER_SNAME()
	FROM inserted
 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bHQCo', i.Company, CAST(i.Company AS VARCHAR(30)), 'budxrefUnion'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString Company = "' + REPLACE(CAST(i.[Company] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Union = "' + REPLACE(CAST(i.[CMSUnion] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Class = "' + REPLACE(CAST(i.[CMSClass] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Type = "' + REPLACE(CAST(i.[CMSType] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudxrefUnion_Audit_Insert] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudxrefUnion_Audit_Insert]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudxrefUnion_Audit_Update ON dbo.budxrefUnion
 AFTER UPDATE 
 NOT FOR REPLICATION AS 
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on Mar 24 2014 10:17AM

 BEGIN TRY 
DECLARE @HQMAKeys TABLE
	(
		  AuditID		bigint
		, KeyString		varchar(max)
	);
 IF UPDATE([Company])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budxrefUnion' , '<KeyString Company = "' + REPLACE(CAST(inserted.[Company] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Union = "' + REPLACE(CAST(inserted.[CMSUnion] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Class = "' + REPLACE(CAST(inserted.[CMSClass] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Type = "' + REPLACE(CAST(inserted.[CMSType] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[Company]' ,  CONVERT(VARCHAR(MAX), deleted.[Company]) ,  CONVERT(VARCHAR(MAX), inserted.[Company]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Company] <> deleted.[Company]) OR (inserted.[Company] IS NULL AND deleted.[Company] IS NOT NULL) OR (inserted.[Company] IS NOT NULL AND deleted.[Company] IS NULL))

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bHQCo', i.Company, CAST(i.Company AS VARCHAR(30)), 'budxrefUnion'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString Company = "' + REPLACE(CAST(i.[Company] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Union = "' + REPLACE(CAST(i.[CMSUnion] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Class = "' + REPLACE(CAST(i.[CMSClass] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Type = "' + REPLACE(CAST(i.[CMSType] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 DELETE FROM @HQMAKeys; 
 END 

 IF UPDATE([CMSUnion])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budxrefUnion' , '<KeyString Company = "' + REPLACE(CAST(inserted.[Company] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Union = "' + REPLACE(CAST(inserted.[CMSUnion] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Class = "' + REPLACE(CAST(inserted.[CMSClass] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Type = "' + REPLACE(CAST(inserted.[CMSType] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[CMSUnion]' ,  CONVERT(VARCHAR(MAX), deleted.[CMSUnion]) ,  CONVERT(VARCHAR(MAX), inserted.[CMSUnion]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[CMSUnion] <> deleted.[CMSUnion]) OR (inserted.[CMSUnion] IS NULL AND deleted.[CMSUnion] IS NOT NULL) OR (inserted.[CMSUnion] IS NOT NULL AND deleted.[CMSUnion] IS NULL))

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bHQCo', i.Company, CAST(i.Company AS VARCHAR(30)), 'budxrefUnion'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString Company = "' + REPLACE(CAST(i.[Company] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Union = "' + REPLACE(CAST(i.[CMSUnion] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Class = "' + REPLACE(CAST(i.[CMSClass] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Type = "' + REPLACE(CAST(i.[CMSType] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 DELETE FROM @HQMAKeys; 
 END 

 IF UPDATE([CMSClass])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budxrefUnion' , '<KeyString Company = "' + REPLACE(CAST(inserted.[Company] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Union = "' + REPLACE(CAST(inserted.[CMSUnion] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Class = "' + REPLACE(CAST(inserted.[CMSClass] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Type = "' + REPLACE(CAST(inserted.[CMSType] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[CMSClass]' ,  CONVERT(VARCHAR(MAX), deleted.[CMSClass]) ,  CONVERT(VARCHAR(MAX), inserted.[CMSClass]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[CMSClass] <> deleted.[CMSClass]) OR (inserted.[CMSClass] IS NULL AND deleted.[CMSClass] IS NOT NULL) OR (inserted.[CMSClass] IS NOT NULL AND deleted.[CMSClass] IS NULL))

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bHQCo', i.Company, CAST(i.Company AS VARCHAR(30)), 'budxrefUnion'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString Company = "' + REPLACE(CAST(i.[Company] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Union = "' + REPLACE(CAST(i.[CMSUnion] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Class = "' + REPLACE(CAST(i.[CMSClass] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Type = "' + REPLACE(CAST(i.[CMSType] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 DELETE FROM @HQMAKeys; 
 END 

 IF UPDATE([CMSType])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budxrefUnion' , '<KeyString Company = "' + REPLACE(CAST(inserted.[Company] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Union = "' + REPLACE(CAST(inserted.[CMSUnion] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Class = "' + REPLACE(CAST(inserted.[CMSClass] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Type = "' + REPLACE(CAST(inserted.[CMSType] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[CMSType]' ,  CONVERT(VARCHAR(MAX), deleted.[CMSType]) ,  CONVERT(VARCHAR(MAX), inserted.[CMSType]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[CMSType] <> deleted.[CMSType]) OR (inserted.[CMSType] IS NULL AND deleted.[CMSType] IS NOT NULL) OR (inserted.[CMSType] IS NOT NULL AND deleted.[CMSType] IS NULL))

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bHQCo', i.Company, CAST(i.Company AS VARCHAR(30)), 'budxrefUnion'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString Company = "' + REPLACE(CAST(i.[Company] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Union = "' + REPLACE(CAST(i.[CMSUnion] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Class = "' + REPLACE(CAST(i.[CMSClass] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Type = "' + REPLACE(CAST(i.[CMSType] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 DELETE FROM @HQMAKeys; 
 END 

 IF UPDATE([Craft])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budxrefUnion' , '<KeyString Company = "' + REPLACE(CAST(inserted.[Company] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Union = "' + REPLACE(CAST(inserted.[CMSUnion] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Class = "' + REPLACE(CAST(inserted.[CMSClass] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Type = "' + REPLACE(CAST(inserted.[CMSType] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[Craft]' ,  CONVERT(VARCHAR(MAX), deleted.[Craft]) ,  CONVERT(VARCHAR(MAX), inserted.[Craft]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Craft] <> deleted.[Craft]) OR (inserted.[Craft] IS NULL AND deleted.[Craft] IS NOT NULL) OR (inserted.[Craft] IS NOT NULL AND deleted.[Craft] IS NULL))

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bHQCo', i.Company, CAST(i.Company AS VARCHAR(30)), 'budxrefUnion'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString Company = "' + REPLACE(CAST(i.[Company] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Union = "' + REPLACE(CAST(i.[CMSUnion] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Class = "' + REPLACE(CAST(i.[CMSClass] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Type = "' + REPLACE(CAST(i.[CMSType] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 DELETE FROM @HQMAKeys; 
 END 

 IF UPDATE([Class])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budxrefUnion' , '<KeyString Company = "' + REPLACE(CAST(inserted.[Company] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Union = "' + REPLACE(CAST(inserted.[CMSUnion] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Class = "' + REPLACE(CAST(inserted.[CMSClass] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Type = "' + REPLACE(CAST(inserted.[CMSType] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[Class]' ,  CONVERT(VARCHAR(MAX), deleted.[Class]) ,  CONVERT(VARCHAR(MAX), inserted.[Class]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Class] <> deleted.[Class]) OR (inserted.[Class] IS NULL AND deleted.[Class] IS NOT NULL) OR (inserted.[Class] IS NOT NULL AND deleted.[Class] IS NULL))

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bHQCo', i.Company, CAST(i.Company AS VARCHAR(30)), 'budxrefUnion'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString Company = "' + REPLACE(CAST(i.[Company] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Union = "' + REPLACE(CAST(i.[CMSUnion] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Class = "' + REPLACE(CAST(i.[CMSClass] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Type = "' + REPLACE(CAST(i.[CMSType] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 DELETE FROM @HQMAKeys; 
 END 

 IF UPDATE([Description])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budxrefUnion' , '<KeyString Company = "' + REPLACE(CAST(inserted.[Company] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Union = "' + REPLACE(CAST(inserted.[CMSUnion] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Class = "' + REPLACE(CAST(inserted.[CMSClass] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Type = "' + REPLACE(CAST(inserted.[CMSType] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[Description]' ,  CONVERT(VARCHAR(MAX), deleted.[Description]) ,  CONVERT(VARCHAR(MAX), inserted.[Description]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Description] <> deleted.[Description]) OR (inserted.[Description] IS NULL AND deleted.[Description] IS NOT NULL) OR (inserted.[Description] IS NOT NULL AND deleted.[Description] IS NULL))

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bHQCo', i.Company, CAST(i.Company AS VARCHAR(30)), 'budxrefUnion'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString Company = "' + REPLACE(CAST(i.[Company] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Union = "' + REPLACE(CAST(i.[CMSUnion] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Class = "' + REPLACE(CAST(i.[CMSClass] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Type = "' + REPLACE(CAST(i.[CMSType] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 DELETE FROM @HQMAKeys; 
 END 

 IF UPDATE([UniqueAttchID])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budxrefUnion' , '<KeyString Company = "' + REPLACE(CAST(inserted.[Company] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Union = "' + REPLACE(CAST(inserted.[CMSUnion] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Class = "' + REPLACE(CAST(inserted.[CMSClass] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Type = "' + REPLACE(CAST(inserted.[CMSType] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , '' , 'C' , '[UniqueAttchID]' ,  CONVERT(VARCHAR(MAX), deleted.[UniqueAttchID]) ,  CONVERT(VARCHAR(MAX), inserted.[UniqueAttchID]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[UniqueAttchID] <> deleted.[UniqueAttchID]) OR (inserted.[UniqueAttchID] IS NULL AND deleted.[UniqueAttchID] IS NOT NULL) OR (inserted.[UniqueAttchID] IS NOT NULL AND deleted.[UniqueAttchID] IS NULL))

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bHQCo', i.Company, CAST(i.Company AS VARCHAR(30)), 'budxrefUnion'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString Company = "' + REPLACE(CAST(i.[Company] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Union = "' + REPLACE(CAST(i.[CMSUnion] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Class = "' + REPLACE(CAST(i.[CMSClass] AS VARCHAR(MAX)),'"', '&quot;') + '" CMS Type = "' + REPLACE(CAST(i.[CMSType] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 DELETE FROM @HQMAKeys; 
 END 

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudxrefUnion_Audit_Update] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudxrefUnion_Audit_Update]', 'last', 'update', null
GO
CREATE UNIQUE CLUSTERED INDEX [biudxrefUnion] ON [dbo].[budxrefUnion] ([Company], [CMSUnion], [CMSClass], [CMSType]) ON [PRIMARY]
GO
