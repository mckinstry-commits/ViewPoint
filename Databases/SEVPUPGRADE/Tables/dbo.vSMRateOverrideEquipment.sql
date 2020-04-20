CREATE TABLE [dbo].[vSMRateOverrideEquipment]
(
[SMRateOverrideEquipID] [bigint] NOT NULL IDENTITY(1, 1),
[SMRateOverrideID] [bigint] NOT NULL,
[EMCo] [dbo].[bCompany] NOT NULL,
[Equipment] [dbo].[bEquip] NOT NULL,
[RevCode] [dbo].[bRevCode] NOT NULL,
[MarkupOrFlatRate] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[MarkupAmount] [dbo].[bUnitCost] NULL,
[FlatRateAmount] [dbo].[bUnitCost] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtvSMRateOverrideEquipment_AuditSM_Delete] ON [dbo].[vSMRateOverrideEquipment]
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

		SELECT @TableName = 'vSMRateOverrideEquipment'

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
		
		--Audit MarkupOrFlatRate----------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(deleted.SMRateOverrideID) + '" EMCo = "' + dbo.vfToString(deleted.EMCo) + '" Equipment = "' + dbo.vfToString(deleted.Equipment) + '" RevCode = "' + dbo.vfToString(deleted.RevCode) + '" />', Audit.AuditCo, 'D', 'MarkupOrFlatRate', dbo.vfToString(deleted.[MarkupOrFlatRate]), NULL, GETDATE(), SUSER_SNAME()
		FROM deleted
			  CROSS APPLY (
					SELECT TOP 1 AuditCo
					FROM @RecordsToAudit
					WHERE KeyID = deleted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit MarkupAmount--------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(deleted.SMRateOverrideID) + '" EMCo = "' + dbo.vfToString(deleted.EMCo) + '" Equipment = "' + dbo.vfToString(deleted.Equipment) + '" RevCode = "' + dbo.vfToString(deleted.RevCode) + '" />', Audit.AuditCo, 'D', 'MarkupAmount', dbo.vfToString(deleted.[MarkupAmount]), NULL, GETDATE(), SUSER_SNAME()
		FROM deleted
			  CROSS APPLY (
					SELECT TOP 1 AuditCo
					FROM @RecordsToAudit
					WHERE KeyID = deleted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit FlatRateAmount--------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(deleted.SMRateOverrideID) + '" EMCo = "' + dbo.vfToString(deleted.EMCo) + '" Equipment = "' + dbo.vfToString(deleted.Equipment) + '" RevCode = "' + dbo.vfToString(deleted.RevCode) + '" />', Audit.AuditCo, 'D', 'FlatRateAmount', dbo.vfToString(deleted.[FlatRateAmount]), NULL, GETDATE(), SUSER_SNAME()
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

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[vtvSMRateOverrideEquipment_AuditSM_Delete] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMRateOverrideEquipment_AuditSM_Delete]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtvSMRateOverrideEquipment_AuditSM_Insert] ON [dbo].[vSMRateOverrideEquipment]
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

		SELECT @TableName = 'vSMRateOverrideEquipment'

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
		
		--Audit MarkupOrFlatRate----------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(inserted.SMRateOverrideID) + '" EMCo = "' + dbo.vfToString(inserted.EMCo) + '" Equipment = "' + dbo.vfToString(inserted.Equipment) + '" RevCode = "' + dbo.vfToString(inserted.RevCode) + '" />', Audit.AuditCo, 'A', 'MarkupOrFlatRate', NULL, dbo.vfToString(inserted.[MarkupOrFlatRate]), GETDATE(), SUSER_SNAME()
		FROM inserted
			CROSS APPLY (
				SELECT TOP 1 AuditCo
				FROM @RecordsToAudit
				WHERE KeyID = inserted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit MarkupAmount--------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(inserted.SMRateOverrideID) + '" EMCo = "' + dbo.vfToString(inserted.EMCo) + '" Equipment = "' + dbo.vfToString(inserted.Equipment) + '" RevCode = "' + dbo.vfToString(inserted.RevCode) + '" />', Audit.AuditCo, 'A', 'MarkupAmount', NULL, dbo.vfToString(inserted.[MarkupAmount]), GETDATE(), SUSER_SNAME()
		FROM inserted
			CROSS APPLY (
				SELECT TOP 1 AuditCo
				FROM @RecordsToAudit
				WHERE KeyID = inserted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit FlatRateAmount------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(inserted.SMRateOverrideID) + '" EMCo = "' + dbo.vfToString(inserted.EMCo) + '" Equipment = "' + dbo.vfToString(inserted.Equipment) + '" RevCode = "' + dbo.vfToString(inserted.RevCode) + '" />', Audit.AuditCo, 'A', 'FlatRateAmount', NULL, dbo.vfToString(inserted.[FlatRateAmount]), GETDATE(), SUSER_SNAME()
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

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[vtvSMRateOverrideEquipment_AuditSM_Insert] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMRateOverrideEquipment_AuditSM_Insert]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtvSMRateOverrideEquipment_AuditSM_Update] ON [dbo].[vSMRateOverrideEquipment]
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

		SELECT @TableName = 'vSMRateOverrideEquipment'

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

		--Audit MarkupOrFlatRate----------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(inserted.SMRateOverrideID) + '" EMCo = "' + dbo.vfToString(inserted.EMCo) + '" Equipment = "' + dbo.vfToString(inserted.Equipment) + '" RevCode = "' + dbo.vfToString(inserted.RevCode) + '" />', Audit.AuditCo, 'C', 'MarkupOrFlatRate', dbo.vfToString(deleted.[MarkupOrFlatRate]), dbo.vfToString(inserted.[MarkupOrFlatRate]), GETDATE(), SUSER_SNAME()
		FROM inserted
			JOIN deleted ON inserted.SMRateOverrideEquipID = deleted.SMRateOverrideEquipID
				AND dbo.vfIsEqual(inserted.MarkupOrFlatRate, deleted.MarkupOrFlatRate) = 0
			CROSS APPLY (
				SELECT TOP 1 AuditCo
				FROM @RecordsToAudit
				WHERE KeyID = inserted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit MarkupAmount--------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(inserted.SMRateOverrideID) + '" EMCo = "' + dbo.vfToString(inserted.EMCo) + '" Equipment = "' + dbo.vfToString(inserted.Equipment) + '" RevCode = "' + dbo.vfToString(inserted.RevCode) + '" />', Audit.AuditCo, 'C', 'MarkupAmount', dbo.vfToString(deleted.[MarkupAmount]), dbo.vfToString(inserted.[MarkupAmount]), GETDATE(), SUSER_SNAME()
		FROM inserted
			JOIN deleted ON inserted.SMRateOverrideEquipID = deleted.SMRateOverrideEquipID
				AND dbo.vfIsEqual(inserted.MarkupAmount, deleted.MarkupAmount) = 0
			CROSS APPLY (
				SELECT TOP 1 AuditCo
				FROM @RecordsToAudit
				WHERE KeyID = inserted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit FlatRateAmount------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(inserted.SMRateOverrideID) + '" EMCo = "' + dbo.vfToString(inserted.EMCo) + '" Equipment = "' + dbo.vfToString(inserted.Equipment) + '" RevCode = "' + dbo.vfToString(inserted.RevCode) + '" />', Audit.AuditCo, 'C', 'FlatRateAmount', dbo.vfToString(deleted.[FlatRateAmount]), dbo.vfToString(inserted.[FlatRateAmount]), GETDATE(), SUSER_SNAME()
		FROM inserted
			JOIN deleted ON inserted.SMRateOverrideEquipID = deleted.SMRateOverrideEquipID
				AND dbo.vfIsEqual(inserted.FlatRateAmount, deleted.FlatRateAmount) = 0
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

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[vtvSMRateOverrideEquipment_AuditSM_Update] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMRateOverrideEquipment_AuditSM_Update]', 'last', 'update', null
GO
ALTER TABLE [dbo].[vSMRateOverrideEquipment] ADD CONSTRAINT [PK_vSMRateOverrideEquipment] PRIMARY KEY CLUSTERED  ([SMRateOverrideEquipID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMRateOverrideEquipment] ADD CONSTRAINT [IX_vSMRateOverrideEquipment] UNIQUE NONCLUSTERED  ([SMRateOverrideID], [EMCo], [Equipment], [RevCode]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMRateOverrideEquipment] WITH NOCHECK ADD CONSTRAINT [FK_vSMRateOverrideEquipment_bEMEM] FOREIGN KEY ([EMCo], [Equipment]) REFERENCES [dbo].[bEMEM] ([EMCo], [Equipment]) ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[vSMRateOverrideEquipment] WITH NOCHECK ADD CONSTRAINT [FK_vSMRateOverrideEquipment_vSMRateOverride] FOREIGN KEY ([SMRateOverrideID]) REFERENCES [dbo].[vSMRateOverride] ([SMRateOverrideID]) ON DELETE CASCADE
GO
