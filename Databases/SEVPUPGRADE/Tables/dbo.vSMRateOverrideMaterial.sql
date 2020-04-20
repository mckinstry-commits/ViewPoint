CREATE TABLE [dbo].[vSMRateOverrideMaterial]
(
[SMRateOverrideMaterialID] [bigint] NOT NULL IDENTITY(1, 1),
[SMRateOverrideID] [bigint] NOT NULL,
[Seq] [int] NOT NULL,
[MatlGroup] [dbo].[bGroup] NULL,
[Category] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Material] [dbo].[bMatl] NULL,
[MarkupOrDiscount] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Basis] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Percent] [dbo].[bUnitCost] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtvSMRateOverrideMaterial_AuditSM_Delete] ON [dbo].[vSMRateOverrideMaterial]
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

		SELECT @TableName = 'vSMRateOverrideMaterial'

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


		--Audit MatlGroup--------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(deleted.SMRateOverrideID) + '" Seq = "' + dbo.vfToString(deleted.Seq) + '" />', Audit.AuditCo, 'D', 'MatlGroup', dbo.vfToString(deleted.[MatlGroup]), NULL, GETDATE(), SUSER_SNAME()
		FROM deleted
			  CROSS APPLY (
					SELECT TOP 1 AuditCo
					FROM @RecordsToAudit
					WHERE KeyID = deleted.SMRateOverrideID) Audit
		----------------------------------------

		--Audit Category------------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(deleted.SMRateOverrideID) + '" Seq = "' + dbo.vfToString(deleted.Seq) + '" />', Audit.AuditCo, 'D', 'Category', dbo.vfToString(deleted.[Category]), NULL, GETDATE(), SUSER_SNAME()
		FROM deleted
			  CROSS APPLY (
					SELECT TOP 1 AuditCo
					FROM @RecordsToAudit
					WHERE KeyID = deleted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit Material------------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(deleted.SMRateOverrideID) + '" Seq = "' + dbo.vfToString(deleted.Seq) + '" />', Audit.AuditCo, 'D', 'Material', dbo.vfToString(deleted.[Material]), NULL, GETDATE(), SUSER_SNAME()
		FROM deleted
			  CROSS APPLY (
					SELECT TOP 1 AuditCo
					FROM @RecordsToAudit
					WHERE KeyID = deleted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit MarkupOrDiscount----------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(deleted.SMRateOverrideID) + '" Seq = "' + dbo.vfToString(deleted.Seq) + '" />', Audit.AuditCo, 'D', 'MarkupOrDiscount', dbo.vfToString(deleted.[MarkupOrDiscount]), NULL, GETDATE(), SUSER_SNAME()
		FROM deleted
			  CROSS APPLY (
					SELECT TOP 1 AuditCo
					FROM @RecordsToAudit
					WHERE KeyID = deleted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit Basis---------------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(deleted.SMRateOverrideID) + '" Seq = "' + dbo.vfToString(deleted.Seq) + '" />', Audit.AuditCo, 'D', 'Basis', dbo.vfToString(deleted.[Basis]), NULL, GETDATE(), SUSER_SNAME()
		FROM deleted
			  CROSS APPLY (
					SELECT TOP 1 AuditCo
					FROM @RecordsToAudit
					WHERE KeyID = deleted.SMRateOverrideID) Audit
		----------------------------------------
		
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(deleted.SMRateOverrideID) + '" Seq = "' + dbo.vfToString(deleted.Seq) + '" />', Audit.AuditCo, 'D', 'Percent', dbo.vfToString(deleted.[Percent]), NULL, GETDATE(), SUSER_SNAME()
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

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[vtvSMRateOverrideMaterial_AuditSM_Delete] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMRateOverrideMaterial_AuditSM_Delete]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtvSMRateOverrideMaterial_AuditSM_Insert] ON [dbo].[vSMRateOverrideMaterial]
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

		SELECT @TableName = 'vSMRateOverrideMaterial'

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
 
 
 
		--Audit MatlGroup--------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(inserted.SMRateOverrideID) + '" Seq = "' + dbo.vfToString(inserted.Seq) + '" />', Audit.AuditCo, 'A', 'MatlGroup', NULL, dbo.vfToString(inserted.[MatlGroup]), GETDATE(), SUSER_SNAME()
		FROM inserted
			CROSS APPLY (
				SELECT TOP 1 AuditCo
				FROM @RecordsToAudit
				WHERE KeyID = inserted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit Category------------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(inserted.SMRateOverrideID) + '" Seq = "' + dbo.vfToString(inserted.Seq) + '" />', Audit.AuditCo, 'A', 'Category', NULL, dbo.vfToString(inserted.[Category]), GETDATE(), SUSER_SNAME()
		FROM inserted
			CROSS APPLY (
				SELECT TOP 1 AuditCo
				FROM @RecordsToAudit
				WHERE KeyID = inserted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit Material------------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(inserted.SMRateOverrideID) + '" Seq = "' + dbo.vfToString(inserted.Seq) + '" />', Audit.AuditCo, 'A', 'Material', NULL, dbo.vfToString(inserted.[Material]), GETDATE(), SUSER_SNAME()
		FROM inserted
			CROSS APPLY (
				SELECT TOP 1 AuditCo
				FROM @RecordsToAudit
				WHERE KeyID = inserted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit MarkupOrDiscount----------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(inserted.SMRateOverrideID) + '" Seq = "' + dbo.vfToString(inserted.Seq) + '" />', Audit.AuditCo, 'A', 'MarkupOrDiscount', NULL, dbo.vfToString(inserted.[MarkupOrDiscount]), GETDATE(), SUSER_SNAME()
		FROM inserted
			CROSS APPLY (
				SELECT TOP 1 AuditCo
				FROM @RecordsToAudit
				WHERE KeyID = inserted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit Basis---------------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(inserted.SMRateOverrideID) + '" Seq = "' + dbo.vfToString(inserted.Seq) + '" />', Audit.AuditCo, 'A', 'Basis', NULL, dbo.vfToString(inserted.[Basis]), GETDATE(), SUSER_SNAME()
		FROM inserted
			CROSS APPLY (
				SELECT TOP 1 AuditCo
				FROM @RecordsToAudit
				WHERE KeyID = inserted.SMRateOverrideID) Audit
		----------------------------------------
		
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(inserted.SMRateOverrideID) + '" Seq = "' + dbo.vfToString(inserted.Seq) + '" />', Audit.AuditCo, 'A', 'Percent', NULL, dbo.vfToString(inserted.[Percent]), GETDATE(), SUSER_SNAME()
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

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[vtvSMRateOverrideMaterial_AuditSM_Insert] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMRateOverrideMaterial_AuditSM_Insert]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtvSMRateOverrideMaterial_AuditSM_Update] ON [dbo].[vSMRateOverrideMaterial]
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

		SELECT @TableName = 'vSMRateOverrideMaterial'

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
 
 
 
		--Audit MatlGroup--------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(inserted.SMRateOverrideID) + '" Seq = "' + dbo.vfToString(inserted.Seq) + '" />', Audit.AuditCo, 'C', 'MatlGroup', dbo.vfToString(deleted.[MatlGroup]), dbo.vfToString(inserted.[MatlGroup]), GETDATE(), SUSER_SNAME()
		FROM inserted
			JOIN deleted ON inserted.SMRateOverrideMaterialID = deleted.SMRateOverrideMaterialID
				AND dbo.vfIsEqual(inserted.MatlGroup, deleted.MatlGroup) = 0
			CROSS APPLY (
				SELECT TOP 1 AuditCo
				FROM @RecordsToAudit
				WHERE KeyID = inserted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit Category------------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(inserted.SMRateOverrideID) + '" Seq = "' + dbo.vfToString(inserted.Seq) + '" />', Audit.AuditCo, 'C', 'Category', dbo.vfToString(deleted.[Category]), dbo.vfToString(inserted.[Category]), GETDATE(), SUSER_SNAME()
		FROM inserted
			JOIN deleted ON inserted.SMRateOverrideMaterialID = deleted.SMRateOverrideMaterialID
				AND dbo.vfIsEqual(inserted.Category, deleted.Category) = 0
			CROSS APPLY (
				SELECT TOP 1 AuditCo
				FROM @RecordsToAudit
				WHERE KeyID = inserted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit Material------------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(inserted.SMRateOverrideID) + '" Seq = "' + dbo.vfToString(inserted.Seq) + '" />', Audit.AuditCo, 'C', 'Material', dbo.vfToString(deleted.[Material]), dbo.vfToString(inserted.[Material]), GETDATE(), SUSER_SNAME()
		FROM inserted
			JOIN deleted ON inserted.SMRateOverrideMaterialID = deleted.SMRateOverrideMaterialID
				AND dbo.vfIsEqual(inserted.Material, deleted.Material) = 0
			CROSS APPLY (
				SELECT TOP 1 AuditCo
				FROM @RecordsToAudit
				WHERE KeyID = inserted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit MarkupOrDiscount----------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(inserted.SMRateOverrideID) + '" Seq = "' + dbo.vfToString(inserted.Seq) + '" />', Audit.AuditCo, 'C', 'MarkupOrDiscount', dbo.vfToString(deleted.[MarkupOrDiscount]), dbo.vfToString(inserted.[MarkupOrDiscount]), GETDATE(), SUSER_SNAME()
		FROM inserted
			JOIN deleted ON inserted.SMRateOverrideMaterialID = deleted.SMRateOverrideMaterialID
				AND dbo.vfIsEqual(inserted.MarkupOrDiscount, deleted.MarkupOrDiscount) = 0
			CROSS APPLY (
				SELECT TOP 1 AuditCo
				FROM @RecordsToAudit
				WHERE KeyID = inserted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit Basis---------------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(inserted.SMRateOverrideID) + '" Seq = "' + dbo.vfToString(inserted.Seq) + '" />', Audit.AuditCo, 'C', 'Basis', dbo.vfToString(deleted.[Basis]), dbo.vfToString(inserted.[Basis]), GETDATE(), SUSER_SNAME()
		FROM inserted
			JOIN deleted ON inserted.SMRateOverrideMaterialID = deleted.SMRateOverrideMaterialID
				AND dbo.vfIsEqual(inserted.Basis, deleted.Basis) = 0
			CROSS APPLY (
				SELECT TOP 1 AuditCo
				FROM @RecordsToAudit
				WHERE KeyID = inserted.SMRateOverrideID) Audit
		----------------------------------------
		
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(inserted.SMRateOverrideID) + '" Seq = "' + dbo.vfToString(inserted.Seq) + '" />', Audit.AuditCo, 'C', 'Percent', dbo.vfToString(deleted.[Percent]), dbo.vfToString(inserted.[Percent]), GETDATE(), SUSER_SNAME()
		FROM inserted
			JOIN deleted ON inserted.SMRateOverrideMaterialID = deleted.SMRateOverrideMaterialID
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

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[vtvSMRateOverrideMaterial_AuditSM_Update] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMRateOverrideMaterial_AuditSM_Update]', 'last', 'update', null
GO
ALTER TABLE [dbo].[vSMRateOverrideMaterial] ADD CONSTRAINT [PK_vSMRateOverrideMaterial] PRIMARY KEY CLUSTERED  ([SMRateOverrideMaterialID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMRateOverrideMaterial] ADD CONSTRAINT [IX_vSMRateOverrideMaterial_SMRateOverrideID_MatlGroup_Category_Material] UNIQUE NONCLUSTERED  ([SMRateOverrideID], [MatlGroup], [Category], [Material]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMRateOverrideMaterial] ADD CONSTRAINT [IX_vSMRateOverrideMaterial_SMRateOverrideID_Seq] UNIQUE NONCLUSTERED  ([SMRateOverrideID], [Seq]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMRateOverrideMaterial] WITH NOCHECK ADD CONSTRAINT [FK_vSMRateOverrideMaterial_bHQMC] FOREIGN KEY ([MatlGroup], [Category]) REFERENCES [dbo].[bHQMC] ([MatlGroup], [Category])
GO
ALTER TABLE [dbo].[vSMRateOverrideMaterial] WITH NOCHECK ADD CONSTRAINT [FK_vSMRateOverrideMaterial_bHQMT] FOREIGN KEY ([MatlGroup], [Material]) REFERENCES [dbo].[bHQMT] ([MatlGroup], [Material])
GO
ALTER TABLE [dbo].[vSMRateOverrideMaterial] WITH NOCHECK ADD CONSTRAINT [FK_vSMRateOverrideMaterial_vSMRateOverride] FOREIGN KEY ([SMRateOverrideID]) REFERENCES [dbo].[vSMRateOverride] ([SMRateOverrideID]) ON DELETE CASCADE
GO
