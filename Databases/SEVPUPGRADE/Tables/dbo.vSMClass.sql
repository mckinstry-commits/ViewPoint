CREATE TABLE [dbo].[vSMClass]
(
[SMClassID] [int] NOT NULL IDENTITY(1, 1),
[SMCo] [dbo].[bCompany] NOT NULL,
[Class] [varchar] (15) COLLATE Latin1_General_BIN NOT NULL,
[Description] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Active] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vSMClass_Active] DEFAULT ('Y'),
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMClass_Audit_Delete ON dbo.vSMClass
 AFTER DELETE
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspAuditCreateAuditTriggers

 BEGIN TRY 
DECLARE @HQMAKeys TABLE
	(
		  AuditID		bigint
		, KeyString		varchar(max)
	);
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMClass' , 
								'<KeyString Class = "' + REPLACE(CAST(ISNULL(deleted.[Class],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'Active' , 
								CONVERT(VARCHAR(MAX), deleted.[Active]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 4
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMClass' , 
								'<KeyString Class = "' + REPLACE(CAST(ISNULL(deleted.[Class],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'Class' , 
								CONVERT(VARCHAR(MAX), deleted.[Class]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 4
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMClass' , 
								'<KeyString Class = "' + REPLACE(CAST(ISNULL(deleted.[Class],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'Description' , 
								CONVERT(VARCHAR(MAX), deleted.[Description]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 4
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMClass' , 
								'<KeyString Class = "' + REPLACE(CAST(ISNULL(deleted.[Class],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'SMClassID' , 
								CONVERT(VARCHAR(MAX), deleted.[SMClassID]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 4
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMClass' , 
								'<KeyString Class = "' + REPLACE(CAST(ISNULL(deleted.[Class],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'SMCo' , 
								CONVERT(VARCHAR(MAX), deleted.[SMCo]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 4
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMClass' , 
								'<KeyString Class = "' + REPLACE(CAST(ISNULL(deleted.[Class],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'UniqueAttchID' , 
								CONVERT(VARCHAR(MAX), deleted.[UniqueAttchID]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 4

							 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT DISTINCT Keys.AuditID, 'bSMCo', d.SMCo, CAST(d.SMCo AS VARCHAR(30)), 'vSMClass'
				FROM deleted AS d
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString Class = "' + REPLACE(CAST(ISNULL(d.[Class],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(d.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMClass_Audit_Delete] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMClass_Audit_Delete]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMClass_Audit_Insert ON dbo.vSMClass
 AFTER INSERT
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspAuditTriggersCreate

 BEGIN TRY 
DECLARE @HQMAKeys TABLE
	(
		  AuditID		bigint
		, KeyString		varchar(max)
	);
-- log additions to the Active column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMClass' , 
								'<KeyString Class = "' + REPLACE(CAST(ISNULL(inserted.[Class],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Active' , 
								NULL , 
								Active , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 4

-- log additions to the Class column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMClass' , 
								'<KeyString Class = "' + REPLACE(CAST(ISNULL(inserted.[Class],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Class' , 
								NULL , 
								Class , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 4

-- log additions to the Description column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMClass' , 
								'<KeyString Class = "' + REPLACE(CAST(ISNULL(inserted.[Class],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Description' , 
								NULL , 
								Description , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 4

-- log additions to the SMClassID column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMClass' , 
								'<KeyString Class = "' + REPLACE(CAST(ISNULL(inserted.[Class],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'SMClassID' , 
								NULL , 
								SMClassID , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 4

-- log additions to the SMCo column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMClass' , 
								'<KeyString Class = "' + REPLACE(CAST(ISNULL(inserted.[Class],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'SMCo' , 
								NULL , 
								SMCo , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 4

-- log additions to the UniqueAttchID column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMClass' , 
								'<KeyString Class = "' + REPLACE(CAST(ISNULL(inserted.[Class],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'UniqueAttchID' , 
								NULL , 
								UniqueAttchID , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 4

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT DISTINCT Keys.AuditID, 'bSMCo', i.SMCo, CAST(i.SMCo AS VARCHAR(30)), 'vSMClass'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString Class = "' + REPLACE(CAST(ISNULL(i.[Class],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(i.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMClass_Audit_Insert] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMClass_Audit_Insert]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMClass_Audit_Update ON dbo.vSMClass
 AFTER UPDATE 
 NOT FOR REPLICATION AS 
 SET NOCOUNT ON 
 -- generated by vspAuditTriggersCreate

 BEGIN TRY 
DECLARE @HQMAKeys TABLE
	(
		  AuditID		bigint
		, KeyString		varchar(max)
	);
							IF UPDATE([Active])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMClass' , 								'<KeyString Class = "' + REPLACE(CAST(ISNULL(inserted.[Class],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'Active' , 								CONVERT(VARCHAR(MAX), deleted.[Active]) , 								CONVERT(VARCHAR(MAX), inserted.[Active]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMClassID] = deleted.[SMClassID] 
									AND ((inserted.[Active] <> deleted.[Active]) OR (inserted.[Active] IS NULL AND deleted.[Active] IS NOT NULL) OR (inserted.[Active] IS NOT NULL AND deleted.[Active] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 4

							END 

							IF UPDATE([Class])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMClass' , 								'<KeyString Class = "' + REPLACE(CAST(ISNULL(inserted.[Class],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'Class' , 								CONVERT(VARCHAR(MAX), deleted.[Class]) , 								CONVERT(VARCHAR(MAX), inserted.[Class]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMClassID] = deleted.[SMClassID] 
									AND ((inserted.[Class] <> deleted.[Class]) OR (inserted.[Class] IS NULL AND deleted.[Class] IS NOT NULL) OR (inserted.[Class] IS NOT NULL AND deleted.[Class] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 4

							END 

							IF UPDATE([Description])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMClass' , 								'<KeyString Class = "' + REPLACE(CAST(ISNULL(inserted.[Class],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'Description' , 								CONVERT(VARCHAR(MAX), deleted.[Description]) , 								CONVERT(VARCHAR(MAX), inserted.[Description]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMClassID] = deleted.[SMClassID] 
									AND ((inserted.[Description] <> deleted.[Description]) OR (inserted.[Description] IS NULL AND deleted.[Description] IS NOT NULL) OR (inserted.[Description] IS NOT NULL AND deleted.[Description] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 4

							END 

							IF UPDATE([SMClassID])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMClass' , 								'<KeyString Class = "' + REPLACE(CAST(ISNULL(inserted.[Class],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'SMClassID' , 								CONVERT(VARCHAR(MAX), deleted.[SMClassID]) , 								CONVERT(VARCHAR(MAX), inserted.[SMClassID]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMClassID] = deleted.[SMClassID] 
									AND ((inserted.[SMClassID] <> deleted.[SMClassID]) OR (inserted.[SMClassID] IS NULL AND deleted.[SMClassID] IS NOT NULL) OR (inserted.[SMClassID] IS NOT NULL AND deleted.[SMClassID] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 4

							END 

							IF UPDATE([SMCo])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMClass' , 								'<KeyString Class = "' + REPLACE(CAST(ISNULL(inserted.[Class],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'SMCo' , 								CONVERT(VARCHAR(MAX), deleted.[SMCo]) , 								CONVERT(VARCHAR(MAX), inserted.[SMCo]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMClassID] = deleted.[SMClassID] 
									AND ((inserted.[SMCo] <> deleted.[SMCo]) OR (inserted.[SMCo] IS NULL AND deleted.[SMCo] IS NOT NULL) OR (inserted.[SMCo] IS NOT NULL AND deleted.[SMCo] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 4

							END 

							IF UPDATE([UniqueAttchID])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMClass' , 								'<KeyString Class = "' + REPLACE(CAST(ISNULL(inserted.[Class],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'UniqueAttchID' , 								CONVERT(VARCHAR(MAX), deleted.[UniqueAttchID]) , 								CONVERT(VARCHAR(MAX), inserted.[UniqueAttchID]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMClassID] = deleted.[SMClassID] 
									AND ((inserted.[UniqueAttchID] <> deleted.[UniqueAttchID]) OR (inserted.[UniqueAttchID] IS NULL AND deleted.[UniqueAttchID] IS NOT NULL) OR (inserted.[UniqueAttchID] IS NOT NULL AND deleted.[UniqueAttchID] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 4

							END 

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT DISTINCT Keys.AuditID, 'bSMCo', i.SMCo, CAST(i.SMCo AS VARCHAR(30)), 'vSMClass'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString Class = "' + REPLACE(CAST(ISNULL(i.[Class],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(i.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />'


 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMClass_Audit_Update] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMClass_Audit_Update]', 'last', 'update', null
GO
ALTER TABLE [dbo].[vSMClass] ADD CONSTRAINT [PK_vSMClass] PRIMARY KEY CLUSTERED  ([SMClassID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMClass] ADD CONSTRAINT [IX_vSMClass] UNIQUE NONCLUSTERED  ([SMCo], [Class]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMClass] WITH NOCHECK ADD CONSTRAINT [FK_vSMClass_vSMCO] FOREIGN KEY ([SMCo]) REFERENCES [dbo].[vSMCO] ([SMCo])
GO
