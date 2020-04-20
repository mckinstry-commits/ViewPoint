CREATE TABLE [dbo].[vSMCustomerContact]
(
[SMCustomerContactID] [bigint] NOT NULL IDENTITY(1, 1),
[SMCo] [dbo].[bCompany] NOT NULL,
[CustGroup] [dbo].[bGroup] NOT NULL,
[Customer] [int] NOT NULL,
[ContactGroup] [dbo].[bGroup] NOT NULL,
[ContactSeq] [int] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMCustomerContact_Audit_Delete ON dbo.vSMCustomerContact
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
								'vSMCustomerContact' , 
								'<KeyString CustGroup = "' + REPLACE(CAST(ISNULL(deleted.[CustGroup],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Customer = "' + REPLACE(CAST(ISNULL(deleted.[Customer],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'ContactGroup' , 
								CONVERT(VARCHAR(MAX), deleted.[ContactGroup]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 13
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
								'vSMCustomerContact' , 
								'<KeyString CustGroup = "' + REPLACE(CAST(ISNULL(deleted.[CustGroup],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Customer = "' + REPLACE(CAST(ISNULL(deleted.[Customer],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'ContactSeq' , 
								CONVERT(VARCHAR(MAX), deleted.[ContactSeq]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 13
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
								'vSMCustomerContact' , 
								'<KeyString CustGroup = "' + REPLACE(CAST(ISNULL(deleted.[CustGroup],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Customer = "' + REPLACE(CAST(ISNULL(deleted.[Customer],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'CustGroup' , 
								CONVERT(VARCHAR(MAX), deleted.[CustGroup]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 13
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
								'vSMCustomerContact' , 
								'<KeyString CustGroup = "' + REPLACE(CAST(ISNULL(deleted.[CustGroup],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Customer = "' + REPLACE(CAST(ISNULL(deleted.[Customer],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'Customer' , 
								CONVERT(VARCHAR(MAX), deleted.[Customer]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 13
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
								'vSMCustomerContact' , 
								'<KeyString CustGroup = "' + REPLACE(CAST(ISNULL(deleted.[CustGroup],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Customer = "' + REPLACE(CAST(ISNULL(deleted.[Customer],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'SMCo' , 
								CONVERT(VARCHAR(MAX), deleted.[SMCo]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 13
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
								'vSMCustomerContact' , 
								'<KeyString CustGroup = "' + REPLACE(CAST(ISNULL(deleted.[CustGroup],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Customer = "' + REPLACE(CAST(ISNULL(deleted.[Customer],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'SMCustomerContactID' , 
								CONVERT(VARCHAR(MAX), deleted.[SMCustomerContactID]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 13

							 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT DISTINCT Keys.AuditID, 'bSMCo', d.SMCo, CAST(d.SMCo AS VARCHAR(30)), 'vSMCustomerContact'
				FROM deleted AS d
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString CustGroup = "' + REPLACE(CAST(ISNULL(d.[CustGroup],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Customer = "' + REPLACE(CAST(ISNULL(d.[Customer],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(d.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMCustomerContact_Audit_Delete] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMCustomerContact_Audit_Delete]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMCustomerContact_Audit_Insert ON dbo.vSMCustomerContact
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
-- log additions to the ContactGroup column
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
								'vSMCustomerContact' , 
								'<KeyString CustGroup = "' + REPLACE(CAST(ISNULL(inserted.[CustGroup],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Customer = "' + REPLACE(CAST(ISNULL(inserted.[Customer],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'ContactGroup' , 
								NULL , 
								ContactGroup , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 13

-- log additions to the ContactSeq column
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
								'vSMCustomerContact' , 
								'<KeyString CustGroup = "' + REPLACE(CAST(ISNULL(inserted.[CustGroup],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Customer = "' + REPLACE(CAST(ISNULL(inserted.[Customer],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'ContactSeq' , 
								NULL , 
								ContactSeq , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 13

-- log additions to the CustGroup column
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
								'vSMCustomerContact' , 
								'<KeyString CustGroup = "' + REPLACE(CAST(ISNULL(inserted.[CustGroup],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Customer = "' + REPLACE(CAST(ISNULL(inserted.[Customer],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'CustGroup' , 
								NULL , 
								CustGroup , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 13

-- log additions to the Customer column
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
								'vSMCustomerContact' , 
								'<KeyString CustGroup = "' + REPLACE(CAST(ISNULL(inserted.[CustGroup],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Customer = "' + REPLACE(CAST(ISNULL(inserted.[Customer],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Customer' , 
								NULL , 
								Customer , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 13

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
								'vSMCustomerContact' , 
								'<KeyString CustGroup = "' + REPLACE(CAST(ISNULL(inserted.[CustGroup],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Customer = "' + REPLACE(CAST(ISNULL(inserted.[Customer],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'SMCo' , 
								NULL , 
								SMCo , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 13

-- log additions to the SMCustomerContactID column
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
								'vSMCustomerContact' , 
								'<KeyString CustGroup = "' + REPLACE(CAST(ISNULL(inserted.[CustGroup],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Customer = "' + REPLACE(CAST(ISNULL(inserted.[Customer],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'SMCustomerContactID' , 
								NULL , 
								SMCustomerContactID , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 13

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT DISTINCT Keys.AuditID, 'bSMCo', i.SMCo, CAST(i.SMCo AS VARCHAR(30)), 'vSMCustomerContact'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString CustGroup = "' + REPLACE(CAST(ISNULL(i.[CustGroup],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Customer = "' + REPLACE(CAST(ISNULL(i.[Customer],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(i.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMCustomerContact_Audit_Insert] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMCustomerContact_Audit_Insert]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMCustomerContact_Audit_Update ON dbo.vSMCustomerContact
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
							IF UPDATE([ContactGroup])
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
								SELECT 							'vSMCustomerContact' , 								'<KeyString CustGroup = "' + REPLACE(CAST(ISNULL(inserted.[CustGroup],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Customer = "' + REPLACE(CAST(ISNULL(inserted.[Customer],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'ContactGroup' , 								CONVERT(VARCHAR(MAX), deleted.[ContactGroup]) , 								CONVERT(VARCHAR(MAX), inserted.[ContactGroup]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMCustomerContactID] = deleted.[SMCustomerContactID] 
									AND ((inserted.[ContactGroup] <> deleted.[ContactGroup]) OR (inserted.[ContactGroup] IS NULL AND deleted.[ContactGroup] IS NOT NULL) OR (inserted.[ContactGroup] IS NOT NULL AND deleted.[ContactGroup] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 13

							END 

							IF UPDATE([ContactSeq])
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
								SELECT 							'vSMCustomerContact' , 								'<KeyString CustGroup = "' + REPLACE(CAST(ISNULL(inserted.[CustGroup],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Customer = "' + REPLACE(CAST(ISNULL(inserted.[Customer],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'ContactSeq' , 								CONVERT(VARCHAR(MAX), deleted.[ContactSeq]) , 								CONVERT(VARCHAR(MAX), inserted.[ContactSeq]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMCustomerContactID] = deleted.[SMCustomerContactID] 
									AND ((inserted.[ContactSeq] <> deleted.[ContactSeq]) OR (inserted.[ContactSeq] IS NULL AND deleted.[ContactSeq] IS NOT NULL) OR (inserted.[ContactSeq] IS NOT NULL AND deleted.[ContactSeq] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 13

							END 

							IF UPDATE([CustGroup])
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
								SELECT 							'vSMCustomerContact' , 								'<KeyString CustGroup = "' + REPLACE(CAST(ISNULL(inserted.[CustGroup],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Customer = "' + REPLACE(CAST(ISNULL(inserted.[Customer],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'CustGroup' , 								CONVERT(VARCHAR(MAX), deleted.[CustGroup]) , 								CONVERT(VARCHAR(MAX), inserted.[CustGroup]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMCustomerContactID] = deleted.[SMCustomerContactID] 
									AND ((inserted.[CustGroup] <> deleted.[CustGroup]) OR (inserted.[CustGroup] IS NULL AND deleted.[CustGroup] IS NOT NULL) OR (inserted.[CustGroup] IS NOT NULL AND deleted.[CustGroup] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 13

							END 

							IF UPDATE([Customer])
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
								SELECT 							'vSMCustomerContact' , 								'<KeyString CustGroup = "' + REPLACE(CAST(ISNULL(inserted.[CustGroup],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Customer = "' + REPLACE(CAST(ISNULL(inserted.[Customer],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'Customer' , 								CONVERT(VARCHAR(MAX), deleted.[Customer]) , 								CONVERT(VARCHAR(MAX), inserted.[Customer]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMCustomerContactID] = deleted.[SMCustomerContactID] 
									AND ((inserted.[Customer] <> deleted.[Customer]) OR (inserted.[Customer] IS NULL AND deleted.[Customer] IS NOT NULL) OR (inserted.[Customer] IS NOT NULL AND deleted.[Customer] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 13

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
								SELECT 							'vSMCustomerContact' , 								'<KeyString CustGroup = "' + REPLACE(CAST(ISNULL(inserted.[CustGroup],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Customer = "' + REPLACE(CAST(ISNULL(inserted.[Customer],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'SMCo' , 								CONVERT(VARCHAR(MAX), deleted.[SMCo]) , 								CONVERT(VARCHAR(MAX), inserted.[SMCo]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMCustomerContactID] = deleted.[SMCustomerContactID] 
									AND ((inserted.[SMCo] <> deleted.[SMCo]) OR (inserted.[SMCo] IS NULL AND deleted.[SMCo] IS NOT NULL) OR (inserted.[SMCo] IS NOT NULL AND deleted.[SMCo] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 13

							END 

							IF UPDATE([SMCustomerContactID])
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
								SELECT 							'vSMCustomerContact' , 								'<KeyString CustGroup = "' + REPLACE(CAST(ISNULL(inserted.[CustGroup],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Customer = "' + REPLACE(CAST(ISNULL(inserted.[Customer],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'SMCustomerContactID' , 								CONVERT(VARCHAR(MAX), deleted.[SMCustomerContactID]) , 								CONVERT(VARCHAR(MAX), inserted.[SMCustomerContactID]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMCustomerContactID] = deleted.[SMCustomerContactID] 
									AND ((inserted.[SMCustomerContactID] <> deleted.[SMCustomerContactID]) OR (inserted.[SMCustomerContactID] IS NULL AND deleted.[SMCustomerContactID] IS NOT NULL) OR (inserted.[SMCustomerContactID] IS NOT NULL AND deleted.[SMCustomerContactID] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 13

							END 

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT DISTINCT Keys.AuditID, 'bSMCo', i.SMCo, CAST(i.SMCo AS VARCHAR(30)), 'vSMCustomerContact'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString CustGroup = "' + REPLACE(CAST(ISNULL(i.[CustGroup],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Customer = "' + REPLACE(CAST(ISNULL(i.[Customer],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(i.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />'


 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMCustomerContact_Audit_Update] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMCustomerContact_Audit_Update]', 'last', 'update', null
GO
ALTER TABLE [dbo].[vSMCustomerContact] ADD CONSTRAINT [PK_vSMCustomerContact] PRIMARY KEY CLUSTERED  ([SMCustomerContactID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMCustomerContact] ADD CONSTRAINT [IX_vSMCustomerContact_SMCo_CustGroup_Customer_ContactGroup_ContactSeq] UNIQUE NONCLUSTERED  ([SMCo], [CustGroup], [Customer], [ContactGroup], [ContactSeq]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMCustomerContact] WITH NOCHECK ADD CONSTRAINT [FK_vSMCustomerContact_vHQContact] FOREIGN KEY ([ContactGroup], [ContactSeq]) REFERENCES [dbo].[vHQContact] ([ContactGroup], [ContactSeq])
GO
ALTER TABLE [dbo].[vSMCustomerContact] WITH NOCHECK ADD CONSTRAINT [FK_vSMCustomerContact_vSMCO] FOREIGN KEY ([SMCo]) REFERENCES [dbo].[vSMCO] ([SMCo])
GO
ALTER TABLE [dbo].[vSMCustomerContact] WITH NOCHECK ADD CONSTRAINT [FK_vSMCustomerContact_vCustomer] FOREIGN KEY ([SMCo], [CustGroup], [Customer]) REFERENCES [dbo].[vSMCustomer] ([SMCo], [CustGroup], [Customer])
GO
