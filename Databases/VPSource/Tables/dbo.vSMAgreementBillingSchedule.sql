CREATE TABLE [dbo].[vSMAgreementBillingSchedule]
(
[SMAgreementBillingScheduleID] [bigint] NOT NULL IDENTITY(1, 1),
[SMCo] [dbo].[bCompany] NOT NULL,
[Agreement] [varchar] (15) COLLATE Latin1_General_BIN NOT NULL,
[Revision] [int] NOT NULL,
[Service] [int] NULL,
[Billing] [int] NOT NULL,
[Date] [dbo].[bDate] NULL,
[Month] [tinyint] NULL,
[Day] [tinyint] NULL,
[BillingAmount] [dbo].[bDollar] NOT NULL,
[SMInvoiceID] [bigint] NULL,
[Notes] [dbo].[bNotes] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[TaxType] [tinyint] NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[TaxBasis] [dbo].[bDollar] NULL,
[TaxAmount] [dbo].[bDollar] NULL,
[BillingType] [char] (1) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
ALTER TABLE [dbo].[vSMAgreementBillingSchedule] WITH NOCHECK ADD
CONSTRAINT [FK_vSMAgreementBillingSchedule_vSMInvoice] FOREIGN KEY ([SMInvoiceID]) REFERENCES [dbo].[vSMInvoice] ([SMInvoiceID])
ALTER TABLE [dbo].[vSMAgreementBillingSchedule] WITH NOCHECK ADD
CONSTRAINT [FK_vSMAgreementBillingSchedule_vSMAgreement] FOREIGN KEY ([SMCo], [Agreement], [Revision]) REFERENCES [dbo].[vSMAgreement] ([SMCo], [Agreement], [Revision])
ALTER TABLE [dbo].[vSMAgreementBillingSchedule] ADD
CONSTRAINT [FK_vSMAgreementBillingSchedule_bHQTX] FOREIGN KEY ([TaxGroup], [TaxCode]) REFERENCES [dbo].[bHQTX] ([TaxGroup], [TaxCode])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 3/8/12
-- Description:	Trigger validation for vSMAgreementBillingSchedule
-- =============================================
CREATE TRIGGER [dbo].[vtSMAgreementBillingSchedulei]
   ON  [dbo].[vSMAgreementBillingSchedule]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF EXISTS(SELECT 1
		FROM INSERTED
			INNER JOIN dbo.SMAgreementService ON INSERTED.SMCo = SMAgreementService.SMCo AND INSERTED.Agreement = SMAgreementService.Agreement AND INSERTED.Revision = SMAgreementService.Revision AND INSERTED.[Service] = SMAgreementService.[Service]
		WHERE dbo.vfIsEqual(SMAgreementService.BilledSeparately, 'Y') = 0)
	BEGIN
		RAISERROR(N'Billing may only be added to periodic services marked as bill separately.', 11, -1)
    	ROLLBACK TRANSACTION
		RETURN
	END

	IF EXISTS(SELECT 1
		FROM INSERTED
			INNER JOIN dbo.SMAgreement ON INSERTED.SMCo = SMAgreement.SMCo AND INSERTED.Agreement = SMAgreement.Agreement AND INSERTED.Revision = SMAgreement.Revision
		WHERE SMAgreement.NonExpiring = 'N' AND INSERTED.[Date] IS NULL)
	BEGIN
		RAISERROR(N'All billings for an expiring agreement must have a date supplied.', 11, -1)
    	ROLLBACK TRANSACTION
		RETURN
	END
	
	IF EXISTS(SELECT 1
		FROM INSERTED
			INNER JOIN dbo.SMAgreement ON INSERTED.SMCo = SMAgreement.SMCo AND INSERTED.Agreement = SMAgreement.Agreement AND INSERTED.Revision = SMAgreement.Revision
		WHERE SMAgreement.NonExpiring = 'Y' AND (INSERTED.[Month] IS NULL OR INSERTED.[Day] IS NULL ))
	BEGIN
		RAISERROR(N'All billings for an expiring agreement must have a month and day supplied.', 11, -1)
    	ROLLBACK TRANSACTION
		RETURN
	END
END
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 3/12/12
-- Description:	Trigger validation for vSMAgreementBillingSchedule
-- Modified:	JVH 6/10/13 - TFS-50983 Modified to allow deleting SM adjustment agreement scheduled records
-- =============================================
CREATE TRIGGER [dbo].[vtSMAgreementBillingScheduleiud]
   ON  [dbo].[vSMAgreementBillingSchedule]
   AFTER INSERT, UPDATE, DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF COLUMNS_UPDATED() = 0x0 --If COLUMNS_UPDATED() = 0x0 then a delete was done
	BEGIN
		--Prevent billings that have been invoiced from being deleted
		IF EXISTS
		(
			SELECT 1
			FROM deleted
				INNER JOIN dbo.vSMInvoice ON deleted.SMInvoiceID = vSMInvoice.SMInvoiceID
			WHERE deleted.BillingType <> 'A' OR vSMInvoice.VoidDate IS NULL
		)
		BEGIN
			RAISERROR(N'Billings that have been invoiced cannot be deleted.', 11, -1)
			ROLLBACK TRANSACTION
			RETURN
		END
	
		--Prevent billings from being deleted from an active revision. If the revision has been amended and then terminated the billings that haven't been invoiced will be deleted.
		IF EXISTS (SELECT 1
					FROM DELETED
						INNER JOIN dbo.SMAgreement ON DELETED.SMCo = SMAgreement.SMCo AND DELETED.Agreement = SMAgreement.Agreement AND DELETED.Revision = SMAgreement.Revision
					WHERE DELETED.BillingType = 'S' AND SMAgreement.DateActivated IS NOT NULL AND SMAgreement.AmendmentRevision IS NULL)
		BEGIN
			RAISERROR(N'Changes are not allowed for active agreements.', 11, -1)
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	ELSE
	BEGIN
		IF EXISTS(SELECT 1 FROM dbo.vfColumnsUpdated(COLUMNS_UPDATED(), 'vSMAgreementBillingSchedule') WHERE ColumnsUpdated NOT IN ('SMInvoiceID', 'TaxType', 'TaxGroup', 'TaxCode', 'TaxBasis', 'TaxAmount')) AND
			EXISTS(SELECT 1 
				FROM dbo.vSMAgreement
					INNER JOIN (
						SELECT SMCo, Agreement, Revision
						FROM INSERTED
						WHERE INSERTED.BillingType = 'S'
						UNION
						SELECT SMCo, Agreement, Revision
						FROM DELETED
						WHERE DELETED.BillingType = 'S') RelatedAgreements ON vSMAgreement.SMCo = RelatedAgreements.SMCo AND vSMAgreement.Agreement = RelatedAgreements.Agreement AND vSMAgreement.Revision = RelatedAgreements.Revision
				WHERE DateActivated IS NOT NULL)
		BEGIN
			RAISERROR(N'Changes are not allowed for active agreements.', 11, -1)
			ROLLBACK TRANSACTION
			RETURN
		END
	END
END
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 3/8/12
-- Description:	Trigger validation for vSMAgreementBillingSchedule
-- =============================================
CREATE TRIGGER [dbo].[vtSMAgreementBillingScheduleu]
   ON  [dbo].[vSMAgreementBillingSchedule]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF EXISTS(SELECT 1
		FROM DELETED
		WHERE SMInvoiceID IS NOT NULL)
		AND EXISTS(SELECT 1 FROM dbo.vfColumnsUpdated(COLUMNS_UPDATED(), 'vSMAgreementBillingSchedule') WHERE ColumnsUpdated NOT IN ('SMInvoiceID')) --Allow for removing the billing from an invoice when the invoice is cancelled.
	BEGIN
		RAISERROR(N'Changes to invoiced billings are not allowed.', 11, -1)
		ROLLBACK TRANSACTION
		RETURN
	END

	IF EXISTS(SELECT 1
		FROM INSERTED
			INNER JOIN dbo.SMAgreementService ON INSERTED.SMCo = SMAgreementService.SMCo AND INSERTED.Agreement = SMAgreementService.Agreement AND INSERTED.Revision = SMAgreementService.Revision AND INSERTED.[Service] = SMAgreementService.[Service]
		WHERE dbo.vfIsEqual(SMAgreementService.BilledSeparately, 'Y') = 0)
	BEGIN
		RAISERROR(N'Billing may only be added to periodic services marked as bill separately.', 11, -1)
    	ROLLBACK TRANSACTION
		RETURN
	END

	IF EXISTS(SELECT 1
		FROM INSERTED
			INNER JOIN dbo.SMAgreement ON INSERTED.SMCo = SMAgreement.SMCo AND INSERTED.Agreement = SMAgreement.Agreement AND INSERTED.Revision = SMAgreement.Revision
		WHERE SMAgreement.NonExpiring = 'N' AND INSERTED.[Date] IS NULL)
	BEGIN
		RAISERROR(N'All billings for an expiring agreement must have a date supplied.', 11, -1)
    	ROLLBACK TRANSACTION
		RETURN
	END
	
	IF EXISTS(SELECT 1
		FROM INSERTED
			INNER JOIN dbo.SMAgreement ON INSERTED.SMCo = SMAgreement.SMCo AND INSERTED.Agreement = SMAgreement.Agreement AND INSERTED.Revision = SMAgreement.Revision
		WHERE SMAgreement.NonExpiring = 'Y' AND (INSERTED.[Month] IS NULL OR INSERTED.[Day] IS NULL ))
	BEGIN
		RAISERROR(N'All billings for an expiring agreement must have a month and day supplied.', 11, -1)
    	ROLLBACK TRANSACTION
		RETURN
	END
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMAgreementBillingSchedule_Audit_Delete ON dbo.vSMAgreementBillingSchedule
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
								'vSMAgreementBillingSchedule' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'Agreement' , 
								CONVERT(VARCHAR(MAX), deleted.[Agreement]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15
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
								'vSMAgreementBillingSchedule' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'Billing' , 
								CONVERT(VARCHAR(MAX), deleted.[Billing]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15
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
								'vSMAgreementBillingSchedule' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'BillingAmount' , 
								CONVERT(VARCHAR(MAX), deleted.[BillingAmount]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15
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
								'vSMAgreementBillingSchedule' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'BillingType' , 
								CONVERT(VARCHAR(MAX), deleted.[BillingType]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15
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
								'vSMAgreementBillingSchedule' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'Date' , 
								CONVERT(VARCHAR(MAX), deleted.[Date]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15
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
								'vSMAgreementBillingSchedule' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'Day' , 
								CONVERT(VARCHAR(MAX), deleted.[Day]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15
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
								'vSMAgreementBillingSchedule' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'Month' , 
								CONVERT(VARCHAR(MAX), deleted.[Month]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15
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
								'vSMAgreementBillingSchedule' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'Revision' , 
								CONVERT(VARCHAR(MAX), deleted.[Revision]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15
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
								'vSMAgreementBillingSchedule' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'SMAgreementBillingScheduleID' , 
								CONVERT(VARCHAR(MAX), deleted.[SMAgreementBillingScheduleID]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15
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
								'vSMAgreementBillingSchedule' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'SMCo' , 
								CONVERT(VARCHAR(MAX), deleted.[SMCo]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15
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
								'vSMAgreementBillingSchedule' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'SMInvoiceID' , 
								CONVERT(VARCHAR(MAX), deleted.[SMInvoiceID]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15
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
								'vSMAgreementBillingSchedule' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'Service' , 
								CONVERT(VARCHAR(MAX), deleted.[Service]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15
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
								'vSMAgreementBillingSchedule' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'TaxAmount' , 
								CONVERT(VARCHAR(MAX), deleted.[TaxAmount]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15
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
								'vSMAgreementBillingSchedule' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'TaxBasis' , 
								CONVERT(VARCHAR(MAX), deleted.[TaxBasis]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15
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
								'vSMAgreementBillingSchedule' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'TaxCode' , 
								CONVERT(VARCHAR(MAX), deleted.[TaxCode]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15
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
								'vSMAgreementBillingSchedule' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'TaxGroup' , 
								CONVERT(VARCHAR(MAX), deleted.[TaxGroup]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15
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
								'vSMAgreementBillingSchedule' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'TaxType' , 
								CONVERT(VARCHAR(MAX), deleted.[TaxType]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15
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
								'vSMAgreementBillingSchedule' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'UniqueAttchID' , 
								CONVERT(VARCHAR(MAX), deleted.[UniqueAttchID]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							
 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMAgreementBillingSchedule_Audit_Delete] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMAgreementBillingSchedule_Audit_Delete]', 'last', 'delete', null
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMAgreementBillingSchedule_Audit_Insert ON dbo.vSMAgreementBillingSchedule
 AFTER INSERT
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspAuditTriggersCreate

 BEGIN TRY 

-- log additions to the Agreement column
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
								'vSMAgreementBillingSchedule' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Agreement' , 
								NULL , 
								[Agreement] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the Billing column
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
								'vSMAgreementBillingSchedule' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Billing' , 
								NULL , 
								[Billing] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the BillingAmount column
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
								'vSMAgreementBillingSchedule' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'BillingAmount' , 
								NULL , 
								[BillingAmount] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the BillingType column
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
								'vSMAgreementBillingSchedule' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'BillingType' , 
								NULL , 
								[BillingType] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the Date column
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
								'vSMAgreementBillingSchedule' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Date' , 
								NULL , 
								[Date] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the Day column
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
								'vSMAgreementBillingSchedule' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Day' , 
								NULL , 
								[Day] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the Month column
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
								'vSMAgreementBillingSchedule' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Month' , 
								NULL , 
								[Month] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the Revision column
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
								'vSMAgreementBillingSchedule' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Revision' , 
								NULL , 
								[Revision] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the SMAgreementBillingScheduleID column
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
								'vSMAgreementBillingSchedule' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'SMAgreementBillingScheduleID' , 
								NULL , 
								[SMAgreementBillingScheduleID] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

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
								'vSMAgreementBillingSchedule' , 
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
							WHERE afc.AuditFlagID = 15

-- log additions to the SMInvoiceID column
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
								'vSMAgreementBillingSchedule' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'SMInvoiceID' , 
								NULL , 
								[SMInvoiceID] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the Service column
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
								'vSMAgreementBillingSchedule' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Service' , 
								NULL , 
								[Service] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the TaxAmount column
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
								'vSMAgreementBillingSchedule' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'TaxAmount' , 
								NULL , 
								[TaxAmount] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the TaxBasis column
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
								'vSMAgreementBillingSchedule' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'TaxBasis' , 
								NULL , 
								[TaxBasis] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the TaxCode column
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
								'vSMAgreementBillingSchedule' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'TaxCode' , 
								NULL , 
								[TaxCode] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the TaxGroup column
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
								'vSMAgreementBillingSchedule' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'TaxGroup' , 
								NULL , 
								[TaxGroup] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the TaxType column
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
								'vSMAgreementBillingSchedule' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'TaxType' , 
								NULL , 
								[TaxType] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

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
								'vSMAgreementBillingSchedule' , 
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
							WHERE afc.AuditFlagID = 15


 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMAgreementBillingSchedule_Audit_Insert] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMAgreementBillingSchedule_Audit_Insert]', 'last', 'insert', null
GO

EXEC sp_settriggerorder N'[dbo].[vtvSMAgreementBillingSchedule_Audit_Insert]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMAgreementBillingSchedule_Audit_Update ON dbo.vSMAgreementBillingSchedule
 AFTER UPDATE 
 NOT FOR REPLICATION AS 
 SET NOCOUNT ON 
 -- generated by vspAuditTriggersCreate

 BEGIN TRY 

							IF UPDATE([Agreement])
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
								
								SELECT 							'vSMAgreementBillingSchedule' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'Agreement' , 								CONVERT(VARCHAR(MAX), deleted.[Agreement]) , 								CONVERT(VARCHAR(MAX), inserted.[Agreement]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementBillingScheduleID] = deleted.[SMAgreementBillingScheduleID] 
									AND ((inserted.[Agreement] <> deleted.[Agreement]) OR (inserted.[Agreement] IS NULL AND deleted.[Agreement] IS NOT NULL) OR (inserted.[Agreement] IS NOT NULL AND deleted.[Agreement] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([Billing])
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
								
								SELECT 							'vSMAgreementBillingSchedule' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'Billing' , 								CONVERT(VARCHAR(MAX), deleted.[Billing]) , 								CONVERT(VARCHAR(MAX), inserted.[Billing]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementBillingScheduleID] = deleted.[SMAgreementBillingScheduleID] 
									AND ((inserted.[Billing] <> deleted.[Billing]) OR (inserted.[Billing] IS NULL AND deleted.[Billing] IS NOT NULL) OR (inserted.[Billing] IS NOT NULL AND deleted.[Billing] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([BillingAmount])
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
								
								SELECT 							'vSMAgreementBillingSchedule' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'BillingAmount' , 								CONVERT(VARCHAR(MAX), deleted.[BillingAmount]) , 								CONVERT(VARCHAR(MAX), inserted.[BillingAmount]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementBillingScheduleID] = deleted.[SMAgreementBillingScheduleID] 
									AND ((inserted.[BillingAmount] <> deleted.[BillingAmount]) OR (inserted.[BillingAmount] IS NULL AND deleted.[BillingAmount] IS NOT NULL) OR (inserted.[BillingAmount] IS NOT NULL AND deleted.[BillingAmount] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([BillingType])
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
								
								SELECT 							'vSMAgreementBillingSchedule' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'BillingType' , 								CONVERT(VARCHAR(MAX), deleted.[BillingType]) , 								CONVERT(VARCHAR(MAX), inserted.[BillingType]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementBillingScheduleID] = deleted.[SMAgreementBillingScheduleID] 
									AND ((inserted.[BillingType] <> deleted.[BillingType]) OR (inserted.[BillingType] IS NULL AND deleted.[BillingType] IS NOT NULL) OR (inserted.[BillingType] IS NOT NULL AND deleted.[BillingType] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([Date])
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
								
								SELECT 							'vSMAgreementBillingSchedule' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'Date' , 								CONVERT(VARCHAR(MAX), deleted.[Date]) , 								CONVERT(VARCHAR(MAX), inserted.[Date]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementBillingScheduleID] = deleted.[SMAgreementBillingScheduleID] 
									AND ((inserted.[Date] <> deleted.[Date]) OR (inserted.[Date] IS NULL AND deleted.[Date] IS NOT NULL) OR (inserted.[Date] IS NOT NULL AND deleted.[Date] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([Day])
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
								
								SELECT 							'vSMAgreementBillingSchedule' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'Day' , 								CONVERT(VARCHAR(MAX), deleted.[Day]) , 								CONVERT(VARCHAR(MAX), inserted.[Day]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementBillingScheduleID] = deleted.[SMAgreementBillingScheduleID] 
									AND ((inserted.[Day] <> deleted.[Day]) OR (inserted.[Day] IS NULL AND deleted.[Day] IS NOT NULL) OR (inserted.[Day] IS NOT NULL AND deleted.[Day] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([Month])
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
								
								SELECT 							'vSMAgreementBillingSchedule' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'Month' , 								CONVERT(VARCHAR(MAX), deleted.[Month]) , 								CONVERT(VARCHAR(MAX), inserted.[Month]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementBillingScheduleID] = deleted.[SMAgreementBillingScheduleID] 
									AND ((inserted.[Month] <> deleted.[Month]) OR (inserted.[Month] IS NULL AND deleted.[Month] IS NOT NULL) OR (inserted.[Month] IS NOT NULL AND deleted.[Month] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([Revision])
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
								
								SELECT 							'vSMAgreementBillingSchedule' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'Revision' , 								CONVERT(VARCHAR(MAX), deleted.[Revision]) , 								CONVERT(VARCHAR(MAX), inserted.[Revision]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementBillingScheduleID] = deleted.[SMAgreementBillingScheduleID] 
									AND ((inserted.[Revision] <> deleted.[Revision]) OR (inserted.[Revision] IS NULL AND deleted.[Revision] IS NOT NULL) OR (inserted.[Revision] IS NOT NULL AND deleted.[Revision] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([SMAgreementBillingScheduleID])
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
								
								SELECT 							'vSMAgreementBillingSchedule' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'SMAgreementBillingScheduleID' , 								CONVERT(VARCHAR(MAX), deleted.[SMAgreementBillingScheduleID]) , 								CONVERT(VARCHAR(MAX), inserted.[SMAgreementBillingScheduleID]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementBillingScheduleID] = deleted.[SMAgreementBillingScheduleID] 
									AND ((inserted.[SMAgreementBillingScheduleID] <> deleted.[SMAgreementBillingScheduleID]) OR (inserted.[SMAgreementBillingScheduleID] IS NULL AND deleted.[SMAgreementBillingScheduleID] IS NOT NULL) OR (inserted.[SMAgreementBillingScheduleID] IS NOT NULL AND deleted.[SMAgreementBillingScheduleID] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

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
								
								SELECT 							'vSMAgreementBillingSchedule' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'SMCo' , 								CONVERT(VARCHAR(MAX), deleted.[SMCo]) , 								CONVERT(VARCHAR(MAX), inserted.[SMCo]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementBillingScheduleID] = deleted.[SMAgreementBillingScheduleID] 
									AND ((inserted.[SMCo] <> deleted.[SMCo]) OR (inserted.[SMCo] IS NULL AND deleted.[SMCo] IS NOT NULL) OR (inserted.[SMCo] IS NOT NULL AND deleted.[SMCo] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([SMInvoiceID])
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
								
								SELECT 							'vSMAgreementBillingSchedule' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'SMInvoiceID' , 								CONVERT(VARCHAR(MAX), deleted.[SMInvoiceID]) , 								CONVERT(VARCHAR(MAX), inserted.[SMInvoiceID]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementBillingScheduleID] = deleted.[SMAgreementBillingScheduleID] 
									AND ((inserted.[SMInvoiceID] <> deleted.[SMInvoiceID]) OR (inserted.[SMInvoiceID] IS NULL AND deleted.[SMInvoiceID] IS NOT NULL) OR (inserted.[SMInvoiceID] IS NOT NULL AND deleted.[SMInvoiceID] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([Service])
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
								
								SELECT 							'vSMAgreementBillingSchedule' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'Service' , 								CONVERT(VARCHAR(MAX), deleted.[Service]) , 								CONVERT(VARCHAR(MAX), inserted.[Service]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementBillingScheduleID] = deleted.[SMAgreementBillingScheduleID] 
									AND ((inserted.[Service] <> deleted.[Service]) OR (inserted.[Service] IS NULL AND deleted.[Service] IS NOT NULL) OR (inserted.[Service] IS NOT NULL AND deleted.[Service] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([TaxAmount])
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
								
								SELECT 							'vSMAgreementBillingSchedule' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'TaxAmount' , 								CONVERT(VARCHAR(MAX), deleted.[TaxAmount]) , 								CONVERT(VARCHAR(MAX), inserted.[TaxAmount]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementBillingScheduleID] = deleted.[SMAgreementBillingScheduleID] 
									AND ((inserted.[TaxAmount] <> deleted.[TaxAmount]) OR (inserted.[TaxAmount] IS NULL AND deleted.[TaxAmount] IS NOT NULL) OR (inserted.[TaxAmount] IS NOT NULL AND deleted.[TaxAmount] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([TaxBasis])
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
								
								SELECT 							'vSMAgreementBillingSchedule' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'TaxBasis' , 								CONVERT(VARCHAR(MAX), deleted.[TaxBasis]) , 								CONVERT(VARCHAR(MAX), inserted.[TaxBasis]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementBillingScheduleID] = deleted.[SMAgreementBillingScheduleID] 
									AND ((inserted.[TaxBasis] <> deleted.[TaxBasis]) OR (inserted.[TaxBasis] IS NULL AND deleted.[TaxBasis] IS NOT NULL) OR (inserted.[TaxBasis] IS NOT NULL AND deleted.[TaxBasis] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([TaxCode])
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
								
								SELECT 							'vSMAgreementBillingSchedule' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'TaxCode' , 								CONVERT(VARCHAR(MAX), deleted.[TaxCode]) , 								CONVERT(VARCHAR(MAX), inserted.[TaxCode]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementBillingScheduleID] = deleted.[SMAgreementBillingScheduleID] 
									AND ((inserted.[TaxCode] <> deleted.[TaxCode]) OR (inserted.[TaxCode] IS NULL AND deleted.[TaxCode] IS NOT NULL) OR (inserted.[TaxCode] IS NOT NULL AND deleted.[TaxCode] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([TaxGroup])
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
								
								SELECT 							'vSMAgreementBillingSchedule' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'TaxGroup' , 								CONVERT(VARCHAR(MAX), deleted.[TaxGroup]) , 								CONVERT(VARCHAR(MAX), inserted.[TaxGroup]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementBillingScheduleID] = deleted.[SMAgreementBillingScheduleID] 
									AND ((inserted.[TaxGroup] <> deleted.[TaxGroup]) OR (inserted.[TaxGroup] IS NULL AND deleted.[TaxGroup] IS NOT NULL) OR (inserted.[TaxGroup] IS NOT NULL AND deleted.[TaxGroup] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([TaxType])
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
								
								SELECT 							'vSMAgreementBillingSchedule' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'TaxType' , 								CONVERT(VARCHAR(MAX), deleted.[TaxType]) , 								CONVERT(VARCHAR(MAX), inserted.[TaxType]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementBillingScheduleID] = deleted.[SMAgreementBillingScheduleID] 
									AND ((inserted.[TaxType] <> deleted.[TaxType]) OR (inserted.[TaxType] IS NULL AND deleted.[TaxType] IS NOT NULL) OR (inserted.[TaxType] IS NOT NULL AND deleted.[TaxType] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

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
								
								SELECT 							'vSMAgreementBillingSchedule' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'UniqueAttchID' , 								CONVERT(VARCHAR(MAX), deleted.[UniqueAttchID]) , 								CONVERT(VARCHAR(MAX), inserted.[UniqueAttchID]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementBillingScheduleID] = deleted.[SMAgreementBillingScheduleID] 
									AND ((inserted.[UniqueAttchID] <> deleted.[UniqueAttchID]) OR (inserted.[UniqueAttchID] IS NULL AND deleted.[UniqueAttchID] IS NOT NULL) OR (inserted.[UniqueAttchID] IS NOT NULL AND deleted.[UniqueAttchID] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 



 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMAgreementBillingSchedule_Audit_Update] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMAgreementBillingSchedule_Audit_Update]', 'last', 'update', null
GO
ALTER TABLE [dbo].[vSMAgreementBillingSchedule] ADD CONSTRAINT [PK_vSMAgreementBillingSchedule] PRIMARY KEY CLUSTERED  ([SMAgreementBillingScheduleID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMAgreementBillingSchedule] ADD CONSTRAINT [IX_vSMAgreementBillingSchedule] UNIQUE NONCLUSTERED  ([SMCo], [Agreement], [Revision], [Service], [Billing]) ON [PRIMARY]
GO

ALTER TABLE [dbo].[vSMAgreementBillingSchedule] WITH NOCHECK ADD CONSTRAINT [FK_vSMAgreementBillingSchedule_vSMAgreementService] FOREIGN KEY ([SMCo], [Agreement], [Revision], [Service]) REFERENCES [dbo].[vSMAgreementService] ([SMCo], [Agreement], [Revision], [Service])
GO
