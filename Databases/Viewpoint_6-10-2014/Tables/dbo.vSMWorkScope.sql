CREATE TABLE [dbo].[vSMWorkScope]
(
[SMCo] [dbo].[bCompany] NOT NULL,
[WorkScope] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Description] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[WorkScopeSummary] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[WorkScopeID] [int] NOT NULL IDENTITY(1, 1),
[PriorityName] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[Phase] [dbo].[bPhase] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMWorkScope_Audit_Delete ON dbo.vSMWorkScope
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
								'vSMWorkScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkScope = "' + REPLACE(CAST(ISNULL(deleted.[WorkScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'Description' , 
								CONVERT(VARCHAR(MAX), deleted.[Description]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 10
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
								'vSMWorkScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkScope = "' + REPLACE(CAST(ISNULL(deleted.[WorkScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'Phase' , 
								CONVERT(VARCHAR(MAX), deleted.[Phase]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 10
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
								'vSMWorkScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkScope = "' + REPLACE(CAST(ISNULL(deleted.[WorkScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'PhaseGroup' , 
								CONVERT(VARCHAR(MAX), deleted.[PhaseGroup]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 10
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
								'vSMWorkScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkScope = "' + REPLACE(CAST(ISNULL(deleted.[WorkScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'PriorityName' , 
								CONVERT(VARCHAR(MAX), deleted.[PriorityName]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 10
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
								'vSMWorkScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkScope = "' + REPLACE(CAST(ISNULL(deleted.[WorkScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'SMCo' , 
								CONVERT(VARCHAR(MAX), deleted.[SMCo]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 10
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
								'vSMWorkScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkScope = "' + REPLACE(CAST(ISNULL(deleted.[WorkScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'UniqueAttchID' , 
								CONVERT(VARCHAR(MAX), deleted.[UniqueAttchID]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 10
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
								'vSMWorkScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkScope = "' + REPLACE(CAST(ISNULL(deleted.[WorkScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'WorkScope' , 
								CONVERT(VARCHAR(MAX), deleted.[WorkScope]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 10
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
								'vSMWorkScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkScope = "' + REPLACE(CAST(ISNULL(deleted.[WorkScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'WorkScopeID' , 
								CONVERT(VARCHAR(MAX), deleted.[WorkScopeID]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 10

							
 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMWorkScope_Audit_Delete] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMWorkScope_Audit_Delete]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMWorkScope_Audit_Insert ON dbo.vSMWorkScope
 AFTER INSERT
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspAuditTriggersCreate

 BEGIN TRY 

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
							
							SELECT 
								'vSMWorkScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Description' , 
								NULL , 
								[Description] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 10

-- log additions to the Phase column
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
								'vSMWorkScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Phase' , 
								NULL , 
								[Phase] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 10

-- log additions to the PhaseGroup column
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
								'vSMWorkScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'PhaseGroup' , 
								NULL , 
								[PhaseGroup] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 10

-- log additions to the PriorityName column
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
								'vSMWorkScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'PriorityName' , 
								NULL , 
								[PriorityName] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 10

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
								'vSMWorkScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'SMCo' , 
								NULL , 
								[SMCo] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 10

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
								'vSMWorkScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'UniqueAttchID' , 
								NULL , 
								[UniqueAttchID] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 10

-- log additions to the WorkScope column
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
								'vSMWorkScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'WorkScope' , 
								NULL , 
								[WorkScope] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 10

-- log additions to the WorkScopeID column
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
								'vSMWorkScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'WorkScopeID' , 
								NULL , 
								[WorkScopeID] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 10


 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMWorkScope_Audit_Insert] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMWorkScope_Audit_Insert]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMWorkScope_Audit_Update ON dbo.vSMWorkScope
 AFTER UPDATE 
 NOT FOR REPLICATION AS 
 SET NOCOUNT ON 
 -- generated by vspAuditTriggersCreate

 BEGIN TRY 

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
								
								SELECT 							'vSMWorkScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'Description' , 								CONVERT(VARCHAR(MAX), deleted.[Description]) , 								CONVERT(VARCHAR(MAX), inserted.[Description]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[WorkScopeID] = deleted.[WorkScopeID] 
									AND ((inserted.[Description] <> deleted.[Description]) OR (inserted.[Description] IS NULL AND deleted.[Description] IS NOT NULL) OR (inserted.[Description] IS NOT NULL AND deleted.[Description] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 10

							END 

							IF UPDATE([Phase])
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
								
								SELECT 							'vSMWorkScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'Phase' , 								CONVERT(VARCHAR(MAX), deleted.[Phase]) , 								CONVERT(VARCHAR(MAX), inserted.[Phase]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[WorkScopeID] = deleted.[WorkScopeID] 
									AND ((inserted.[Phase] <> deleted.[Phase]) OR (inserted.[Phase] IS NULL AND deleted.[Phase] IS NOT NULL) OR (inserted.[Phase] IS NOT NULL AND deleted.[Phase] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 10

							END 

							IF UPDATE([PhaseGroup])
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
								
								SELECT 							'vSMWorkScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'PhaseGroup' , 								CONVERT(VARCHAR(MAX), deleted.[PhaseGroup]) , 								CONVERT(VARCHAR(MAX), inserted.[PhaseGroup]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[WorkScopeID] = deleted.[WorkScopeID] 
									AND ((inserted.[PhaseGroup] <> deleted.[PhaseGroup]) OR (inserted.[PhaseGroup] IS NULL AND deleted.[PhaseGroup] IS NOT NULL) OR (inserted.[PhaseGroup] IS NOT NULL AND deleted.[PhaseGroup] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 10

							END 

							IF UPDATE([PriorityName])
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
								
								SELECT 							'vSMWorkScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'PriorityName' , 								CONVERT(VARCHAR(MAX), deleted.[PriorityName]) , 								CONVERT(VARCHAR(MAX), inserted.[PriorityName]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[WorkScopeID] = deleted.[WorkScopeID] 
									AND ((inserted.[PriorityName] <> deleted.[PriorityName]) OR (inserted.[PriorityName] IS NULL AND deleted.[PriorityName] IS NOT NULL) OR (inserted.[PriorityName] IS NOT NULL AND deleted.[PriorityName] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 10

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
								
								SELECT 							'vSMWorkScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'SMCo' , 								CONVERT(VARCHAR(MAX), deleted.[SMCo]) , 								CONVERT(VARCHAR(MAX), inserted.[SMCo]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[WorkScopeID] = deleted.[WorkScopeID] 
									AND ((inserted.[SMCo] <> deleted.[SMCo]) OR (inserted.[SMCo] IS NULL AND deleted.[SMCo] IS NOT NULL) OR (inserted.[SMCo] IS NOT NULL AND deleted.[SMCo] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 10

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
								
								SELECT 							'vSMWorkScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'UniqueAttchID' , 								CONVERT(VARCHAR(MAX), deleted.[UniqueAttchID]) , 								CONVERT(VARCHAR(MAX), inserted.[UniqueAttchID]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[WorkScopeID] = deleted.[WorkScopeID] 
									AND ((inserted.[UniqueAttchID] <> deleted.[UniqueAttchID]) OR (inserted.[UniqueAttchID] IS NULL AND deleted.[UniqueAttchID] IS NOT NULL) OR (inserted.[UniqueAttchID] IS NOT NULL AND deleted.[UniqueAttchID] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 10

							END 

							IF UPDATE([WorkScope])
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
								
								SELECT 							'vSMWorkScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'WorkScope' , 								CONVERT(VARCHAR(MAX), deleted.[WorkScope]) , 								CONVERT(VARCHAR(MAX), inserted.[WorkScope]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[WorkScopeID] = deleted.[WorkScopeID] 
									AND ((inserted.[WorkScope] <> deleted.[WorkScope]) OR (inserted.[WorkScope] IS NULL AND deleted.[WorkScope] IS NOT NULL) OR (inserted.[WorkScope] IS NOT NULL AND deleted.[WorkScope] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 10

							END 

							IF UPDATE([WorkScopeID])
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
								
								SELECT 							'vSMWorkScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'WorkScopeID' , 								CONVERT(VARCHAR(MAX), deleted.[WorkScopeID]) , 								CONVERT(VARCHAR(MAX), inserted.[WorkScopeID]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[WorkScopeID] = deleted.[WorkScopeID] 
									AND ((inserted.[WorkScopeID] <> deleted.[WorkScopeID]) OR (inserted.[WorkScopeID] IS NULL AND deleted.[WorkScopeID] IS NOT NULL) OR (inserted.[WorkScopeID] IS NOT NULL AND deleted.[WorkScopeID] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 10

							END 



 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMWorkScope_Audit_Update] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMWorkScope_Audit_Update]', 'last', 'update', null
GO
ALTER TABLE [dbo].[vSMWorkScope] ADD CONSTRAINT [PK_SMScopes] PRIMARY KEY CLUSTERED  ([WorkScopeID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMWorkScope] ADD CONSTRAINT [IX_vSMWorkScope_SMCo_WorkScope] UNIQUE NONCLUSTERED  ([SMCo], [WorkScope]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMWorkScope] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkScope_bJCPM] FOREIGN KEY ([PhaseGroup], [Phase]) REFERENCES [dbo].[bJCPM] ([PhaseGroup], [Phase])
GO
ALTER TABLE [dbo].[vSMWorkScope] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkScope_vSMScopePriority] FOREIGN KEY ([PriorityName]) REFERENCES [dbo].[vSMScopePriority] ([PriorityName])
GO
ALTER TABLE [dbo].[vSMWorkScope] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkScope_vSMCO] FOREIGN KEY ([SMCo]) REFERENCES [dbo].[vSMCO] ([SMCo])
GO
ALTER TABLE [dbo].[vSMWorkScope] NOCHECK CONSTRAINT [FK_vSMWorkScope_bJCPM]
GO
ALTER TABLE [dbo].[vSMWorkScope] NOCHECK CONSTRAINT [FK_vSMWorkScope_vSMScopePriority]
GO
ALTER TABLE [dbo].[vSMWorkScope] NOCHECK CONSTRAINT [FK_vSMWorkScope_vSMCO]
GO
