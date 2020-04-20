CREATE TABLE [dbo].[vSMRateOverrideLabor]
(
[SMRateOverrideLaborID] [bigint] NOT NULL IDENTITY(1, 1),
[SMRateOverrideID] [bigint] NOT NULL,
[Seq] [int] NOT NULL,
[SMCo] [dbo].[bCompany] NOT NULL,
[Technician] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[PRCo] [dbo].[bCompany] NOT NULL,
[Craft] [dbo].[bCraft] NULL,
[Class] [dbo].[bClass] NULL,
[CallType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[PayType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Rate] [dbo].[bUnitCost] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL
) ON [PRIMARY]
ALTER TABLE [dbo].[vSMRateOverrideLabor] WITH NOCHECK ADD
CONSTRAINT [FK_vSMRateOverrideLabor_bPRCO] FOREIGN KEY ([PRCo]) REFERENCES [dbo].[bPRCO] ([PRCo])
ALTER TABLE [dbo].[vSMRateOverrideLabor] WITH NOCHECK ADD
CONSTRAINT [FK_vSMRateOverrideLabor_bPRCM] FOREIGN KEY ([PRCo], [Craft]) REFERENCES [dbo].[bPRCM] ([PRCo], [Craft])
ALTER TABLE [dbo].[vSMRateOverrideLabor] WITH NOCHECK ADD
CONSTRAINT [FK_vSMRateOverrideLabor_bPRCC] FOREIGN KEY ([PRCo], [Craft], [Class]) REFERENCES [dbo].[bPRCC] ([PRCo], [Craft], [Class])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtvSMRateOverrideLabor_AuditSM_Delete] ON [dbo].[vSMRateOverrideLabor]
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

		SELECT @TableName = 'vSMRateOverrideLabor'

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


		--Audit SMCo----------------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(deleted.SMRateOverrideID) + '" Seq = "' + dbo.vfToString(deleted.Seq) + '" />', Audit.AuditCo, 'D', 'SMCo', dbo.vfToString(deleted.[SMCo]), NULL, GETDATE(), SUSER_SNAME()
		FROM deleted
			  CROSS APPLY (
					SELECT TOP 1 AuditCo
					FROM @RecordsToAudit
					WHERE KeyID = deleted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit Technician----------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(deleted.SMRateOverrideID) + '" Seq = "' + dbo.vfToString(deleted.Seq) + '" />', Audit.AuditCo, 'D', 'Technician', dbo.vfToString(deleted.[Technician]), NULL, GETDATE(), SUSER_SNAME()
		FROM deleted
			  CROSS APPLY (
					SELECT TOP 1 AuditCo
					FROM @RecordsToAudit
					WHERE KeyID = deleted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit PRCo----------------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(deleted.SMRateOverrideID) + '" Seq = "' + dbo.vfToString(deleted.Seq) + '" />', Audit.AuditCo, 'D', 'PRCo', dbo.vfToString(deleted.[PRCo]), NULL, GETDATE(), SUSER_SNAME()
		FROM deleted
			  CROSS APPLY (
					SELECT TOP 1 AuditCo
					FROM @RecordsToAudit
					WHERE KeyID = deleted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit Craft---------------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(deleted.SMRateOverrideID) + '" Seq = "' + dbo.vfToString(deleted.Seq) + '" />', Audit.AuditCo, 'D', 'Craft', dbo.vfToString(deleted.[Craft]), NULL, GETDATE(), SUSER_SNAME()
		FROM deleted
			  CROSS APPLY (
					SELECT TOP 1 AuditCo
					FROM @RecordsToAudit
					WHERE KeyID = deleted.SMRateOverrideID) Audit
		----------------------------------------

		--Audit Class---------------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(deleted.SMRateOverrideID) + '" Seq = "' + dbo.vfToString(deleted.Seq) + '" />', Audit.AuditCo, 'D', 'Class', dbo.vfToString(deleted.[Class]), NULL, GETDATE(), SUSER_SNAME()
		FROM deleted
			  CROSS APPLY (
					SELECT TOP 1 AuditCo
					FROM @RecordsToAudit
					WHERE KeyID = deleted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit CallType------------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(deleted.SMRateOverrideID) + '" Seq = "' + dbo.vfToString(deleted.Seq) + '" />', Audit.AuditCo, 'D', 'CallType', dbo.vfToString(deleted.[CallType]), NULL, GETDATE(), SUSER_SNAME()
		FROM deleted
			  CROSS APPLY (
					SELECT TOP 1 AuditCo
					FROM @RecordsToAudit
					WHERE KeyID = deleted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit PayType-------------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(deleted.SMRateOverrideID) + '" Seq = "' + dbo.vfToString(deleted.Seq) + '" />', Audit.AuditCo, 'D', 'PayType', dbo.vfToString(deleted.[PayType]), NULL, GETDATE(), SUSER_SNAME()
		FROM deleted
			  CROSS APPLY (
					SELECT TOP 1 AuditCo
					FROM @RecordsToAudit
					WHERE KeyID = deleted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit Rate----------------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(deleted.SMRateOverrideID) + '" Seq = "' + dbo.vfToString(deleted.Seq) + '" />', Audit.AuditCo, 'D', 'Rate', dbo.vfToString(deleted.[Rate]), NULL, GETDATE(), SUSER_SNAME()
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

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[vtvSMRateOverrideLabor_AuditSM_Delete] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMRateOverrideLabor_AuditSM_Delete]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtvSMRateOverrideLabor_AuditSM_Insert] ON [dbo].[vSMRateOverrideLabor]
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

		SELECT @TableName = 'vSMRateOverrideLabor'

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
 

		--Audit SMCo-------------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(inserted.SMRateOverrideID) + '" Seq = "' + dbo.vfToString(inserted.Seq) + '" />', Audit.AuditCo, 'A', 'SMCo', NULL, dbo.vfToString(inserted.[SMCo]), GETDATE(), SUSER_SNAME()
		FROM inserted
			CROSS APPLY (
				SELECT TOP 1 AuditCo
				FROM @RecordsToAudit
				WHERE KeyID = inserted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit Technician----------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(inserted.SMRateOverrideID) + '" Seq = "' + dbo.vfToString(inserted.Seq) + '" />', Audit.AuditCo, 'A', 'Technician', NULL, dbo.vfToString(inserted.[Technician]), GETDATE(), SUSER_SNAME()
		FROM inserted
			CROSS APPLY (
				SELECT TOP 1 AuditCo
				FROM @RecordsToAudit
				WHERE KeyID = inserted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit PRCo----------------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(inserted.SMRateOverrideID) + '" Seq = "' + dbo.vfToString(inserted.Seq) + '" />', Audit.AuditCo, 'A', 'PRCo', NULL, dbo.vfToString(inserted.[PRCo]), GETDATE(), SUSER_SNAME()
		FROM inserted
			CROSS APPLY (
				SELECT TOP 1 AuditCo
				FROM @RecordsToAudit
				WHERE KeyID = inserted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit Craft---------------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(inserted.SMRateOverrideID) + '" Seq = "' + dbo.vfToString(inserted.Seq) + '" />', Audit.AuditCo, 'A', 'Craft', NULL, dbo.vfToString(inserted.[Craft]), GETDATE(), SUSER_SNAME()
		FROM inserted
			CROSS APPLY (
				SELECT TOP 1 AuditCo
				FROM @RecordsToAudit
				WHERE KeyID = inserted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit Class---------------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(inserted.SMRateOverrideID) + '" Seq = "' + dbo.vfToString(inserted.Seq) + '" />', Audit.AuditCo, 'A', 'Class', NULL, dbo.vfToString(inserted.[Class]), GETDATE(), SUSER_SNAME()
		FROM inserted
			CROSS APPLY (
				SELECT TOP 1 AuditCo
				FROM @RecordsToAudit
				WHERE KeyID = inserted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit CallType------------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(inserted.SMRateOverrideID) + '" Seq = "' + dbo.vfToString(inserted.Seq) + '" />', Audit.AuditCo, 'A', 'CallType', NULL, dbo.vfToString(inserted.[CallType]), GETDATE(), SUSER_SNAME()
		FROM inserted
			CROSS APPLY (
				SELECT TOP 1 AuditCo
				FROM @RecordsToAudit
				WHERE KeyID = inserted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit PayType-------------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(inserted.SMRateOverrideID) + '" Seq = "' + dbo.vfToString(inserted.Seq) + '" />', Audit.AuditCo, 'A', 'PayType', NULL, dbo.vfToString(inserted.[PayType]), GETDATE(), SUSER_SNAME()
		FROM inserted
			CROSS APPLY (
				SELECT TOP 1 AuditCo
				FROM @RecordsToAudit
				WHERE KeyID = inserted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit Rate----------------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(inserted.SMRateOverrideID) + '" Seq = "' + dbo.vfToString(inserted.Seq) + '" />', Audit.AuditCo, 'A', 'Rate', NULL, dbo.vfToString(inserted.[Rate]), GETDATE(), SUSER_SNAME()
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

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[vtvSMRateOverrideLabor_AuditSM_Insert] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMRateOverrideLabor_AuditSM_Insert]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtvSMRateOverrideLabor_AuditSM_Update] ON [dbo].[vSMRateOverrideLabor]
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

		SELECT @TableName = 'vSMRateOverrideLabor'

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


		--Audit SMCo----------------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(inserted.SMRateOverrideID) + '" Seq = "' + dbo.vfToString(inserted.Seq) + '" />', Audit.AuditCo, 'C', 'SMCo', dbo.vfToString(deleted.[SMCo]), dbo.vfToString(inserted.[SMCo]), GETDATE(), SUSER_SNAME()
		FROM inserted
			JOIN deleted ON inserted.SMRateOverrideLaborID = deleted.SMRateOverrideLaborID
				AND dbo.vfIsEqual(inserted.SMCo, deleted.SMCo) = 0
			CROSS APPLY (
				SELECT TOP 1 AuditCo
				FROM @RecordsToAudit
				WHERE KeyID = inserted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit Technician----------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(inserted.SMRateOverrideID) + '" Seq = "' + dbo.vfToString(inserted.Seq) + '" />', Audit.AuditCo, 'C', 'Technician', dbo.vfToString(deleted.[Technician]), dbo.vfToString(inserted.[Technician]), GETDATE(), SUSER_SNAME()
		FROM inserted
			JOIN deleted ON inserted.SMRateOverrideLaborID = deleted.SMRateOverrideLaborID
				AND dbo.vfIsEqual(inserted.Technician, deleted.Technician) = 0
			CROSS APPLY (
				SELECT TOP 1 AuditCo
				FROM @RecordsToAudit
				WHERE KeyID = inserted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit PRCo----------------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(inserted.SMRateOverrideID) + '" Seq = "' + dbo.vfToString(inserted.Seq) + '" />', Audit.AuditCo, 'C', 'PRCo', dbo.vfToString(deleted.[PRCo]), dbo.vfToString(inserted.[PRCo]), GETDATE(), SUSER_SNAME()
		FROM inserted
			JOIN deleted ON inserted.SMRateOverrideLaborID = deleted.SMRateOverrideLaborID
				AND dbo.vfIsEqual(inserted.PRCo, deleted.PRCo) = 0
			CROSS APPLY (
				SELECT TOP 1 AuditCo
				FROM @RecordsToAudit
				WHERE KeyID = inserted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit Craft---------------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(inserted.SMRateOverrideID) + '" Seq = "' + dbo.vfToString(inserted.Seq) + '" />', Audit.AuditCo, 'C', 'Craft', dbo.vfToString(deleted.[Craft]), dbo.vfToString(inserted.[Craft]), GETDATE(), SUSER_SNAME()
		FROM inserted
			JOIN deleted ON inserted.SMRateOverrideLaborID = deleted.SMRateOverrideLaborID
				AND dbo.vfIsEqual(inserted.Craft, deleted.Craft) = 0
			CROSS APPLY (
				SELECT TOP 1 AuditCo
				FROM @RecordsToAudit
				WHERE KeyID = inserted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit Class---------------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(inserted.SMRateOverrideID) + '" Seq = "' + dbo.vfToString(inserted.Seq) + '" />', Audit.AuditCo, 'C', 'Class', dbo.vfToString(deleted.[Class]), dbo.vfToString(inserted.[Class]), GETDATE(), SUSER_SNAME()
		FROM inserted
			JOIN deleted ON inserted.SMRateOverrideLaborID = deleted.SMRateOverrideLaborID
				AND dbo.vfIsEqual(inserted.Class, deleted.Class) = 0
			CROSS APPLY (
				SELECT TOP 1 AuditCo
				FROM @RecordsToAudit
				WHERE KeyID = inserted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit CallType------------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(inserted.SMRateOverrideID) + '" Seq = "' + dbo.vfToString(inserted.Seq) + '" />', Audit.AuditCo, 'C', 'CallType', dbo.vfToString(deleted.[CallType]), dbo.vfToString(inserted.[CallType]), GETDATE(), SUSER_SNAME()
		FROM inserted
			JOIN deleted ON inserted.SMRateOverrideLaborID = deleted.SMRateOverrideLaborID
				AND dbo.vfIsEqual(inserted.CallType, deleted.CallType) = 0
			CROSS APPLY (
				SELECT TOP 1 AuditCo
				FROM @RecordsToAudit
				WHERE KeyID = inserted.SMRateOverrideID) Audit
		----------------------------------------
		
		--Audit PayType-------------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(inserted.SMRateOverrideID) + '" Seq = "' + dbo.vfToString(inserted.Seq) + '" />', Audit.AuditCo, 'C', 'PayType', dbo.vfToString(deleted.[PayType]), dbo.vfToString(inserted.[PayType]), GETDATE(), SUSER_SNAME()
		FROM inserted
			JOIN deleted ON inserted.SMRateOverrideLaborID = deleted.SMRateOverrideLaborID
				AND dbo.vfIsEqual(inserted.PayType, deleted.PayType) = 0
			CROSS APPLY (
				SELECT TOP 1 AuditCo
				FROM @RecordsToAudit
				WHERE KeyID = inserted.SMRateOverrideID) Audit
		----------------------------------------

		--Audit Rate----------------------------
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
		SELECT @TableName, '<KeyString SMRateOverrideID = "'+ dbo.vfToString(inserted.SMRateOverrideID) + '" Seq = "' + dbo.vfToString(inserted.Seq) + '" />', Audit.AuditCo, 'C', 'Rate', dbo.vfToString(deleted.[Rate]), dbo.vfToString(inserted.[Rate]), GETDATE(), SUSER_SNAME()
		FROM inserted
			JOIN deleted ON inserted.SMRateOverrideLaborID = deleted.SMRateOverrideLaborID
				AND dbo.vfIsEqual(inserted.Rate, deleted.Rate) = 0
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

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[vtvSMRateOverrideLabor_AuditSM_Update] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMRateOverrideLabor_AuditSM_Update]', 'last', 'update', null
GO
ALTER TABLE [dbo].[vSMRateOverrideLabor] ADD CONSTRAINT [CK_vSMRateOverrideLabor_EnsureAtLeastOneValueIsSupplied] CHECK (((((([dbo].[vfEqualsNull]([PayType])&[dbo].[vfEqualsNull]([CallType]))&[dbo].[vfEqualsNull]([Craft]))&[dbo].[vfEqualsNull]([Class]))&[dbo].[vfEqualsNull]([Technician]))=(0)))
GO
ALTER TABLE [dbo].[vSMRateOverrideLabor] ADD CONSTRAINT [PK_vSMRateOverrideLabor] PRIMARY KEY CLUSTERED  ([SMRateOverrideLaborID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMRateOverrideLabor] ADD CONSTRAINT [IX_vSMRateOverrideLabor_SMRateOverrideID_Seq] UNIQUE NONCLUSTERED  ([SMRateOverrideID], [Seq]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMRateOverrideLabor] ADD CONSTRAINT [IX_vSMRateOverrideLabor_SMRateOverrideID_SMCo_Technician_PRCo_Craft_Class_CallType_PayType] UNIQUE NONCLUSTERED  ([SMRateOverrideID], [SMCo], [Technician], [PRCo], [Craft], [Class], [CallType], [PayType]) ON [PRIMARY]
GO

ALTER TABLE [dbo].[vSMRateOverrideLabor] WITH NOCHECK ADD CONSTRAINT [FK_vSMRateOverrideLabor_vSMCO] FOREIGN KEY ([SMCo]) REFERENCES [dbo].[vSMCO] ([SMCo])
GO
ALTER TABLE [dbo].[vSMRateOverrideLabor] WITH NOCHECK ADD CONSTRAINT [FK_vSMRateOverrideLabor_vSMCallType] FOREIGN KEY ([SMCo], [CallType]) REFERENCES [dbo].[vSMCallType] ([SMCo], [CallType])
GO
ALTER TABLE [dbo].[vSMRateOverrideLabor] WITH NOCHECK ADD CONSTRAINT [FK_vSMRateOverrideLabor_vSMPayType] FOREIGN KEY ([SMCo], [PayType]) REFERENCES [dbo].[vSMPayType] ([SMCo], [PayType])
GO
ALTER TABLE [dbo].[vSMRateOverrideLabor] WITH NOCHECK ADD CONSTRAINT [FK_vSMRateOverrideLabor_vSMTechnician] FOREIGN KEY ([SMCo], [Technician]) REFERENCES [dbo].[vSMTechnician] ([SMCo], [Technician])
GO
ALTER TABLE [dbo].[vSMRateOverrideLabor] WITH NOCHECK ADD CONSTRAINT [FK_vSMRateOverrideLabor_vSMRateOverride] FOREIGN KEY ([SMRateOverrideID]) REFERENCES [dbo].[vSMRateOverride] ([SMRateOverrideID]) ON DELETE CASCADE
GO
