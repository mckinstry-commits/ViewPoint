CREATE TABLE [dbo].[vSMRateOverrideStandardItem]
(
[SMRateOverrideStandardItemID] [bigint] NOT NULL IDENTITY(1, 1),
[SMCo] [dbo].[bCompany] NOT NULL,
[StandardItem] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[BillableRate] [dbo].[bUnitCost] NOT NULL,
[AutoAdd] [dbo].[bYN] NULL,
[EntitySeq] [int] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMRateOverrideStandardItem_Audit_Delete ON dbo.vSMRateOverrideStandardItem
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
								'vSMRateOverrideStandardItem' , 
								'<KeyString EntitySeq = "' + REPLACE(CAST(ISNULL(deleted.[EntitySeq],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" StandardItem = "' + REPLACE(CAST(ISNULL(deleted.[StandardItem],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'AutoAdd' , 
								CONVERT(VARCHAR(MAX), deleted.[AutoAdd]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 7
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
								'vSMRateOverrideStandardItem' , 
								'<KeyString EntitySeq = "' + REPLACE(CAST(ISNULL(deleted.[EntitySeq],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" StandardItem = "' + REPLACE(CAST(ISNULL(deleted.[StandardItem],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'BillableRate' , 
								CONVERT(VARCHAR(MAX), deleted.[BillableRate]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 7
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
								'vSMRateOverrideStandardItem' , 
								'<KeyString EntitySeq = "' + REPLACE(CAST(ISNULL(deleted.[EntitySeq],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" StandardItem = "' + REPLACE(CAST(ISNULL(deleted.[StandardItem],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'EntitySeq' , 
								CONVERT(VARCHAR(MAX), deleted.[EntitySeq]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 7
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
								'vSMRateOverrideStandardItem' , 
								'<KeyString EntitySeq = "' + REPLACE(CAST(ISNULL(deleted.[EntitySeq],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" StandardItem = "' + REPLACE(CAST(ISNULL(deleted.[StandardItem],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'SMCo' , 
								CONVERT(VARCHAR(MAX), deleted.[SMCo]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 7
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
								'vSMRateOverrideStandardItem' , 
								'<KeyString EntitySeq = "' + REPLACE(CAST(ISNULL(deleted.[EntitySeq],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" StandardItem = "' + REPLACE(CAST(ISNULL(deleted.[StandardItem],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'SMRateOverrideStandardItemID' , 
								CONVERT(VARCHAR(MAX), deleted.[SMRateOverrideStandardItemID]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 7
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
								'vSMRateOverrideStandardItem' , 
								'<KeyString EntitySeq = "' + REPLACE(CAST(ISNULL(deleted.[EntitySeq],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" StandardItem = "' + REPLACE(CAST(ISNULL(deleted.[StandardItem],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'StandardItem' , 
								CONVERT(VARCHAR(MAX), deleted.[StandardItem]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 7

							 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT DISTINCT Keys.AuditID, 'bSMCo', d.SMCo, CAST(d.SMCo AS VARCHAR(30)), 'vSMRateOverrideStandardItem'
				FROM deleted AS d
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString EntitySeq = "' + REPLACE(CAST(ISNULL(d.[EntitySeq],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(d.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" StandardItem = "' + REPLACE(CAST(ISNULL(d.[StandardItem],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMRateOverrideStandardItem_Audit_Delete] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMRateOverrideStandardItem_Audit_Delete]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMRateOverrideStandardItem_Audit_Insert ON dbo.vSMRateOverrideStandardItem
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
-- log additions to the AutoAdd column
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
								'vSMRateOverrideStandardItem' , 
								'<KeyString EntitySeq = "' + REPLACE(CAST(ISNULL(inserted.[EntitySeq],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" StandardItem = "' + REPLACE(CAST(ISNULL(inserted.[StandardItem],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'AutoAdd' , 
								NULL , 
								[AutoAdd] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 7

-- log additions to the BillableRate column
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
								'vSMRateOverrideStandardItem' , 
								'<KeyString EntitySeq = "' + REPLACE(CAST(ISNULL(inserted.[EntitySeq],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" StandardItem = "' + REPLACE(CAST(ISNULL(inserted.[StandardItem],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'BillableRate' , 
								NULL , 
								[BillableRate] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 7

-- log additions to the EntitySeq column
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
								'vSMRateOverrideStandardItem' , 
								'<KeyString EntitySeq = "' + REPLACE(CAST(ISNULL(inserted.[EntitySeq],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" StandardItem = "' + REPLACE(CAST(ISNULL(inserted.[StandardItem],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'EntitySeq' , 
								NULL , 
								[EntitySeq] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 7

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
								'vSMRateOverrideStandardItem' , 
								'<KeyString EntitySeq = "' + REPLACE(CAST(ISNULL(inserted.[EntitySeq],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" StandardItem = "' + REPLACE(CAST(ISNULL(inserted.[StandardItem],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'SMCo' , 
								NULL , 
								[SMCo] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 7

-- log additions to the SMRateOverrideStandardItemID column
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
								'vSMRateOverrideStandardItem' , 
								'<KeyString EntitySeq = "' + REPLACE(CAST(ISNULL(inserted.[EntitySeq],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" StandardItem = "' + REPLACE(CAST(ISNULL(inserted.[StandardItem],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'SMRateOverrideStandardItemID' , 
								NULL , 
								[SMRateOverrideStandardItemID] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 7

-- log additions to the StandardItem column
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
								'vSMRateOverrideStandardItem' , 
								'<KeyString EntitySeq = "' + REPLACE(CAST(ISNULL(inserted.[EntitySeq],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" StandardItem = "' + REPLACE(CAST(ISNULL(inserted.[StandardItem],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'StandardItem' , 
								NULL , 
								[StandardItem] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 7

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT DISTINCT Keys.AuditID, 'bSMCo', i.SMCo, CAST(i.SMCo AS VARCHAR(30)), 'vSMRateOverrideStandardItem'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString EntitySeq = "' + REPLACE(CAST(ISNULL(i.[EntitySeq],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(i.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" StandardItem = "' + REPLACE(CAST(ISNULL(i.[StandardItem],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMRateOverrideStandardItem_Audit_Insert] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMRateOverrideStandardItem_Audit_Insert]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMRateOverrideStandardItem_Audit_Update ON dbo.vSMRateOverrideStandardItem
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
							IF UPDATE([AutoAdd])
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
								SELECT 							'vSMRateOverrideStandardItem' , 								'<KeyString EntitySeq = "' + REPLACE(CAST(ISNULL(inserted.[EntitySeq],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" StandardItem = "' + REPLACE(CAST(ISNULL(inserted.[StandardItem],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'AutoAdd' , 								CONVERT(VARCHAR(MAX), deleted.[AutoAdd]) , 								CONVERT(VARCHAR(MAX), inserted.[AutoAdd]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMRateOverrideStandardItemID] = deleted.[SMRateOverrideStandardItemID] 
									AND ((inserted.[AutoAdd] <> deleted.[AutoAdd]) OR (inserted.[AutoAdd] IS NULL AND deleted.[AutoAdd] IS NOT NULL) OR (inserted.[AutoAdd] IS NOT NULL AND deleted.[AutoAdd] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 7

							END 

							IF UPDATE([BillableRate])
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
								SELECT 							'vSMRateOverrideStandardItem' , 								'<KeyString EntitySeq = "' + REPLACE(CAST(ISNULL(inserted.[EntitySeq],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" StandardItem = "' + REPLACE(CAST(ISNULL(inserted.[StandardItem],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'BillableRate' , 								CONVERT(VARCHAR(MAX), deleted.[BillableRate]) , 								CONVERT(VARCHAR(MAX), inserted.[BillableRate]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMRateOverrideStandardItemID] = deleted.[SMRateOverrideStandardItemID] 
									AND ((inserted.[BillableRate] <> deleted.[BillableRate]) OR (inserted.[BillableRate] IS NULL AND deleted.[BillableRate] IS NOT NULL) OR (inserted.[BillableRate] IS NOT NULL AND deleted.[BillableRate] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 7

							END 

							IF UPDATE([EntitySeq])
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
								SELECT 							'vSMRateOverrideStandardItem' , 								'<KeyString EntitySeq = "' + REPLACE(CAST(ISNULL(inserted.[EntitySeq],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" StandardItem = "' + REPLACE(CAST(ISNULL(inserted.[StandardItem],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'EntitySeq' , 								CONVERT(VARCHAR(MAX), deleted.[EntitySeq]) , 								CONVERT(VARCHAR(MAX), inserted.[EntitySeq]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMRateOverrideStandardItemID] = deleted.[SMRateOverrideStandardItemID] 
									AND ((inserted.[EntitySeq] <> deleted.[EntitySeq]) OR (inserted.[EntitySeq] IS NULL AND deleted.[EntitySeq] IS NOT NULL) OR (inserted.[EntitySeq] IS NOT NULL AND deleted.[EntitySeq] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 7

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
								SELECT 							'vSMRateOverrideStandardItem' , 								'<KeyString EntitySeq = "' + REPLACE(CAST(ISNULL(inserted.[EntitySeq],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" StandardItem = "' + REPLACE(CAST(ISNULL(inserted.[StandardItem],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'SMCo' , 								CONVERT(VARCHAR(MAX), deleted.[SMCo]) , 								CONVERT(VARCHAR(MAX), inserted.[SMCo]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMRateOverrideStandardItemID] = deleted.[SMRateOverrideStandardItemID] 
									AND ((inserted.[SMCo] <> deleted.[SMCo]) OR (inserted.[SMCo] IS NULL AND deleted.[SMCo] IS NOT NULL) OR (inserted.[SMCo] IS NOT NULL AND deleted.[SMCo] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 7

							END 

							IF UPDATE([SMRateOverrideStandardItemID])
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
								SELECT 							'vSMRateOverrideStandardItem' , 								'<KeyString EntitySeq = "' + REPLACE(CAST(ISNULL(inserted.[EntitySeq],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" StandardItem = "' + REPLACE(CAST(ISNULL(inserted.[StandardItem],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'SMRateOverrideStandardItemID' , 								CONVERT(VARCHAR(MAX), deleted.[SMRateOverrideStandardItemID]) , 								CONVERT(VARCHAR(MAX), inserted.[SMRateOverrideStandardItemID]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMRateOverrideStandardItemID] = deleted.[SMRateOverrideStandardItemID] 
									AND ((inserted.[SMRateOverrideStandardItemID] <> deleted.[SMRateOverrideStandardItemID]) OR (inserted.[SMRateOverrideStandardItemID] IS NULL AND deleted.[SMRateOverrideStandardItemID] IS NOT NULL) OR (inserted.[SMRateOverrideStandardItemID] IS NOT NULL AND deleted.[SMRateOverrideStandardItemID] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 7

							END 

							IF UPDATE([StandardItem])
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
								SELECT 							'vSMRateOverrideStandardItem' , 								'<KeyString EntitySeq = "' + REPLACE(CAST(ISNULL(inserted.[EntitySeq],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" StandardItem = "' + REPLACE(CAST(ISNULL(inserted.[StandardItem],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'StandardItem' , 								CONVERT(VARCHAR(MAX), deleted.[StandardItem]) , 								CONVERT(VARCHAR(MAX), inserted.[StandardItem]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMRateOverrideStandardItemID] = deleted.[SMRateOverrideStandardItemID] 
									AND ((inserted.[StandardItem] <> deleted.[StandardItem]) OR (inserted.[StandardItem] IS NULL AND deleted.[StandardItem] IS NOT NULL) OR (inserted.[StandardItem] IS NOT NULL AND deleted.[StandardItem] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 7

							END 

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT DISTINCT Keys.AuditID, 'bSMCo', i.SMCo, CAST(i.SMCo AS VARCHAR(30)), 'vSMRateOverrideStandardItem'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString EntitySeq = "' + REPLACE(CAST(ISNULL(i.[EntitySeq],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(i.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" StandardItem = "' + REPLACE(CAST(ISNULL(i.[StandardItem],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />'


 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMRateOverrideStandardItem_Audit_Update] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMRateOverrideStandardItem_Audit_Update]', 'last', 'update', null
GO
ALTER TABLE [dbo].[vSMRateOverrideStandardItem] ADD CONSTRAINT [PK_vSMRateOverrideStandardItem] PRIMARY KEY CLUSTERED  ([SMRateOverrideStandardItemID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMRateOverrideStandardItem] ADD CONSTRAINT [IX_vSMRateOverrideStandardItem_SMCo_EntitySeq_StandardItem] UNIQUE NONCLUSTERED  ([SMCo], [EntitySeq], [StandardItem]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMRateOverrideStandardItem] WITH NOCHECK ADD CONSTRAINT [FK_vSMRateOverrideStandardItem_vSMEntity] FOREIGN KEY ([SMCo], [EntitySeq]) REFERENCES [dbo].[vSMEntity] ([SMCo], [EntitySeq]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vSMRateOverrideStandardItem] NOCHECK CONSTRAINT [FK_vSMRateOverrideStandardItem_vSMEntity]
GO