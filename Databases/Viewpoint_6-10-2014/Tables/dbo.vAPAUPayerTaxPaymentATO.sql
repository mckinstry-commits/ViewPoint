CREATE TABLE [dbo].[vAPAUPayerTaxPaymentATO]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[APCo] [dbo].[bCompany] NOT NULL,
[TaxYear] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[ContactName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ContactPhone] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[SignatureOfAuthPerson] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ReportDate] [dbo].[bDate] NULL,
[TaxYearClosed] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vAPAUPayerTaxPaymentATO_TaxYearClosed] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL,
[ABN] [varchar] (11) COLLATE Latin1_General_BIN NULL,
[BranchNo] [varchar] (3) COLLATE Latin1_General_BIN NULL,
[CompanyName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Address] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Address2] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[City] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[PostalCode] [dbo].[bZip] NULL,
[Country] [varchar] (2) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvAPAUPayerTaxPaymentATO_Audit_Delete ON dbo.vAPAUPayerTaxPaymentATO
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
								'vAPAUPayerTaxPaymentATO' , 
								'<KeyString APCo = "' + REPLACE(CAST(ISNULL(deleted.[APCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" TaxYear = "' + REPLACE(CAST(ISNULL(deleted.[TaxYear],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.APCo , 
								'D' , 
								'APCo' , 
								CONVERT(VARCHAR(MAX), deleted.[APCo]) , 								NULL , 
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
								'vAPAUPayerTaxPaymentATO' , 
								'<KeyString APCo = "' + REPLACE(CAST(ISNULL(deleted.[APCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" TaxYear = "' + REPLACE(CAST(ISNULL(deleted.[TaxYear],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.APCo , 
								'D' , 
								'TaxYear' , 
								CONVERT(VARCHAR(MAX), deleted.[TaxYear]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								

							
 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvAPAUPayerTaxPaymentATO_Audit_Delete] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvAPAUPayerTaxPaymentATO_Audit_Delete]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvAPAUPayerTaxPaymentATO_Audit_Insert ON dbo.vAPAUPayerTaxPaymentATO
 AFTER INSERT
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspAuditTriggersCreate

 BEGIN TRY 

-- log additions to the ABN column
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
								'vAPAUPayerTaxPaymentATO' , 
								'<KeyString APCo = "' + REPLACE(CAST(ISNULL(inserted.[APCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" TaxYear = "' + REPLACE(CAST(ISNULL(inserted.[TaxYear],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.APCo, '') , 
								'A' , 
								'ABN' , 
								NULL , 
								[ABN] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								

-- log additions to the APCo column
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
								'vAPAUPayerTaxPaymentATO' , 
								'<KeyString APCo = "' + REPLACE(CAST(ISNULL(inserted.[APCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" TaxYear = "' + REPLACE(CAST(ISNULL(inserted.[TaxYear],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.APCo, '') , 
								'A' , 
								'APCo' , 
								NULL , 
								[APCo] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								

-- log additions to the Address column
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
								'vAPAUPayerTaxPaymentATO' , 
								'<KeyString APCo = "' + REPLACE(CAST(ISNULL(inserted.[APCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" TaxYear = "' + REPLACE(CAST(ISNULL(inserted.[TaxYear],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.APCo, '') , 
								'A' , 
								'Address' , 
								NULL , 
								[Address] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								

-- log additions to the Address2 column
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
								'vAPAUPayerTaxPaymentATO' , 
								'<KeyString APCo = "' + REPLACE(CAST(ISNULL(inserted.[APCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" TaxYear = "' + REPLACE(CAST(ISNULL(inserted.[TaxYear],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.APCo, '') , 
								'A' , 
								'Address2' , 
								NULL , 
								[Address2] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								

-- log additions to the BranchNo column
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
								'vAPAUPayerTaxPaymentATO' , 
								'<KeyString APCo = "' + REPLACE(CAST(ISNULL(inserted.[APCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" TaxYear = "' + REPLACE(CAST(ISNULL(inserted.[TaxYear],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.APCo, '') , 
								'A' , 
								'BranchNo' , 
								NULL , 
								[BranchNo] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								

-- log additions to the City column
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
								'vAPAUPayerTaxPaymentATO' , 
								'<KeyString APCo = "' + REPLACE(CAST(ISNULL(inserted.[APCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" TaxYear = "' + REPLACE(CAST(ISNULL(inserted.[TaxYear],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.APCo, '') , 
								'A' , 
								'City' , 
								NULL , 
								[City] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								

-- log additions to the CompanyName column
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
								'vAPAUPayerTaxPaymentATO' , 
								'<KeyString APCo = "' + REPLACE(CAST(ISNULL(inserted.[APCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" TaxYear = "' + REPLACE(CAST(ISNULL(inserted.[TaxYear],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.APCo, '') , 
								'A' , 
								'CompanyName' , 
								NULL , 
								[CompanyName] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								

-- log additions to the ContactName column
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
								'vAPAUPayerTaxPaymentATO' , 
								'<KeyString APCo = "' + REPLACE(CAST(ISNULL(inserted.[APCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" TaxYear = "' + REPLACE(CAST(ISNULL(inserted.[TaxYear],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.APCo, '') , 
								'A' , 
								'ContactName' , 
								NULL , 
								[ContactName] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								

-- log additions to the ContactPhone column
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
								'vAPAUPayerTaxPaymentATO' , 
								'<KeyString APCo = "' + REPLACE(CAST(ISNULL(inserted.[APCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" TaxYear = "' + REPLACE(CAST(ISNULL(inserted.[TaxYear],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.APCo, '') , 
								'A' , 
								'ContactPhone' , 
								NULL , 
								[ContactPhone] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								

-- log additions to the Country column
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
								'vAPAUPayerTaxPaymentATO' , 
								'<KeyString APCo = "' + REPLACE(CAST(ISNULL(inserted.[APCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" TaxYear = "' + REPLACE(CAST(ISNULL(inserted.[TaxYear],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.APCo, '') , 
								'A' , 
								'Country' , 
								NULL , 
								[Country] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								

-- log additions to the PostalCode column
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
								'vAPAUPayerTaxPaymentATO' , 
								'<KeyString APCo = "' + REPLACE(CAST(ISNULL(inserted.[APCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" TaxYear = "' + REPLACE(CAST(ISNULL(inserted.[TaxYear],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.APCo, '') , 
								'A' , 
								'PostalCode' , 
								NULL , 
								[PostalCode] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								

-- log additions to the ReportDate column
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
								'vAPAUPayerTaxPaymentATO' , 
								'<KeyString APCo = "' + REPLACE(CAST(ISNULL(inserted.[APCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" TaxYear = "' + REPLACE(CAST(ISNULL(inserted.[TaxYear],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.APCo, '') , 
								'A' , 
								'ReportDate' , 
								NULL , 
								[ReportDate] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								

-- log additions to the SignatureOfAuthPerson column
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
								'vAPAUPayerTaxPaymentATO' , 
								'<KeyString APCo = "' + REPLACE(CAST(ISNULL(inserted.[APCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" TaxYear = "' + REPLACE(CAST(ISNULL(inserted.[TaxYear],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.APCo, '') , 
								'A' , 
								'SignatureOfAuthPerson' , 
								NULL , 
								[SignatureOfAuthPerson] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								

-- log additions to the State column
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
								'vAPAUPayerTaxPaymentATO' , 
								'<KeyString APCo = "' + REPLACE(CAST(ISNULL(inserted.[APCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" TaxYear = "' + REPLACE(CAST(ISNULL(inserted.[TaxYear],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.APCo, '') , 
								'A' , 
								'State' , 
								NULL , 
								[State] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								

-- log additions to the TaxYear column
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
								'vAPAUPayerTaxPaymentATO' , 
								'<KeyString APCo = "' + REPLACE(CAST(ISNULL(inserted.[APCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" TaxYear = "' + REPLACE(CAST(ISNULL(inserted.[TaxYear],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.APCo, '') , 
								'A' , 
								'TaxYear' , 
								NULL , 
								[TaxYear] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								

-- log additions to the TaxYearClosed column
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
								'vAPAUPayerTaxPaymentATO' , 
								'<KeyString APCo = "' + REPLACE(CAST(ISNULL(inserted.[APCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" TaxYear = "' + REPLACE(CAST(ISNULL(inserted.[TaxYear],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.APCo, '') , 
								'A' , 
								'TaxYearClosed' , 
								NULL , 
								[TaxYearClosed] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								


 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvAPAUPayerTaxPaymentATO_Audit_Insert] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvAPAUPayerTaxPaymentATO_Audit_Insert]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvAPAUPayerTaxPaymentATO_Audit_Update ON dbo.vAPAUPayerTaxPaymentATO
 AFTER UPDATE 
 NOT FOR REPLICATION AS 
 SET NOCOUNT ON 
 -- generated by vspAuditTriggersCreate

 BEGIN TRY 

							IF UPDATE([ABN])
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
								
								SELECT 							'vAPAUPayerTaxPaymentATO' , 								'<KeyString APCo = "' + REPLACE(CAST(ISNULL(inserted.[APCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" TaxYear = "' + REPLACE(CAST(ISNULL(inserted.[TaxYear],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.APCo , 								'C' , 								'ABN' , 								CONVERT(VARCHAR(MAX), deleted.[ABN]) , 								CONVERT(VARCHAR(MAX), inserted.[ABN]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[KeyID] = deleted.[KeyID] 
									AND ((inserted.[ABN] <> deleted.[ABN]) OR (inserted.[ABN] IS NULL AND deleted.[ABN] IS NOT NULL) OR (inserted.[ABN] IS NOT NULL AND deleted.[ABN] IS NULL))
								

							END 

							IF UPDATE([APCo])
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
								
								SELECT 							'vAPAUPayerTaxPaymentATO' , 								'<KeyString APCo = "' + REPLACE(CAST(ISNULL(inserted.[APCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" TaxYear = "' + REPLACE(CAST(ISNULL(inserted.[TaxYear],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.APCo , 								'C' , 								'APCo' , 								CONVERT(VARCHAR(MAX), deleted.[APCo]) , 								CONVERT(VARCHAR(MAX), inserted.[APCo]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[KeyID] = deleted.[KeyID] 
									AND ((inserted.[APCo] <> deleted.[APCo]) OR (inserted.[APCo] IS NULL AND deleted.[APCo] IS NOT NULL) OR (inserted.[APCo] IS NOT NULL AND deleted.[APCo] IS NULL))
								

							END 

							IF UPDATE([Address])
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
								
								SELECT 							'vAPAUPayerTaxPaymentATO' , 								'<KeyString APCo = "' + REPLACE(CAST(ISNULL(inserted.[APCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" TaxYear = "' + REPLACE(CAST(ISNULL(inserted.[TaxYear],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.APCo , 								'C' , 								'Address' , 								CONVERT(VARCHAR(MAX), deleted.[Address]) , 								CONVERT(VARCHAR(MAX), inserted.[Address]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[KeyID] = deleted.[KeyID] 
									AND ((inserted.[Address] <> deleted.[Address]) OR (inserted.[Address] IS NULL AND deleted.[Address] IS NOT NULL) OR (inserted.[Address] IS NOT NULL AND deleted.[Address] IS NULL))
								

							END 

							IF UPDATE([Address2])
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
								
								SELECT 							'vAPAUPayerTaxPaymentATO' , 								'<KeyString APCo = "' + REPLACE(CAST(ISNULL(inserted.[APCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" TaxYear = "' + REPLACE(CAST(ISNULL(inserted.[TaxYear],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.APCo , 								'C' , 								'Address2' , 								CONVERT(VARCHAR(MAX), deleted.[Address2]) , 								CONVERT(VARCHAR(MAX), inserted.[Address2]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[KeyID] = deleted.[KeyID] 
									AND ((inserted.[Address2] <> deleted.[Address2]) OR (inserted.[Address2] IS NULL AND deleted.[Address2] IS NOT NULL) OR (inserted.[Address2] IS NOT NULL AND deleted.[Address2] IS NULL))
								

							END 

							IF UPDATE([BranchNo])
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
								
								SELECT 							'vAPAUPayerTaxPaymentATO' , 								'<KeyString APCo = "' + REPLACE(CAST(ISNULL(inserted.[APCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" TaxYear = "' + REPLACE(CAST(ISNULL(inserted.[TaxYear],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.APCo , 								'C' , 								'BranchNo' , 								CONVERT(VARCHAR(MAX), deleted.[BranchNo]) , 								CONVERT(VARCHAR(MAX), inserted.[BranchNo]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[KeyID] = deleted.[KeyID] 
									AND ((inserted.[BranchNo] <> deleted.[BranchNo]) OR (inserted.[BranchNo] IS NULL AND deleted.[BranchNo] IS NOT NULL) OR (inserted.[BranchNo] IS NOT NULL AND deleted.[BranchNo] IS NULL))
								

							END 

							IF UPDATE([City])
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
								
								SELECT 							'vAPAUPayerTaxPaymentATO' , 								'<KeyString APCo = "' + REPLACE(CAST(ISNULL(inserted.[APCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" TaxYear = "' + REPLACE(CAST(ISNULL(inserted.[TaxYear],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.APCo , 								'C' , 								'City' , 								CONVERT(VARCHAR(MAX), deleted.[City]) , 								CONVERT(VARCHAR(MAX), inserted.[City]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[KeyID] = deleted.[KeyID] 
									AND ((inserted.[City] <> deleted.[City]) OR (inserted.[City] IS NULL AND deleted.[City] IS NOT NULL) OR (inserted.[City] IS NOT NULL AND deleted.[City] IS NULL))
								

							END 

							IF UPDATE([CompanyName])
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
								
								SELECT 							'vAPAUPayerTaxPaymentATO' , 								'<KeyString APCo = "' + REPLACE(CAST(ISNULL(inserted.[APCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" TaxYear = "' + REPLACE(CAST(ISNULL(inserted.[TaxYear],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.APCo , 								'C' , 								'CompanyName' , 								CONVERT(VARCHAR(MAX), deleted.[CompanyName]) , 								CONVERT(VARCHAR(MAX), inserted.[CompanyName]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[KeyID] = deleted.[KeyID] 
									AND ((inserted.[CompanyName] <> deleted.[CompanyName]) OR (inserted.[CompanyName] IS NULL AND deleted.[CompanyName] IS NOT NULL) OR (inserted.[CompanyName] IS NOT NULL AND deleted.[CompanyName] IS NULL))
								

							END 

							IF UPDATE([ContactName])
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
								
								SELECT 							'vAPAUPayerTaxPaymentATO' , 								'<KeyString APCo = "' + REPLACE(CAST(ISNULL(inserted.[APCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" TaxYear = "' + REPLACE(CAST(ISNULL(inserted.[TaxYear],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.APCo , 								'C' , 								'ContactName' , 								CONVERT(VARCHAR(MAX), deleted.[ContactName]) , 								CONVERT(VARCHAR(MAX), inserted.[ContactName]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[KeyID] = deleted.[KeyID] 
									AND ((inserted.[ContactName] <> deleted.[ContactName]) OR (inserted.[ContactName] IS NULL AND deleted.[ContactName] IS NOT NULL) OR (inserted.[ContactName] IS NOT NULL AND deleted.[ContactName] IS NULL))
								

							END 

							IF UPDATE([ContactPhone])
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
								
								SELECT 							'vAPAUPayerTaxPaymentATO' , 								'<KeyString APCo = "' + REPLACE(CAST(ISNULL(inserted.[APCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" TaxYear = "' + REPLACE(CAST(ISNULL(inserted.[TaxYear],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.APCo , 								'C' , 								'ContactPhone' , 								CONVERT(VARCHAR(MAX), deleted.[ContactPhone]) , 								CONVERT(VARCHAR(MAX), inserted.[ContactPhone]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[KeyID] = deleted.[KeyID] 
									AND ((inserted.[ContactPhone] <> deleted.[ContactPhone]) OR (inserted.[ContactPhone] IS NULL AND deleted.[ContactPhone] IS NOT NULL) OR (inserted.[ContactPhone] IS NOT NULL AND deleted.[ContactPhone] IS NULL))
								

							END 

							IF UPDATE([Country])
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
								
								SELECT 							'vAPAUPayerTaxPaymentATO' , 								'<KeyString APCo = "' + REPLACE(CAST(ISNULL(inserted.[APCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" TaxYear = "' + REPLACE(CAST(ISNULL(inserted.[TaxYear],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.APCo , 								'C' , 								'Country' , 								CONVERT(VARCHAR(MAX), deleted.[Country]) , 								CONVERT(VARCHAR(MAX), inserted.[Country]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[KeyID] = deleted.[KeyID] 
									AND ((inserted.[Country] <> deleted.[Country]) OR (inserted.[Country] IS NULL AND deleted.[Country] IS NOT NULL) OR (inserted.[Country] IS NOT NULL AND deleted.[Country] IS NULL))
								

							END 

							IF UPDATE([PostalCode])
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
								
								SELECT 							'vAPAUPayerTaxPaymentATO' , 								'<KeyString APCo = "' + REPLACE(CAST(ISNULL(inserted.[APCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" TaxYear = "' + REPLACE(CAST(ISNULL(inserted.[TaxYear],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.APCo , 								'C' , 								'PostalCode' , 								CONVERT(VARCHAR(MAX), deleted.[PostalCode]) , 								CONVERT(VARCHAR(MAX), inserted.[PostalCode]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[KeyID] = deleted.[KeyID] 
									AND ((inserted.[PostalCode] <> deleted.[PostalCode]) OR (inserted.[PostalCode] IS NULL AND deleted.[PostalCode] IS NOT NULL) OR (inserted.[PostalCode] IS NOT NULL AND deleted.[PostalCode] IS NULL))
								

							END 

							IF UPDATE([ReportDate])
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
								
								SELECT 							'vAPAUPayerTaxPaymentATO' , 								'<KeyString APCo = "' + REPLACE(CAST(ISNULL(inserted.[APCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" TaxYear = "' + REPLACE(CAST(ISNULL(inserted.[TaxYear],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.APCo , 								'C' , 								'ReportDate' , 								CONVERT(VARCHAR(MAX), deleted.[ReportDate]) , 								CONVERT(VARCHAR(MAX), inserted.[ReportDate]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[KeyID] = deleted.[KeyID] 
									AND ((inserted.[ReportDate] <> deleted.[ReportDate]) OR (inserted.[ReportDate] IS NULL AND deleted.[ReportDate] IS NOT NULL) OR (inserted.[ReportDate] IS NOT NULL AND deleted.[ReportDate] IS NULL))
								

							END 

							IF UPDATE([SignatureOfAuthPerson])
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
								
								SELECT 							'vAPAUPayerTaxPaymentATO' , 								'<KeyString APCo = "' + REPLACE(CAST(ISNULL(inserted.[APCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" TaxYear = "' + REPLACE(CAST(ISNULL(inserted.[TaxYear],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.APCo , 								'C' , 								'SignatureOfAuthPerson' , 								CONVERT(VARCHAR(MAX), deleted.[SignatureOfAuthPerson]) , 								CONVERT(VARCHAR(MAX), inserted.[SignatureOfAuthPerson]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[KeyID] = deleted.[KeyID] 
									AND ((inserted.[SignatureOfAuthPerson] <> deleted.[SignatureOfAuthPerson]) OR (inserted.[SignatureOfAuthPerson] IS NULL AND deleted.[SignatureOfAuthPerson] IS NOT NULL) OR (inserted.[SignatureOfAuthPerson] IS NOT NULL AND deleted.[SignatureOfAuthPerson] IS NULL))
								

							END 

							IF UPDATE([State])
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
								
								SELECT 							'vAPAUPayerTaxPaymentATO' , 								'<KeyString APCo = "' + REPLACE(CAST(ISNULL(inserted.[APCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" TaxYear = "' + REPLACE(CAST(ISNULL(inserted.[TaxYear],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.APCo , 								'C' , 								'State' , 								CONVERT(VARCHAR(MAX), deleted.[State]) , 								CONVERT(VARCHAR(MAX), inserted.[State]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[KeyID] = deleted.[KeyID] 
									AND ((inserted.[State] <> deleted.[State]) OR (inserted.[State] IS NULL AND deleted.[State] IS NOT NULL) OR (inserted.[State] IS NOT NULL AND deleted.[State] IS NULL))
								

							END 

							IF UPDATE([TaxYear])
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
								
								SELECT 							'vAPAUPayerTaxPaymentATO' , 								'<KeyString APCo = "' + REPLACE(CAST(ISNULL(inserted.[APCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" TaxYear = "' + REPLACE(CAST(ISNULL(inserted.[TaxYear],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.APCo , 								'C' , 								'TaxYear' , 								CONVERT(VARCHAR(MAX), deleted.[TaxYear]) , 								CONVERT(VARCHAR(MAX), inserted.[TaxYear]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[KeyID] = deleted.[KeyID] 
									AND ((inserted.[TaxYear] <> deleted.[TaxYear]) OR (inserted.[TaxYear] IS NULL AND deleted.[TaxYear] IS NOT NULL) OR (inserted.[TaxYear] IS NOT NULL AND deleted.[TaxYear] IS NULL))
								

							END 

							IF UPDATE([TaxYearClosed])
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
								
								SELECT 							'vAPAUPayerTaxPaymentATO' , 								'<KeyString APCo = "' + REPLACE(CAST(ISNULL(inserted.[APCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" TaxYear = "' + REPLACE(CAST(ISNULL(inserted.[TaxYear],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.APCo , 								'C' , 								'TaxYearClosed' , 								CONVERT(VARCHAR(MAX), deleted.[TaxYearClosed]) , 								CONVERT(VARCHAR(MAX), inserted.[TaxYearClosed]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[KeyID] = deleted.[KeyID] 
									AND ((inserted.[TaxYearClosed] <> deleted.[TaxYearClosed]) OR (inserted.[TaxYearClosed] IS NULL AND deleted.[TaxYearClosed] IS NOT NULL) OR (inserted.[TaxYearClosed] IS NOT NULL AND deleted.[TaxYearClosed] IS NULL))
								

							END 



 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvAPAUPayerTaxPaymentATO_Audit_Update] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvAPAUPayerTaxPaymentATO_Audit_Update]', 'last', 'update', null
GO
ALTER TABLE [dbo].[vAPAUPayerTaxPaymentATO] ADD CONSTRAINT [PK_vAPAUPayerTaxPaymentATO] PRIMARY KEY CLUSTERED  ([APCo], [TaxYear]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[vAPAUPayerTaxPaymentATO] TO [public]
GRANT INSERT ON  [dbo].[vAPAUPayerTaxPaymentATO] TO [public]
GRANT DELETE ON  [dbo].[vAPAUPayerTaxPaymentATO] TO [public]
GRANT UPDATE ON  [dbo].[vAPAUPayerTaxPaymentATO] TO [public]
GO
