CREATE TABLE [dbo].[vSMAgreementServiceTask]
(
[SMAgreementServiceTaskID] [bigint] NOT NULL IDENTITY(1, 1),
[SMCo] [dbo].[bCompany] NOT NULL,
[Agreement] [varchar] (15) COLLATE Latin1_General_BIN NOT NULL,
[Revision] [int] NOT NULL,
[Service] [int] NOT NULL,
[Task] [int] NOT NULL,
[SMStandardTask] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[Name] [varchar] (60) COLLATE Latin1_General_BIN NOT NULL,
[Description] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[ServiceItem] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[Notes] [dbo].[bNotes] NULL,
[UniqueAttchID] [uniqueidentifier] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMAgreementServiceTask_Audit_Delete ON dbo.vSMAgreementServiceTask
 AFTER DELETE
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspAuditCreateAuditTriggers

 BEGIN TRY 

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
								
							SELECT
								'vSMAgreementServiceTask' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'Agreement' , 
								CONVERT(VARCHAR(MAX), deleted.[Agreement]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15
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
								
							SELECT
								'vSMAgreementServiceTask' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'Name' , 
								CONVERT(VARCHAR(MAX), deleted.[Name]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15
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
								
							SELECT
								'vSMAgreementServiceTask' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'Revision' , 
								CONVERT(VARCHAR(MAX), deleted.[Revision]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15
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
								
							SELECT
								'vSMAgreementServiceTask' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'SMAgreementServiceTaskID' , 
								CONVERT(VARCHAR(MAX), deleted.[SMAgreementServiceTaskID]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15
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
								
							SELECT
								'vSMAgreementServiceTask' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'SMCo' , 
								CONVERT(VARCHAR(MAX), deleted.[SMCo]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15
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
								
							SELECT
								'vSMAgreementServiceTask' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'SMStandardTask' , 
								CONVERT(VARCHAR(MAX), deleted.[SMStandardTask]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15
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
								
							SELECT
								'vSMAgreementServiceTask' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'Service' , 
								CONVERT(VARCHAR(MAX), deleted.[Service]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15
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
								
							SELECT
								'vSMAgreementServiceTask' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'ServiceItem' , 
								CONVERT(VARCHAR(MAX), deleted.[ServiceItem]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15
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
								
							SELECT
								'vSMAgreementServiceTask' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'Task' , 
								CONVERT(VARCHAR(MAX), deleted.[Task]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15
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
								
							SELECT
								'vSMAgreementServiceTask' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'UniqueAttchID' , 
								CONVERT(VARCHAR(MAX), deleted.[UniqueAttchID]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							
 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMAgreementServiceTask_Audit_Delete] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMAgreementServiceTask_Audit_Delete]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMAgreementServiceTask_Audit_Insert ON dbo.vSMAgreementServiceTask
 AFTER INSERT
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspAuditTriggersCreate

 BEGIN TRY 

-- log additions to the Agreement column
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
							
							SELECT 
								'vSMAgreementServiceTask' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Agreement' , 
								NULL , 
								[Agreement] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the Name column
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
							
							SELECT 
								'vSMAgreementServiceTask' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Name' , 
								NULL , 
								[Name] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the Revision column
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
							
							SELECT 
								'vSMAgreementServiceTask' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Revision' , 
								NULL , 
								[Revision] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the SMAgreementServiceTaskID column
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
							
							SELECT 
								'vSMAgreementServiceTask' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'SMAgreementServiceTaskID' , 
								NULL , 
								[SMAgreementServiceTaskID] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

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
							
							SELECT 
								'vSMAgreementServiceTask' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'SMCo' , 
								NULL , 
								[SMCo] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the SMStandardTask column
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
							
							SELECT 
								'vSMAgreementServiceTask' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'SMStandardTask' , 
								NULL , 
								[SMStandardTask] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the Service column
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
							
							SELECT 
								'vSMAgreementServiceTask' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Service' , 
								NULL , 
								[Service] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the ServiceItem column
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
							
							SELECT 
								'vSMAgreementServiceTask' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'ServiceItem' , 
								NULL , 
								[ServiceItem] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the Task column
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
							
							SELECT 
								'vSMAgreementServiceTask' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Task' , 
								NULL , 
								[Task] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

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
							
							SELECT 
								'vSMAgreementServiceTask' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'UniqueAttchID' , 
								NULL , 
								[UniqueAttchID] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15


 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMAgreementServiceTask_Audit_Insert] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMAgreementServiceTask_Audit_Insert]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMAgreementServiceTask_Audit_Update ON dbo.vSMAgreementServiceTask
 AFTER UPDATE 
 NOT FOR REPLICATION AS 
 SET NOCOUNT ON 
 -- generated by vspAuditTriggersCreate

 BEGIN TRY 

							IF UPDATE([Agreement])
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
								
								SELECT 							'vSMAgreementServiceTask' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'Agreement' , 								CONVERT(VARCHAR(MAX), deleted.[Agreement]) , 								CONVERT(VARCHAR(MAX), inserted.[Agreement]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceTaskID] = deleted.[SMAgreementServiceTaskID] 
									AND ((inserted.[Agreement] <> deleted.[Agreement]) OR (inserted.[Agreement] IS NULL AND deleted.[Agreement] IS NOT NULL) OR (inserted.[Agreement] IS NOT NULL AND deleted.[Agreement] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([Name])
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
								
								SELECT 							'vSMAgreementServiceTask' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'Name' , 								CONVERT(VARCHAR(MAX), deleted.[Name]) , 								CONVERT(VARCHAR(MAX), inserted.[Name]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceTaskID] = deleted.[SMAgreementServiceTaskID] 
									AND ((inserted.[Name] <> deleted.[Name]) OR (inserted.[Name] IS NULL AND deleted.[Name] IS NOT NULL) OR (inserted.[Name] IS NOT NULL AND deleted.[Name] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([Revision])
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
								
								SELECT 							'vSMAgreementServiceTask' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'Revision' , 								CONVERT(VARCHAR(MAX), deleted.[Revision]) , 								CONVERT(VARCHAR(MAX), inserted.[Revision]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceTaskID] = deleted.[SMAgreementServiceTaskID] 
									AND ((inserted.[Revision] <> deleted.[Revision]) OR (inserted.[Revision] IS NULL AND deleted.[Revision] IS NOT NULL) OR (inserted.[Revision] IS NOT NULL AND deleted.[Revision] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([SMAgreementServiceTaskID])
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
								
								SELECT 							'vSMAgreementServiceTask' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'SMAgreementServiceTaskID' , 								CONVERT(VARCHAR(MAX), deleted.[SMAgreementServiceTaskID]) , 								CONVERT(VARCHAR(MAX), inserted.[SMAgreementServiceTaskID]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceTaskID] = deleted.[SMAgreementServiceTaskID] 
									AND ((inserted.[SMAgreementServiceTaskID] <> deleted.[SMAgreementServiceTaskID]) OR (inserted.[SMAgreementServiceTaskID] IS NULL AND deleted.[SMAgreementServiceTaskID] IS NOT NULL) OR (inserted.[SMAgreementServiceTaskID] IS NOT NULL AND deleted.[SMAgreementServiceTaskID] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

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
								
								SELECT 							'vSMAgreementServiceTask' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'SMCo' , 								CONVERT(VARCHAR(MAX), deleted.[SMCo]) , 								CONVERT(VARCHAR(MAX), inserted.[SMCo]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceTaskID] = deleted.[SMAgreementServiceTaskID] 
									AND ((inserted.[SMCo] <> deleted.[SMCo]) OR (inserted.[SMCo] IS NULL AND deleted.[SMCo] IS NOT NULL) OR (inserted.[SMCo] IS NOT NULL AND deleted.[SMCo] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([SMStandardTask])
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
								
								SELECT 							'vSMAgreementServiceTask' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'SMStandardTask' , 								CONVERT(VARCHAR(MAX), deleted.[SMStandardTask]) , 								CONVERT(VARCHAR(MAX), inserted.[SMStandardTask]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceTaskID] = deleted.[SMAgreementServiceTaskID] 
									AND ((inserted.[SMStandardTask] <> deleted.[SMStandardTask]) OR (inserted.[SMStandardTask] IS NULL AND deleted.[SMStandardTask] IS NOT NULL) OR (inserted.[SMStandardTask] IS NOT NULL AND deleted.[SMStandardTask] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([Service])
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
								
								SELECT 							'vSMAgreementServiceTask' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'Service' , 								CONVERT(VARCHAR(MAX), deleted.[Service]) , 								CONVERT(VARCHAR(MAX), inserted.[Service]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceTaskID] = deleted.[SMAgreementServiceTaskID] 
									AND ((inserted.[Service] <> deleted.[Service]) OR (inserted.[Service] IS NULL AND deleted.[Service] IS NOT NULL) OR (inserted.[Service] IS NOT NULL AND deleted.[Service] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([ServiceItem])
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
								
								SELECT 							'vSMAgreementServiceTask' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'ServiceItem' , 								CONVERT(VARCHAR(MAX), deleted.[ServiceItem]) , 								CONVERT(VARCHAR(MAX), inserted.[ServiceItem]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceTaskID] = deleted.[SMAgreementServiceTaskID] 
									AND ((inserted.[ServiceItem] <> deleted.[ServiceItem]) OR (inserted.[ServiceItem] IS NULL AND deleted.[ServiceItem] IS NOT NULL) OR (inserted.[ServiceItem] IS NOT NULL AND deleted.[ServiceItem] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([Task])
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
								
								SELECT 							'vSMAgreementServiceTask' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'Task' , 								CONVERT(VARCHAR(MAX), deleted.[Task]) , 								CONVERT(VARCHAR(MAX), inserted.[Task]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceTaskID] = deleted.[SMAgreementServiceTaskID] 
									AND ((inserted.[Task] <> deleted.[Task]) OR (inserted.[Task] IS NULL AND deleted.[Task] IS NOT NULL) OR (inserted.[Task] IS NOT NULL AND deleted.[Task] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

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
								
								SELECT 							'vSMAgreementServiceTask' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'UniqueAttchID' , 								CONVERT(VARCHAR(MAX), deleted.[UniqueAttchID]) , 								CONVERT(VARCHAR(MAX), inserted.[UniqueAttchID]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceTaskID] = deleted.[SMAgreementServiceTaskID] 
									AND ((inserted.[UniqueAttchID] <> deleted.[UniqueAttchID]) OR (inserted.[UniqueAttchID] IS NULL AND deleted.[UniqueAttchID] IS NOT NULL) OR (inserted.[UniqueAttchID] IS NOT NULL AND deleted.[UniqueAttchID] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 



 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMAgreementServiceTask_Audit_Update] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMAgreementServiceTask_Audit_Update]', 'last', 'update', null
GO
ALTER TABLE [dbo].[vSMAgreementServiceTask] ADD CONSTRAINT [PK_vSMAgreementServiceTask] PRIMARY KEY CLUSTERED  ([SMAgreementServiceTaskID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMAgreementServiceTask] ADD CONSTRAINT [IX_vSMAgreementServiceTaskNameItem] UNIQUE NONCLUSTERED  ([SMCo], [Agreement], [Revision], [Service], [Name], [ServiceItem]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMAgreementServiceTask] ADD CONSTRAINT [IX_vSMAgreementServiceTask] UNIQUE NONCLUSTERED  ([SMCo], [Agreement], [Revision], [Service], [Task]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMAgreementServiceTask] WITH NOCHECK ADD CONSTRAINT [FK_vSMAgreementServiceTask_vSMAgreementService] FOREIGN KEY ([SMCo], [Agreement], [Revision], [Service]) REFERENCES [dbo].[vSMAgreementService] ([SMCo], [Agreement], [Revision], [Service]) ON DELETE CASCADE ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[vSMAgreementServiceTask] WITH NOCHECK ADD CONSTRAINT [FK_vSMAgreementServiceTask_vSMStandardTask] FOREIGN KEY ([SMCo], [SMStandardTask]) REFERENCES [dbo].[vSMStandardTask] ([SMCo], [SMStandardTask])
GO
ALTER TABLE [dbo].[vSMAgreementServiceTask] NOCHECK CONSTRAINT [FK_vSMAgreementServiceTask_vSMAgreementService]
GO
ALTER TABLE [dbo].[vSMAgreementServiceTask] NOCHECK CONSTRAINT [FK_vSMAgreementServiceTask_vSMStandardTask]
GO