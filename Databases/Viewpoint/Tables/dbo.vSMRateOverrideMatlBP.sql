CREATE TABLE [dbo].[vSMRateOverrideMatlBP]
(
[SMRateOverrideMatlBPID] [bigint] NOT NULL IDENTITY(1, 1),
[SMRateOverrideID] [bigint] NOT NULL,
[RateOverrideMaterialSeq] [int] NULL,
[BreakPoint] [int] NOT NULL,
[Percent] [dbo].[bUnitCost] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtvSMRateOverrideMatlBP_AuditSM_Delete] ON [dbo].[vSMRateOverrideMatlBP]
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

		SELECT @TableName = 'vSMRateOverrideMatlBP'

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

		--Audit Percent-------------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(deleted.SMRateOverrideID) + '"' + dbo.vfToString(CASE WHEN deleted.RateOverrideMaterialSeq IS NOT NULL THEN ' RateOverrideMaterialSeq = "' + dbo.vfToString(deleted.RateOverrideMaterialSeq) + '"' END) + ' BreakPoint = "' + dbo.vfToString(deleted.BreakPoint) + '" />', Audit.AuditCo, 'D', 'Percent', dbo.vfToString(deleted.[Percent]), NULL, GETDATE(), SUSER_SNAME()
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

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[vtvSMRateOverrideMatlBP_AuditSM_Delete] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMRateOverrideMatlBP_AuditSM_Delete]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtvSMRateOverrideMatlBP_AuditSM_Insert] ON [dbo].[vSMRateOverrideMatlBP]
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

		SELECT @TableName = 'vSMRateOverrideMatlBP'

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
 
		--Audit Percent-------------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(inserted.SMRateOverrideID) + '"' + dbo.vfToString(CASE WHEN inserted.RateOverrideMaterialSeq IS NOT NULL THEN ' RateOverrideMaterialSeq = "' + dbo.vfToString(inserted.RateOverrideMaterialSeq) + '"' END) + ' BreakPoint = "' + dbo.vfToString(inserted.BreakPoint) + '" />', Audit.AuditCo, 'A', 'Percent', NULL, dbo.vfToString(inserted.[Percent]), GETDATE(), SUSER_SNAME()
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

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[vtvSMRateOverrideMatlBP_AuditSM_Insert] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMRateOverrideMatlBP_AuditSM_Insert]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtvSMRateOverrideMatlBP_AuditSM_Update] ON [dbo].[vSMRateOverrideMatlBP]
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

		SELECT @TableName = 'vSMRateOverrideMatlBP'

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
 
		--Audit Percent-------------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(inserted.SMRateOverrideID) + '"' + dbo.vfToString(CASE WHEN inserted.RateOverrideMaterialSeq IS NOT NULL THEN ' RateOverrideMaterialSeq = "' + dbo.vfToString(inserted.RateOverrideMaterialSeq) + '"' END) + ' BreakPoint = "' + dbo.vfToString(inserted.BreakPoint) + '" />', Audit.AuditCo, 'C', 'Percent', dbo.vfToString(deleted.[Percent]), dbo.vfToString(inserted.[Percent]), GETDATE(), SUSER_SNAME()
		FROM inserted
			JOIN deleted ON inserted.SMRateOverrideMatlBPID = deleted.SMRateOverrideMatlBPID
				AND dbo.vfIsEqual(inserted.[Percent], deleted.[Percent]) = 0
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

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[vtvSMRateOverrideMatlBP_AuditSM_Update] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMRateOverrideMatlBP_AuditSM_Update]', 'last', 'update', null
GO
ALTER TABLE [dbo].[vSMRateOverrideMatlBP] ADD CONSTRAINT [PK_vSMRateOverrideMatlBP] PRIMARY KEY CLUSTERED  ([SMRateOverrideMatlBPID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMRateOverrideMatlBP] ADD CONSTRAINT [IX_vSMRateOverrideMatlBP_SMRateOverrideID_RateOverrideMaterialSeq_BreakPoint] UNIQUE NONCLUSTERED  ([SMRateOverrideID], [RateOverrideMaterialSeq], [BreakPoint]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMRateOverrideMatlBP] WITH NOCHECK ADD CONSTRAINT [FK_vSMRateOverrideMatlBP_vSMRateOverride] FOREIGN KEY ([SMRateOverrideID]) REFERENCES [dbo].[vSMRateOverride] ([SMRateOverrideID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vSMRateOverrideMatlBP] WITH NOCHECK ADD CONSTRAINT [FK_vSMRateOverrideMatlBP_vSMRateOverrideMaterial] FOREIGN KEY ([SMRateOverrideID], [RateOverrideMaterialSeq]) REFERENCES [dbo].[vSMRateOverrideMaterial] ([SMRateOverrideID], [Seq])
GO
