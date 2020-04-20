CREATE TABLE [dbo].[vSLClaimHeader]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[SLCo] [dbo].[bCompany] NOT NULL,
[SL] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[ClaimNo] [int] NOT NULL,
[Description] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ClaimDate] [dbo].[bDate] NULL,
[RecvdClaimDate] [dbo].[bDate] NULL,
[InvoiceDate] [dbo].[bDate] NULL,
[APRef] [dbo].[bAPReference] NULL,
[CertifyDate] [dbo].[bDate] NULL,
[ClaimStatus] [tinyint] NULL CONSTRAINT [DF_vSLClaimHeader_ClaimStatus] DEFAULT ((10)),
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[InvoiceDesc] [dbo].[bDesc] NULL,
[CertifiedBy] [dbo].[bVPUserName] NULL,
[ApproveRetention] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vSLClaimHeader_ApproveRetention] DEFAULT ((0))
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[vSLClaimHeader] WITH NOCHECK ADD
CONSTRAINT [FK_vSLClaimHeader_bSLHD] FOREIGN KEY ([SLCo], [SL]) REFERENCES [dbo].[bSLHD] ([SLCo], [SL])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSLClaimHeader_Audit_Delete ON dbo.vSLClaimHeader
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
								'vSLClaimHeader' , 
								'<KeyString ClaimNo = "' + REPLACE(CAST(ISNULL(deleted.[ClaimNo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SL = "' + REPLACE(CAST(ISNULL(deleted.[SL],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SLCo = "' + REPLACE(CAST(ISNULL(deleted.[SLCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SLCo , 
								'D' , 
								'ClaimNo' , 
								CONVERT(VARCHAR(MAX), deleted.[ClaimNo]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								
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
								'vSLClaimHeader' , 
								'<KeyString ClaimNo = "' + REPLACE(CAST(ISNULL(deleted.[ClaimNo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SL = "' + REPLACE(CAST(ISNULL(deleted.[SL],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SLCo = "' + REPLACE(CAST(ISNULL(deleted.[SLCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SLCo , 
								'D' , 
								'SL' , 
								CONVERT(VARCHAR(MAX), deleted.[SL]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								
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
								'vSLClaimHeader' , 
								'<KeyString ClaimNo = "' + REPLACE(CAST(ISNULL(deleted.[ClaimNo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SL = "' + REPLACE(CAST(ISNULL(deleted.[SL],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SLCo = "' + REPLACE(CAST(ISNULL(deleted.[SLCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SLCo , 
								'D' , 
								'SLCo' , 
								CONVERT(VARCHAR(MAX), deleted.[SLCo]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								

							
 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSLClaimHeader_Audit_Delete] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSLClaimHeader_Audit_Delete]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSLClaimHeader_Audit_Insert ON dbo.vSLClaimHeader
 AFTER INSERT
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspAuditTriggersCreate

 BEGIN TRY 

-- log additions to the APRef column
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
								'vSLClaimHeader' , 
								'<KeyString ClaimNo = "' + REPLACE(CAST(ISNULL(inserted.[ClaimNo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SL = "' + REPLACE(CAST(ISNULL(inserted.[SL],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SLCo = "' + REPLACE(CAST(ISNULL(inserted.[SLCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SLCo, '') , 
								'A' , 
								'APRef' , 
								NULL , 
								APRef , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								

-- log additions to the ApproveRetention column
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
								'vSLClaimHeader' , 
								'<KeyString ClaimNo = "' + REPLACE(CAST(ISNULL(inserted.[ClaimNo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SL = "' + REPLACE(CAST(ISNULL(inserted.[SL],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SLCo = "' + REPLACE(CAST(ISNULL(inserted.[SLCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SLCo, '') , 
								'A' , 
								'ApproveRetention' , 
								NULL , 
								ApproveRetention , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								

-- log additions to the CertifiedBy column
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
								'vSLClaimHeader' , 
								'<KeyString ClaimNo = "' + REPLACE(CAST(ISNULL(inserted.[ClaimNo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SL = "' + REPLACE(CAST(ISNULL(inserted.[SL],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SLCo = "' + REPLACE(CAST(ISNULL(inserted.[SLCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SLCo, '') , 
								'A' , 
								'CertifiedBy' , 
								NULL , 
								CertifiedBy , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								

-- log additions to the CertifyDate column
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
								'vSLClaimHeader' , 
								'<KeyString ClaimNo = "' + REPLACE(CAST(ISNULL(inserted.[ClaimNo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SL = "' + REPLACE(CAST(ISNULL(inserted.[SL],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SLCo = "' + REPLACE(CAST(ISNULL(inserted.[SLCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SLCo, '') , 
								'A' , 
								'CertifyDate' , 
								NULL , 
								CertifyDate , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								

-- log additions to the ClaimDate column
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
								'vSLClaimHeader' , 
								'<KeyString ClaimNo = "' + REPLACE(CAST(ISNULL(inserted.[ClaimNo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SL = "' + REPLACE(CAST(ISNULL(inserted.[SL],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SLCo = "' + REPLACE(CAST(ISNULL(inserted.[SLCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SLCo, '') , 
								'A' , 
								'ClaimDate' , 
								NULL , 
								ClaimDate , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								

-- log additions to the ClaimNo column
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
								'vSLClaimHeader' , 
								'<KeyString ClaimNo = "' + REPLACE(CAST(ISNULL(inserted.[ClaimNo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SL = "' + REPLACE(CAST(ISNULL(inserted.[SL],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SLCo = "' + REPLACE(CAST(ISNULL(inserted.[SLCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SLCo, '') , 
								'A' , 
								'ClaimNo' , 
								NULL , 
								ClaimNo , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								

-- log additions to the ClaimStatus column
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
								'vSLClaimHeader' , 
								'<KeyString ClaimNo = "' + REPLACE(CAST(ISNULL(inserted.[ClaimNo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SL = "' + REPLACE(CAST(ISNULL(inserted.[SL],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SLCo = "' + REPLACE(CAST(ISNULL(inserted.[SLCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SLCo, '') , 
								'A' , 
								'ClaimStatus' , 
								NULL , 
								ClaimStatus , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								

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
								'vSLClaimHeader' , 
								'<KeyString ClaimNo = "' + REPLACE(CAST(ISNULL(inserted.[ClaimNo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SL = "' + REPLACE(CAST(ISNULL(inserted.[SL],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SLCo = "' + REPLACE(CAST(ISNULL(inserted.[SLCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SLCo, '') , 
								'A' , 
								'Description' , 
								NULL , 
								Description , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								

-- log additions to the InvoiceDate column
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
								'vSLClaimHeader' , 
								'<KeyString ClaimNo = "' + REPLACE(CAST(ISNULL(inserted.[ClaimNo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SL = "' + REPLACE(CAST(ISNULL(inserted.[SL],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SLCo = "' + REPLACE(CAST(ISNULL(inserted.[SLCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SLCo, '') , 
								'A' , 
								'InvoiceDate' , 
								NULL , 
								InvoiceDate , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								

-- log additions to the InvoiceDesc column
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
								'vSLClaimHeader' , 
								'<KeyString ClaimNo = "' + REPLACE(CAST(ISNULL(inserted.[ClaimNo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SL = "' + REPLACE(CAST(ISNULL(inserted.[SL],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SLCo = "' + REPLACE(CAST(ISNULL(inserted.[SLCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SLCo, '') , 
								'A' , 
								'InvoiceDesc' , 
								NULL , 
								InvoiceDesc , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								

-- log additions to the RecvdClaimDate column
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
								'vSLClaimHeader' , 
								'<KeyString ClaimNo = "' + REPLACE(CAST(ISNULL(inserted.[ClaimNo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SL = "' + REPLACE(CAST(ISNULL(inserted.[SL],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SLCo = "' + REPLACE(CAST(ISNULL(inserted.[SLCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SLCo, '') , 
								'A' , 
								'RecvdClaimDate' , 
								NULL , 
								RecvdClaimDate , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								

-- log additions to the SL column
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
								'vSLClaimHeader' , 
								'<KeyString ClaimNo = "' + REPLACE(CAST(ISNULL(inserted.[ClaimNo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SL = "' + REPLACE(CAST(ISNULL(inserted.[SL],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SLCo = "' + REPLACE(CAST(ISNULL(inserted.[SLCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SLCo, '') , 
								'A' , 
								'SL' , 
								NULL , 
								SL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								

-- log additions to the SLCo column
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
								'vSLClaimHeader' , 
								'<KeyString ClaimNo = "' + REPLACE(CAST(ISNULL(inserted.[ClaimNo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SL = "' + REPLACE(CAST(ISNULL(inserted.[SL],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SLCo = "' + REPLACE(CAST(ISNULL(inserted.[SLCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SLCo, '') , 
								'A' , 
								'SLCo' , 
								NULL , 
								SLCo , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								


 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSLClaimHeader_Audit_Insert] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSLClaimHeader_Audit_Insert]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSLClaimHeader_Audit_Update ON dbo.vSLClaimHeader
 AFTER UPDATE 
 NOT FOR REPLICATION AS 
 SET NOCOUNT ON 
 -- generated by vspAuditTriggersCreate

 BEGIN TRY 

							IF UPDATE([APRef])
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
								
								SELECT 							'vSLClaimHeader' , 								'<KeyString ClaimNo = "' + REPLACE(CAST(ISNULL(inserted.[ClaimNo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SL = "' + REPLACE(CAST(ISNULL(inserted.[SL],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SLCo = "' + REPLACE(CAST(ISNULL(inserted.[SLCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SLCo , 								'C' , 								'APRef' , 								CONVERT(VARCHAR(MAX), deleted.[APRef]) , 								CONVERT(VARCHAR(MAX), inserted.[APRef]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[KeyID] = deleted.[KeyID] 
									AND ((inserted.[APRef] <> deleted.[APRef]) OR (inserted.[APRef] IS NULL AND deleted.[APRef] IS NOT NULL) OR (inserted.[APRef] IS NOT NULL AND deleted.[APRef] IS NULL))
								

							END 

							IF UPDATE([ApproveRetention])
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
								
								SELECT 							'vSLClaimHeader' , 								'<KeyString ClaimNo = "' + REPLACE(CAST(ISNULL(inserted.[ClaimNo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SL = "' + REPLACE(CAST(ISNULL(inserted.[SL],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SLCo = "' + REPLACE(CAST(ISNULL(inserted.[SLCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SLCo , 								'C' , 								'ApproveRetention' , 								CONVERT(VARCHAR(MAX), deleted.[ApproveRetention]) , 								CONVERT(VARCHAR(MAX), inserted.[ApproveRetention]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[KeyID] = deleted.[KeyID] 
									AND ((inserted.[ApproveRetention] <> deleted.[ApproveRetention]) OR (inserted.[ApproveRetention] IS NULL AND deleted.[ApproveRetention] IS NOT NULL) OR (inserted.[ApproveRetention] IS NOT NULL AND deleted.[ApproveRetention] IS NULL))
								

							END 

							IF UPDATE([CertifiedBy])
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
								
								SELECT 							'vSLClaimHeader' , 								'<KeyString ClaimNo = "' + REPLACE(CAST(ISNULL(inserted.[ClaimNo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SL = "' + REPLACE(CAST(ISNULL(inserted.[SL],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SLCo = "' + REPLACE(CAST(ISNULL(inserted.[SLCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SLCo , 								'C' , 								'CertifiedBy' , 								CONVERT(VARCHAR(MAX), deleted.[CertifiedBy]) , 								CONVERT(VARCHAR(MAX), inserted.[CertifiedBy]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[KeyID] = deleted.[KeyID] 
									AND ((inserted.[CertifiedBy] <> deleted.[CertifiedBy]) OR (inserted.[CertifiedBy] IS NULL AND deleted.[CertifiedBy] IS NOT NULL) OR (inserted.[CertifiedBy] IS NOT NULL AND deleted.[CertifiedBy] IS NULL))
								

							END 

							IF UPDATE([CertifyDate])
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
								
								SELECT 							'vSLClaimHeader' , 								'<KeyString ClaimNo = "' + REPLACE(CAST(ISNULL(inserted.[ClaimNo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SL = "' + REPLACE(CAST(ISNULL(inserted.[SL],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SLCo = "' + REPLACE(CAST(ISNULL(inserted.[SLCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SLCo , 								'C' , 								'CertifyDate' , 								CONVERT(VARCHAR(MAX), deleted.[CertifyDate]) , 								CONVERT(VARCHAR(MAX), inserted.[CertifyDate]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[KeyID] = deleted.[KeyID] 
									AND ((inserted.[CertifyDate] <> deleted.[CertifyDate]) OR (inserted.[CertifyDate] IS NULL AND deleted.[CertifyDate] IS NOT NULL) OR (inserted.[CertifyDate] IS NOT NULL AND deleted.[CertifyDate] IS NULL))
								

							END 

							IF UPDATE([ClaimDate])
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
								
								SELECT 							'vSLClaimHeader' , 								'<KeyString ClaimNo = "' + REPLACE(CAST(ISNULL(inserted.[ClaimNo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SL = "' + REPLACE(CAST(ISNULL(inserted.[SL],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SLCo = "' + REPLACE(CAST(ISNULL(inserted.[SLCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SLCo , 								'C' , 								'ClaimDate' , 								CONVERT(VARCHAR(MAX), deleted.[ClaimDate]) , 								CONVERT(VARCHAR(MAX), inserted.[ClaimDate]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[KeyID] = deleted.[KeyID] 
									AND ((inserted.[ClaimDate] <> deleted.[ClaimDate]) OR (inserted.[ClaimDate] IS NULL AND deleted.[ClaimDate] IS NOT NULL) OR (inserted.[ClaimDate] IS NOT NULL AND deleted.[ClaimDate] IS NULL))
								

							END 

							IF UPDATE([ClaimNo])
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
								
								SELECT 							'vSLClaimHeader' , 								'<KeyString ClaimNo = "' + REPLACE(CAST(ISNULL(inserted.[ClaimNo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SL = "' + REPLACE(CAST(ISNULL(inserted.[SL],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SLCo = "' + REPLACE(CAST(ISNULL(inserted.[SLCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SLCo , 								'C' , 								'ClaimNo' , 								CONVERT(VARCHAR(MAX), deleted.[ClaimNo]) , 								CONVERT(VARCHAR(MAX), inserted.[ClaimNo]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[KeyID] = deleted.[KeyID] 
									AND ((inserted.[ClaimNo] <> deleted.[ClaimNo]) OR (inserted.[ClaimNo] IS NULL AND deleted.[ClaimNo] IS NOT NULL) OR (inserted.[ClaimNo] IS NOT NULL AND deleted.[ClaimNo] IS NULL))
								

							END 

							IF UPDATE([ClaimStatus])
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
								
								SELECT 							'vSLClaimHeader' , 								'<KeyString ClaimNo = "' + REPLACE(CAST(ISNULL(inserted.[ClaimNo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SL = "' + REPLACE(CAST(ISNULL(inserted.[SL],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SLCo = "' + REPLACE(CAST(ISNULL(inserted.[SLCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SLCo , 								'C' , 								'ClaimStatus' , 								CONVERT(VARCHAR(MAX), deleted.[ClaimStatus]) , 								CONVERT(VARCHAR(MAX), inserted.[ClaimStatus]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[KeyID] = deleted.[KeyID] 
									AND ((inserted.[ClaimStatus] <> deleted.[ClaimStatus]) OR (inserted.[ClaimStatus] IS NULL AND deleted.[ClaimStatus] IS NOT NULL) OR (inserted.[ClaimStatus] IS NOT NULL AND deleted.[ClaimStatus] IS NULL))
								

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
								
								SELECT 							'vSLClaimHeader' , 								'<KeyString ClaimNo = "' + REPLACE(CAST(ISNULL(inserted.[ClaimNo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SL = "' + REPLACE(CAST(ISNULL(inserted.[SL],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SLCo = "' + REPLACE(CAST(ISNULL(inserted.[SLCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SLCo , 								'C' , 								'Description' , 								CONVERT(VARCHAR(MAX), deleted.[Description]) , 								CONVERT(VARCHAR(MAX), inserted.[Description]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[KeyID] = deleted.[KeyID] 
									AND ((inserted.[Description] <> deleted.[Description]) OR (inserted.[Description] IS NULL AND deleted.[Description] IS NOT NULL) OR (inserted.[Description] IS NOT NULL AND deleted.[Description] IS NULL))
								

							END 

							IF UPDATE([InvoiceDate])
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
								
								SELECT 							'vSLClaimHeader' , 								'<KeyString ClaimNo = "' + REPLACE(CAST(ISNULL(inserted.[ClaimNo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SL = "' + REPLACE(CAST(ISNULL(inserted.[SL],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SLCo = "' + REPLACE(CAST(ISNULL(inserted.[SLCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SLCo , 								'C' , 								'InvoiceDate' , 								CONVERT(VARCHAR(MAX), deleted.[InvoiceDate]) , 								CONVERT(VARCHAR(MAX), inserted.[InvoiceDate]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[KeyID] = deleted.[KeyID] 
									AND ((inserted.[InvoiceDate] <> deleted.[InvoiceDate]) OR (inserted.[InvoiceDate] IS NULL AND deleted.[InvoiceDate] IS NOT NULL) OR (inserted.[InvoiceDate] IS NOT NULL AND deleted.[InvoiceDate] IS NULL))
								

							END 

							IF UPDATE([InvoiceDesc])
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
								
								SELECT 							'vSLClaimHeader' , 								'<KeyString ClaimNo = "' + REPLACE(CAST(ISNULL(inserted.[ClaimNo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SL = "' + REPLACE(CAST(ISNULL(inserted.[SL],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SLCo = "' + REPLACE(CAST(ISNULL(inserted.[SLCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SLCo , 								'C' , 								'InvoiceDesc' , 								CONVERT(VARCHAR(MAX), deleted.[InvoiceDesc]) , 								CONVERT(VARCHAR(MAX), inserted.[InvoiceDesc]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[KeyID] = deleted.[KeyID] 
									AND ((inserted.[InvoiceDesc] <> deleted.[InvoiceDesc]) OR (inserted.[InvoiceDesc] IS NULL AND deleted.[InvoiceDesc] IS NOT NULL) OR (inserted.[InvoiceDesc] IS NOT NULL AND deleted.[InvoiceDesc] IS NULL))
								

							END 

							IF UPDATE([RecvdClaimDate])
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
								
								SELECT 							'vSLClaimHeader' , 								'<KeyString ClaimNo = "' + REPLACE(CAST(ISNULL(inserted.[ClaimNo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SL = "' + REPLACE(CAST(ISNULL(inserted.[SL],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SLCo = "' + REPLACE(CAST(ISNULL(inserted.[SLCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SLCo , 								'C' , 								'RecvdClaimDate' , 								CONVERT(VARCHAR(MAX), deleted.[RecvdClaimDate]) , 								CONVERT(VARCHAR(MAX), inserted.[RecvdClaimDate]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[KeyID] = deleted.[KeyID] 
									AND ((inserted.[RecvdClaimDate] <> deleted.[RecvdClaimDate]) OR (inserted.[RecvdClaimDate] IS NULL AND deleted.[RecvdClaimDate] IS NOT NULL) OR (inserted.[RecvdClaimDate] IS NOT NULL AND deleted.[RecvdClaimDate] IS NULL))
								

							END 

							IF UPDATE([SL])
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
								
								SELECT 							'vSLClaimHeader' , 								'<KeyString ClaimNo = "' + REPLACE(CAST(ISNULL(inserted.[ClaimNo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SL = "' + REPLACE(CAST(ISNULL(inserted.[SL],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SLCo = "' + REPLACE(CAST(ISNULL(inserted.[SLCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SLCo , 								'C' , 								'SL' , 								CONVERT(VARCHAR(MAX), deleted.[SL]) , 								CONVERT(VARCHAR(MAX), inserted.[SL]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[KeyID] = deleted.[KeyID] 
									AND ((inserted.[SL] <> deleted.[SL]) OR (inserted.[SL] IS NULL AND deleted.[SL] IS NOT NULL) OR (inserted.[SL] IS NOT NULL AND deleted.[SL] IS NULL))
								

							END 

							IF UPDATE([SLCo])
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
								
								SELECT 							'vSLClaimHeader' , 								'<KeyString ClaimNo = "' + REPLACE(CAST(ISNULL(inserted.[ClaimNo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SL = "' + REPLACE(CAST(ISNULL(inserted.[SL],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SLCo = "' + REPLACE(CAST(ISNULL(inserted.[SLCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SLCo , 								'C' , 								'SLCo' , 								CONVERT(VARCHAR(MAX), deleted.[SLCo]) , 								CONVERT(VARCHAR(MAX), inserted.[SLCo]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[KeyID] = deleted.[KeyID] 
									AND ((inserted.[SLCo] <> deleted.[SLCo]) OR (inserted.[SLCo] IS NULL AND deleted.[SLCo] IS NOT NULL) OR (inserted.[SLCo] IS NOT NULL AND deleted.[SLCo] IS NULL))
								

							END 



 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSLClaimHeader_Audit_Update] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSLClaimHeader_Audit_Update]', 'last', 'update', null
GO
ALTER TABLE [dbo].[vSLClaimHeader] ADD CONSTRAINT [CK_vSLClaimHeader_ClaimStatus] CHECK (([ClaimStatus]>=(10) AND [ClaimStatus]<=(50)))
GO
ALTER TABLE [dbo].[vSLClaimHeader] ADD CONSTRAINT [PK_vSLClaimHeader] PRIMARY KEY CLUSTERED  ([SLCo], [SL], [ClaimNo]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vSLClaimHeader_KeyID] ON [dbo].[vSLClaimHeader] ([KeyID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vSLClaimHeader_SL] ON [dbo].[vSLClaimHeader] ([SLCo], [SL]) ON [PRIMARY]
GO