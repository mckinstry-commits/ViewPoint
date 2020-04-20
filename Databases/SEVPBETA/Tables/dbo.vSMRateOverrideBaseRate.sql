CREATE TABLE [dbo].[vSMRateOverrideBaseRate]
(
[SMRateOverrideID] [bigint] NOT NULL,
[LaborRate] [dbo].[bUnitCost] NULL,
[EquipmentMarkup] [dbo].[bUnitCost] NULL,
[MaterialMarkupOrDiscount] [char] (1) COLLATE Latin1_General_BIN NULL,
[MaterialBasis] [char] (1) COLLATE Latin1_General_BIN NULL,
[MaterialPercent] [dbo].[bUnitCost] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtvSMRateOverrideBaseRate_AuditSM_Delete] ON [dbo].[vSMRateOverrideBaseRate]
 AFTER DELETE
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 

	BEGIN TRY 
		DECLARE @HQMAKeys TABLE
		(
			  AuditID		bigint
			, AuditCo		bCompany
		);
		
		DECLARE @TableName char(30), @AuditFlagID smallint

		SELECT @TableName = 'vSMRateOverrideBaseRate'

		SELECT @AuditFlagID = KeyID
		FROM dbo.vAuditFlags
		WHERE FlagName = 'SMRates' AND Module = 'SM'

		DECLARE @RecordsToAudit TABLE (KeyID bigint, AuditCo bCompany)

		INSERT @RecordsToAudit
		SELECT DISTINCT deleted.SMRateOverrideID, vAuditFlagCompany.AuditCo
		FROM deleted
			  LEFT JOIN dbo.vSMRateTemplate ON vSMRateTemplate.SMRateOverrideID = deleted.SMRateOverrideID
			  LEFT JOIN dbo.vSMRateTemplateEffectiveDate ON vSMRateTemplateEffectiveDate.SMRateOverrideID = deleted.SMRateOverrideID
			  LEFT JOIN dbo.vSMCustomer ON vSMCustomer.SMRateOverrideID = deleted.SMRateOverrideID
			  LEFT JOIN dbo.vSMServiceSite ON vSMServiceSite.SMRateOverrideID = deleted.SMRateOverrideID
			  INNER JOIN dbo.vAuditFlagCompany ON vAuditFlagCompany.AuditCo IN (vSMRateTemplate.SMCo, vSMRateTemplateEffectiveDate.SMCo, vSMCustomer.SMCo, vSMServiceSite.SMCo)
		WHERE AuditFlagID = @AuditFlagID

		--Audit LaborRate--------------------
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
			OUTPUT inserted.AuditID, inserted.Co INTO @HQMAKeys (AuditID, AuditCo) 
		SELECT @TableName, '<KeyString SMRateOverrideID = "' + dbo.vfToString(deleted.SMRateOverrideID) + '" />', Audit.AuditCo, 'D', 'LaborRate', dbo.vfToString(deleted.[LaborRate]), NULL, GETDATE(), SUSER_SNAME()
		FROM deleted
			  CROSS APPLY (
					SELECT TOP 1 AuditCo
					FROM @RecordsToAudit
					WHERE KeyID = deleted.SMRateOverrideID) Audit
		----------------------------------------

		--Audit EquipmentMarkup-----------------
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
			OUTPUT inserted.AuditID, inserted.Co INTO @HQMAKeys (AuditID, AuditCo) 
		SELECT @TableName, '<KeyString SMRateOverrideID = "' + dbo.vfToString(deleted.SMRateOverrideID) + '" />', Audit.AuditCo, 'D', 'EquipmentMarkup', dbo.vfToString(deleted.[EquipmentMarkup]), NULL, GETDATE(), SUSER_SNAME()
		FROM deleted
			  CROSS APPLY (
					SELECT TOP 1 AuditCo
					FROM @RecordsToAudit
					WHERE KeyID = deleted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit MaterialMarkupOrDiscount--------
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
			OUTPUT inserted.AuditID, inserted.Co INTO @HQMAKeys (AuditID, AuditCo) 
		SELECT @TableName, '<KeyString SMRateOverrideID = "' + dbo.vfToString(deleted.SMRateOverrideID) + '" />', Audit.AuditCo, 'D', 'MaterialMarkupOrDiscount', dbo.vfToString(deleted.[MaterialMarkupOrDiscount]), NULL, GETDATE(), SUSER_SNAME()
		FROM deleted
			  CROSS APPLY (
					SELECT TOP 1 AuditCo
					FROM @RecordsToAudit
					WHERE KeyID = deleted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit MaterialBasis-------------------
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
			OUTPUT inserted.AuditID, inserted.Co INTO @HQMAKeys (AuditID, AuditCo) 
		SELECT @TableName, '<KeyString SMRateOverrideID = "' + dbo.vfToString(deleted.SMRateOverrideID) + '" />', Audit.AuditCo, 'D', 'MaterialBasis', dbo.vfToString(deleted.[MaterialBasis]), NULL, GETDATE(), SUSER_SNAME()
		FROM deleted
			  CROSS APPLY (
					SELECT TOP 1 AuditCo
					FROM @RecordsToAudit
					WHERE KeyID = deleted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit MaterialPercent-----------------
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
			OUTPUT inserted.AuditID, inserted.Co INTO @HQMAKeys (AuditID, AuditCo) 
		SELECT @TableName, '<KeyString SMRateOverrideID = "' + dbo.vfToString(deleted.SMRateOverrideID) + '" />', Audit.AuditCo, 'D', 'MaterialPercent', dbo.vfToString(deleted.[MaterialPercent]), NULL, GETDATE(), SUSER_SNAME()
		FROM deleted
			  CROSS APPLY (
					SELECT TOP 1 AuditCo
					FROM @RecordsToAudit
					WHERE KeyID = deleted.SMRateOverrideID) Audit
		----------------------------------------
		
		INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
		SELECT AuditID, 'bSMCo', AuditCo, dbo.vfToString(AuditCo), @TableName
		FROM @HQMAKeys
		
 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[vtvSMRateOverrideBaseRate_AuditSM_Delete] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMRateOverrideBaseRate_AuditSM_Delete]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtvSMRateOverrideBaseRate_AuditSM_Insert] ON [dbo].[vSMRateOverrideBaseRate]
 AFTER INSERT
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 

 BEGIN TRY 
		DECLARE @HQMAKeys TABLE
		(
			  AuditID		bigint
			, AuditCo		bCompany
		);
		
		DECLARE @TableName char(30), @AuditFlagID smallint

		SELECT @TableName = 'vSMRateOverrideBaseRate'

		SELECT @AuditFlagID = KeyID
		FROM dbo.vAuditFlags
		WHERE FlagName = 'SMRates' AND Module = 'SM'

		DECLARE @RecordsToAudit TABLE (KeyID bigint, AuditCo bCompany)

		INSERT @RecordsToAudit
		SELECT DISTINCT inserted.SMRateOverrideID, vAuditFlagCompany.AuditCo
		FROM inserted
			  LEFT JOIN dbo.vSMRateTemplate ON vSMRateTemplate.SMRateOverrideID = inserted.SMRateOverrideID
			  LEFT JOIN dbo.vSMRateTemplateEffectiveDate ON vSMRateTemplateEffectiveDate.SMRateOverrideID = inserted.SMRateOverrideID
			  LEFT JOIN dbo.vSMCustomer ON vSMCustomer.SMRateOverrideID = inserted.SMRateOverrideID
			  LEFT JOIN dbo.vSMServiceSite ON vSMServiceSite.SMRateOverrideID = inserted.SMRateOverrideID
			  INNER JOIN dbo.vAuditFlagCompany ON vAuditFlagCompany.AuditCo IN (vSMRateTemplate.SMCo, vSMRateTemplateEffectiveDate.SMCo, vSMCustomer.SMCo, vSMServiceSite.SMCo)
		WHERE AuditFlagID = @AuditFlagID

		--Audit LaborRate--------------------
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
			OUTPUT inserted.AuditID, inserted.Co INTO @HQMAKeys (AuditID, AuditCo) 
		SELECT @TableName, '<KeyString SMRateOverrideID = "' + dbo.vfToString(inserted.SMRateOverrideID) + '" />', Audit.AuditCo, 'A', 'LaborRate', NULL, dbo.vfToString(inserted.[LaborRate]), GETDATE(), SUSER_SNAME()
		FROM inserted
			CROSS APPLY (
				SELECT TOP 1 AuditCo
				FROM @RecordsToAudit
				WHERE KeyID = inserted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit EquipmentMarkup--------------------
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
			OUTPUT inserted.AuditID, inserted.Co INTO @HQMAKeys (AuditID, AuditCo) 
		SELECT @TableName, '<KeyString SMRateOverrideID = "' + dbo.vfToString(inserted.SMRateOverrideID) + '" />', Audit.AuditCo, 'A', 'EquipmentMarkup', NULL, dbo.vfToString(inserted.[EquipmentMarkup]), GETDATE(), SUSER_SNAME()
		FROM inserted
			CROSS APPLY (
				SELECT TOP 1 AuditCo
				FROM @RecordsToAudit
				WHERE KeyID = inserted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit MaterialMarkupOrDiscount--------
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
			OUTPUT inserted.AuditID, inserted.Co INTO @HQMAKeys (AuditID, AuditCo) 
		SELECT @TableName, '<KeyString SMRateOverrideID = "' + dbo.vfToString(inserted.SMRateOverrideID) + '" />', Audit.AuditCo, 'A', 'MaterialMarkupOrDiscount', NULL, dbo.vfToString(inserted.[MaterialMarkupOrDiscount]), GETDATE(), SUSER_SNAME()
		FROM inserted
			CROSS APPLY (
				SELECT TOP 1 AuditCo
				FROM @RecordsToAudit
				WHERE KeyID = inserted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit MaterialBasis-------------------
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
			OUTPUT inserted.AuditID, inserted.Co INTO @HQMAKeys (AuditID, AuditCo) 
		SELECT @TableName, '<KeyString SMRateOverrideID = "' + dbo.vfToString(inserted.SMRateOverrideID) + '" />', Audit.AuditCo, 'A', 'MaterialBasis', NULL, dbo.vfToString(inserted.[MaterialBasis]), GETDATE(), SUSER_SNAME()
		FROM inserted
			CROSS APPLY (
				SELECT TOP 1 AuditCo
				FROM @RecordsToAudit
				WHERE KeyID = inserted.SMRateOverrideID) Audit
		----------------------------------------

		--Audit MaterialPercent-----------------
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
			OUTPUT inserted.AuditID, inserted.Co INTO @HQMAKeys (AuditID, AuditCo) 
		SELECT @TableName, '<KeyString SMRateOverrideID = "' + dbo.vfToString(inserted.SMRateOverrideID) + '" />', Audit.AuditCo, 'A', 'MaterialPercent', NULL, dbo.vfToString(inserted.[MaterialPercent]), GETDATE(), SUSER_SNAME()
		FROM inserted
			CROSS APPLY (
				SELECT TOP 1 AuditCo
				FROM @RecordsToAudit
				WHERE KeyID = inserted.SMRateOverrideID) Audit
		----------------------------------------

		INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
		SELECT AuditID, 'bSMCo', AuditCo, dbo.vfToString(AuditCo), @TableName
		FROM @HQMAKeys

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[vtvSMRateOverrideBaseRate_AuditSM_Insert] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMRateOverrideBaseRate_AuditSM_Insert]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtvSMRateOverrideBaseRate_AuditSM_Update] ON [dbo].[vSMRateOverrideBaseRate]
 AFTER UPDATE
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 

 BEGIN TRY 
		DECLARE @HQMAKeys TABLE
		(
			  AuditID		bigint
			, AuditCo		bCompany
		);
		
		DECLARE @TableName char(30), @AuditFlagID smallint

		SELECT @TableName = 'vSMRateOverrideBaseRate'

		SELECT @AuditFlagID = KeyID
		FROM dbo.vAuditFlags
		WHERE FlagName = 'SMRates' AND Module = 'SM'

		DECLARE @RecordsToAudit TABLE (KeyID bigint, AuditCo bCompany)

		INSERT @RecordsToAudit
		SELECT DISTINCT inserted.SMRateOverrideID, vAuditFlagCompany.AuditCo
		FROM inserted
			  LEFT JOIN dbo.vSMRateTemplate ON vSMRateTemplate.SMRateOverrideID = inserted.SMRateOverrideID
			  LEFT JOIN dbo.vSMRateTemplateEffectiveDate ON vSMRateTemplateEffectiveDate.SMRateOverrideID = inserted.SMRateOverrideID
			  LEFT JOIN dbo.vSMCustomer ON vSMCustomer.SMRateOverrideID = inserted.SMRateOverrideID
			  LEFT JOIN dbo.vSMServiceSite ON vSMServiceSite.SMRateOverrideID = inserted.SMRateOverrideID
			  INNER JOIN dbo.vAuditFlagCompany ON vAuditFlagCompany.AuditCo IN (vSMRateTemplate.SMCo, vSMRateTemplateEffectiveDate.SMCo, vSMCustomer.SMCo, vSMServiceSite.SMCo)
		WHERE AuditFlagID = @AuditFlagID
		
		--Audit LaborRate-----------------------
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
			OUTPUT inserted.AuditID, inserted.Co INTO @HQMAKeys (AuditID, AuditCo) 
		SELECT @TableName, '<KeyString SMRateOverrideID = "' + dbo.vfToString(inserted.SMRateOverrideID) + '" />', Audit.AuditCo, 'C', 'LaborRate', dbo.vfToString(deleted.[LaborRate]), dbo.vfToString(inserted.[LaborRate]), GETDATE(), SUSER_SNAME()
		FROM inserted
			JOIN deleted ON inserted.SMRateOverrideID = deleted.SMRateOverrideID
				AND dbo.vfIsEqual(inserted.LaborRate, deleted.LaborRate) = 0
			CROSS APPLY (
				SELECT TOP 1 AuditCo
				FROM @RecordsToAudit
				WHERE KeyID = inserted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit EquipmentMarkup-----------------
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
			OUTPUT inserted.AuditID, inserted.Co INTO @HQMAKeys (AuditID, AuditCo) 
		SELECT @TableName, '<KeyString SMRateOverrideID = "' + dbo.vfToString(inserted.SMRateOverrideID) + '" />', Audit.AuditCo, 'C', 'EquipmentMarkup', dbo.vfToString(deleted.[EquipmentMarkup]), dbo.vfToString(inserted.[EquipmentMarkup]), GETDATE(), SUSER_SNAME()
		FROM inserted
			JOIN deleted ON inserted.SMRateOverrideID = deleted.SMRateOverrideID
				AND dbo.vfIsEqual(inserted.EquipmentMarkup, deleted.EquipmentMarkup) = 0
			CROSS APPLY (
				SELECT TOP 1 AuditCo
				FROM @RecordsToAudit
				WHERE KeyID = inserted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit MaterialMarkupOrDiscount--------
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
			OUTPUT inserted.AuditID, inserted.Co INTO @HQMAKeys (AuditID, AuditCo) 
		SELECT @TableName, '<KeyString SMRateOverrideID = "' + dbo.vfToString(inserted.SMRateOverrideID) + '" />', Audit.AuditCo, 'C', 'MaterialMarkupOrDiscount', dbo.vfToString(deleted.[MaterialMarkupOrDiscount]), dbo.vfToString(inserted.[MaterialMarkupOrDiscount]), GETDATE(), SUSER_SNAME()
		FROM inserted
			JOIN deleted ON inserted.SMRateOverrideID = deleted.SMRateOverrideID
				AND dbo.vfIsEqual(inserted.MaterialMarkupOrDiscount, deleted.MaterialMarkupOrDiscount) = 0
			CROSS APPLY (
				SELECT TOP 1 AuditCo
				FROM @RecordsToAudit
				WHERE KeyID = inserted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit MaterialBasis-------------------
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
			OUTPUT inserted.AuditID, inserted.Co INTO @HQMAKeys (AuditID, AuditCo) 
		SELECT @TableName, '<KeyString SMRateOverrideID = "' + dbo.vfToString(inserted.SMRateOverrideID) + '" />', Audit.AuditCo, 'C', 'MaterialBasis', dbo.vfToString(deleted.[MaterialBasis]), dbo.vfToString(inserted.[MaterialBasis]), GETDATE(), SUSER_SNAME()
		FROM inserted
			JOIN deleted ON inserted.SMRateOverrideID = deleted.SMRateOverrideID
				AND dbo.vfIsEqual(inserted.MaterialBasis, deleted.MaterialBasis) = 0
			CROSS APPLY (
				SELECT TOP 1 AuditCo
				FROM @RecordsToAudit
				WHERE KeyID = inserted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit MaterialPercent-------------------
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
			OUTPUT inserted.AuditID, inserted.Co INTO @HQMAKeys (AuditID, AuditCo) 
		SELECT @TableName, '<KeyString SMRateOverrideID = "' + dbo.vfToString(inserted.SMRateOverrideID) + '" />', Audit.AuditCo, 'C', 'MaterialPercent', dbo.vfToString(deleted.[MaterialPercent]), dbo.vfToString(inserted.[MaterialPercent]), GETDATE(), SUSER_SNAME()
		FROM inserted
			JOIN deleted ON inserted.SMRateOverrideID = deleted.SMRateOverrideID
				AND dbo.vfIsEqual(inserted.MaterialPercent, deleted.MaterialPercent) = 0
			CROSS APPLY (
				SELECT TOP 1 AuditCo
				FROM @RecordsToAudit
				WHERE KeyID = inserted.SMRateOverrideID) Audit
		----------------------------------------

		INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
		SELECT AuditID, 'bSMCo', AuditCo, dbo.vfToString(AuditCo), @TableName
		FROM @HQMAKeys

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[vtvSMRateOverrideBaseRate_AuditSM_Update] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMRateOverrideBaseRate_AuditSM_Update]', 'last', 'update', null
GO
ALTER TABLE [dbo].[vSMRateOverrideBaseRate] ADD CONSTRAINT [PK_vSMRateOverrideBaseRate] PRIMARY KEY CLUSTERED  ([SMRateOverrideID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMRateOverrideBaseRate] WITH NOCHECK ADD CONSTRAINT [FK_vSMRateOverrideBaseRate_vSMRateOverride] FOREIGN KEY ([SMRateOverrideID]) REFERENCES [dbo].[vSMRateOverride] ([SMRateOverrideID]) ON DELETE CASCADE
GO
