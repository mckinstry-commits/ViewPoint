CREATE TABLE [dbo].[vSMRequiredMisc]
(
[SMRequiredMiscID] [bigint] NOT NULL IDENTITY(1, 1),
[SMCo] [dbo].[bCompany] NOT NULL,
[EntitySeq] [int] NOT NULL,
[Seq] [int] NOT NULL,
[Task] [int] NULL,
[StandardItem] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[Description] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[SMCostType] [smallint] NULL,
[Quantity] [dbo].[bUnits] NULL,
[CostRate] [dbo].[bUnitCost] NULL,
[CostTotal] [dbo].[bDollar] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Scott Alvey
-- Create date: 04/29/2013
-- Description:	Prevent Insert, Update, Delete on Material related to a locked Entity
-- Modified:	EricV 05/08/13 Coverted from vtSMRequiredMaterialiud
-- =============================================
CREATE TRIGGER [dbo].[vtSMRequiredMisciud]
   ON  [dbo].[vSMRequiredMisc]
   AFTER INSERT, UPDATE, DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE 
		@Type int
		, @msg varchar(60)

	SET @Type = NULL
	SET @msg = NULL

	SELECT @Type = l.Type 
		FROM SMEntityExt l
			INNER JOIN
			(SELECT SMCo, EntitySeq
			FROM INSERTED
			UNION
			SELECT SMCo, EntitySeq
			FROM DELETED) r ON
				l.SMCo = r.SMCo
				AND l.EntitySeq = r.EntitySeq
		WHERE l.Locked = 'Y'

	IF EXISTS
	(
		SELECT 1
        FROM dbo.vfColumnsUpdated(COLUMNS_UPDATED(), 'vSMRequiredMisc')
        WHERE ColumnsUpdated NOT IN ('Notes','UniqueAttchID') --Add columns here that are allowed to be changed
    )
	AND @Type is not null
	BEGIN
		SET @msg = CASE
			WHEN @Type IN (10,11) THEN 'approved work order quotes.'
			WHEN @Type IN (8,9) THEN 'activated agreements.'
			WHEN @Type IN (6,7) THEN 'closed work orders.'
			ELSE ''
		END
		RAISERROR(N'Changes are not allowed for %s', 11, -1, @msg)
		ROLLBACK TRANSACTION
		RETURN
	END
END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMRequiredMisc_Audit_Delete ON dbo.vSMRequiredMisc
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
								'vSMRequiredMisc' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'CostRate' , 
								CONVERT(VARCHAR(MAX), deleted.[CostRate]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 11
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
								'vSMRequiredMisc' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'CostTotal' , 
								CONVERT(VARCHAR(MAX), deleted.[CostTotal]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 11
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
								'vSMRequiredMisc' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'Description' , 
								CONVERT(VARCHAR(MAX), deleted.[Description]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 11
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
								'vSMRequiredMisc' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'EntitySeq' , 
								CONVERT(VARCHAR(MAX), deleted.[EntitySeq]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 11
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
								'vSMRequiredMisc' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'Quantity' , 
								CONVERT(VARCHAR(MAX), deleted.[Quantity]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 11
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
								'vSMRequiredMisc' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'SMCo' , 
								CONVERT(VARCHAR(MAX), deleted.[SMCo]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 11
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
								'vSMRequiredMisc' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'SMCostType' , 
								CONVERT(VARCHAR(MAX), deleted.[SMCostType]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 11
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
								'vSMRequiredMisc' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'SMRequiredMiscID' , 
								CONVERT(VARCHAR(MAX), deleted.[SMRequiredMiscID]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 11
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
								'vSMRequiredMisc' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'Seq' , 
								CONVERT(VARCHAR(MAX), deleted.[Seq]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 11
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
								'vSMRequiredMisc' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'StandardItem' , 
								CONVERT(VARCHAR(MAX), deleted.[StandardItem]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 11
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
								'vSMRequiredMisc' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'Task' , 
								CONVERT(VARCHAR(MAX), deleted.[Task]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 11
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
								'vSMRequiredMisc' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'UniqueAttchID' , 
								CONVERT(VARCHAR(MAX), deleted.[UniqueAttchID]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 11

							
 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMRequiredMisc_Audit_Delete] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMRequiredMisc_Audit_Delete]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMRequiredMisc_Audit_Insert ON dbo.vSMRequiredMisc
 AFTER INSERT
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspAuditTriggersCreate

 BEGIN TRY 

-- log additions to the CostRate column
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
								'vSMRequiredMisc' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'CostRate' , 
								NULL , 
								[CostRate] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 11

-- log additions to the CostTotal column
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
								'vSMRequiredMisc' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'CostTotal' , 
								NULL , 
								[CostTotal] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 11

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
								'vSMRequiredMisc' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Description' , 
								NULL , 
								[Description] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 11

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
							
							SELECT 
								'vSMRequiredMisc' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'EntitySeq' , 
								NULL , 
								[EntitySeq] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 11

-- log additions to the Quantity column
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
								'vSMRequiredMisc' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Quantity' , 
								NULL , 
								[Quantity] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 11

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
								'vSMRequiredMisc' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'SMCo' , 
								NULL , 
								[SMCo] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 11

-- log additions to the SMCostType column
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
								'vSMRequiredMisc' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'SMCostType' , 
								NULL , 
								[SMCostType] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 11

-- log additions to the SMRequiredMiscID column
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
								'vSMRequiredMisc' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'SMRequiredMiscID' , 
								NULL , 
								[SMRequiredMiscID] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 11

-- log additions to the Seq column
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
								'vSMRequiredMisc' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Seq' , 
								NULL , 
								[Seq] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 11

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
							
							SELECT 
								'vSMRequiredMisc' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'StandardItem' , 
								NULL , 
								[StandardItem] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 11

-- log additions to the Task column
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
								'vSMRequiredMisc' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Task' , 
								NULL , 
								[Task] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 11

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
								'vSMRequiredMisc' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'UniqueAttchID' , 
								NULL , 
								[UniqueAttchID] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 11


 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMRequiredMisc_Audit_Insert] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMRequiredMisc_Audit_Insert]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMRequiredMisc_Audit_Update ON dbo.vSMRequiredMisc
 AFTER UPDATE 
 NOT FOR REPLICATION AS 
 SET NOCOUNT ON 
 -- generated by vspAuditTriggersCreate

 BEGIN TRY 

							IF UPDATE([CostRate])
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
								
								SELECT 							'vSMRequiredMisc' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'CostRate' , 								CONVERT(VARCHAR(MAX), deleted.[CostRate]) , 								CONVERT(VARCHAR(MAX), inserted.[CostRate]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMRequiredMiscID] = deleted.[SMRequiredMiscID] 
									AND ((inserted.[CostRate] <> deleted.[CostRate]) OR (inserted.[CostRate] IS NULL AND deleted.[CostRate] IS NOT NULL) OR (inserted.[CostRate] IS NOT NULL AND deleted.[CostRate] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 11

							END 

							IF UPDATE([CostTotal])
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
								
								SELECT 							'vSMRequiredMisc' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'CostTotal' , 								CONVERT(VARCHAR(MAX), deleted.[CostTotal]) , 								CONVERT(VARCHAR(MAX), inserted.[CostTotal]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMRequiredMiscID] = deleted.[SMRequiredMiscID] 
									AND ((inserted.[CostTotal] <> deleted.[CostTotal]) OR (inserted.[CostTotal] IS NULL AND deleted.[CostTotal] IS NOT NULL) OR (inserted.[CostTotal] IS NOT NULL AND deleted.[CostTotal] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 11

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
								
								SELECT 							'vSMRequiredMisc' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'Description' , 								CONVERT(VARCHAR(MAX), deleted.[Description]) , 								CONVERT(VARCHAR(MAX), inserted.[Description]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMRequiredMiscID] = deleted.[SMRequiredMiscID] 
									AND ((inserted.[Description] <> deleted.[Description]) OR (inserted.[Description] IS NULL AND deleted.[Description] IS NOT NULL) OR (inserted.[Description] IS NOT NULL AND deleted.[Description] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 11

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
								
								SELECT 							'vSMRequiredMisc' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'EntitySeq' , 								CONVERT(VARCHAR(MAX), deleted.[EntitySeq]) , 								CONVERT(VARCHAR(MAX), inserted.[EntitySeq]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMRequiredMiscID] = deleted.[SMRequiredMiscID] 
									AND ((inserted.[EntitySeq] <> deleted.[EntitySeq]) OR (inserted.[EntitySeq] IS NULL AND deleted.[EntitySeq] IS NOT NULL) OR (inserted.[EntitySeq] IS NOT NULL AND deleted.[EntitySeq] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 11

							END 

							IF UPDATE([Quantity])
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
								
								SELECT 							'vSMRequiredMisc' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'Quantity' , 								CONVERT(VARCHAR(MAX), deleted.[Quantity]) , 								CONVERT(VARCHAR(MAX), inserted.[Quantity]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMRequiredMiscID] = deleted.[SMRequiredMiscID] 
									AND ((inserted.[Quantity] <> deleted.[Quantity]) OR (inserted.[Quantity] IS NULL AND deleted.[Quantity] IS NOT NULL) OR (inserted.[Quantity] IS NOT NULL AND deleted.[Quantity] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 11

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
								
								SELECT 							'vSMRequiredMisc' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'SMCo' , 								CONVERT(VARCHAR(MAX), deleted.[SMCo]) , 								CONVERT(VARCHAR(MAX), inserted.[SMCo]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMRequiredMiscID] = deleted.[SMRequiredMiscID] 
									AND ((inserted.[SMCo] <> deleted.[SMCo]) OR (inserted.[SMCo] IS NULL AND deleted.[SMCo] IS NOT NULL) OR (inserted.[SMCo] IS NOT NULL AND deleted.[SMCo] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 11

							END 

							IF UPDATE([SMCostType])
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
								
								SELECT 							'vSMRequiredMisc' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'SMCostType' , 								CONVERT(VARCHAR(MAX), deleted.[SMCostType]) , 								CONVERT(VARCHAR(MAX), inserted.[SMCostType]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMRequiredMiscID] = deleted.[SMRequiredMiscID] 
									AND ((inserted.[SMCostType] <> deleted.[SMCostType]) OR (inserted.[SMCostType] IS NULL AND deleted.[SMCostType] IS NOT NULL) OR (inserted.[SMCostType] IS NOT NULL AND deleted.[SMCostType] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 11

							END 

							IF UPDATE([SMRequiredMiscID])
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
								
								SELECT 							'vSMRequiredMisc' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'SMRequiredMiscID' , 								CONVERT(VARCHAR(MAX), deleted.[SMRequiredMiscID]) , 								CONVERT(VARCHAR(MAX), inserted.[SMRequiredMiscID]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMRequiredMiscID] = deleted.[SMRequiredMiscID] 
									AND ((inserted.[SMRequiredMiscID] <> deleted.[SMRequiredMiscID]) OR (inserted.[SMRequiredMiscID] IS NULL AND deleted.[SMRequiredMiscID] IS NOT NULL) OR (inserted.[SMRequiredMiscID] IS NOT NULL AND deleted.[SMRequiredMiscID] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 11

							END 

							IF UPDATE([Seq])
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
								
								SELECT 							'vSMRequiredMisc' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'Seq' , 								CONVERT(VARCHAR(MAX), deleted.[Seq]) , 								CONVERT(VARCHAR(MAX), inserted.[Seq]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMRequiredMiscID] = deleted.[SMRequiredMiscID] 
									AND ((inserted.[Seq] <> deleted.[Seq]) OR (inserted.[Seq] IS NULL AND deleted.[Seq] IS NOT NULL) OR (inserted.[Seq] IS NOT NULL AND deleted.[Seq] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 11

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
								
								SELECT 							'vSMRequiredMisc' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'StandardItem' , 								CONVERT(VARCHAR(MAX), deleted.[StandardItem]) , 								CONVERT(VARCHAR(MAX), inserted.[StandardItem]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMRequiredMiscID] = deleted.[SMRequiredMiscID] 
									AND ((inserted.[StandardItem] <> deleted.[StandardItem]) OR (inserted.[StandardItem] IS NULL AND deleted.[StandardItem] IS NOT NULL) OR (inserted.[StandardItem] IS NOT NULL AND deleted.[StandardItem] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 11

							END 

							IF UPDATE([Task])
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
								
								SELECT 							'vSMRequiredMisc' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'Task' , 								CONVERT(VARCHAR(MAX), deleted.[Task]) , 								CONVERT(VARCHAR(MAX), inserted.[Task]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMRequiredMiscID] = deleted.[SMRequiredMiscID] 
									AND ((inserted.[Task] <> deleted.[Task]) OR (inserted.[Task] IS NULL AND deleted.[Task] IS NOT NULL) OR (inserted.[Task] IS NOT NULL AND deleted.[Task] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 11

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
								
								SELECT 							'vSMRequiredMisc' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'UniqueAttchID' , 								CONVERT(VARCHAR(MAX), deleted.[UniqueAttchID]) , 								CONVERT(VARCHAR(MAX), inserted.[UniqueAttchID]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMRequiredMiscID] = deleted.[SMRequiredMiscID] 
									AND ((inserted.[UniqueAttchID] <> deleted.[UniqueAttchID]) OR (inserted.[UniqueAttchID] IS NULL AND deleted.[UniqueAttchID] IS NOT NULL) OR (inserted.[UniqueAttchID] IS NOT NULL AND deleted.[UniqueAttchID] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 11

							END 



 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMRequiredMisc_Audit_Update] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMRequiredMisc_Audit_Update]', 'last', 'update', null
GO
ALTER TABLE [dbo].[vSMRequiredMisc] ADD CONSTRAINT [PK_vSMRequiredMisc] PRIMARY KEY CLUSTERED  ([SMRequiredMiscID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMRequiredMisc] ADD CONSTRAINT [IX_vSMRequiredMisc] UNIQUE NONCLUSTERED  ([SMCo], [EntitySeq], [Seq]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMRequiredMisc] ADD CONSTRAINT [FK_vSMRequiredMisc_vSMEntity] FOREIGN KEY ([SMCo], [EntitySeq]) REFERENCES [dbo].[vSMEntity] ([SMCo], [EntitySeq]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vSMRequiredMisc] ADD CONSTRAINT [FK_vSMRequiredMisc_vSMRequiredTasks] FOREIGN KEY ([SMCo], [EntitySeq], [Task]) REFERENCES [dbo].[vSMRequiredTasks] ([SMCo], [EntitySeq], [Task])
GO
ALTER TABLE [dbo].[vSMRequiredMisc] ADD CONSTRAINT [FK_vSMRequiredMisc_vSMCostType] FOREIGN KEY ([SMCo], [SMCostType]) REFERENCES [dbo].[vSMCostType] ([SMCo], [SMCostType])
GO
ALTER TABLE [dbo].[vSMRequiredMisc] ADD CONSTRAINT [FK_vSMRequiredMisc_vSMStandardItem] FOREIGN KEY ([SMCo], [StandardItem]) REFERENCES [dbo].[vSMStandardItem] ([SMCo], [StandardItem])
GO
