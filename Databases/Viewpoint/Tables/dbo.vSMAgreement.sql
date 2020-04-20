CREATE TABLE [dbo].[vSMAgreement]
(
[SMAgreementID] [bigint] NOT NULL IDENTITY(1, 1),
[SMCo] [dbo].[bCompany] NOT NULL,
[Agreement] [varchar] (15) COLLATE Latin1_General_BIN NOT NULL,
[Revision] [int] NOT NULL,
[RevisionType] [tinyint] NOT NULL,
[DateActivated] [dbo].[bDate] NULL,
[DateCancelled] [dbo].[bDate] NULL,
[DateTerminated] [dbo].[bDate] NULL,
[Description] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[CustGroup] [dbo].[bGroup] NOT NULL,
[Customer] [dbo].[bCustomer] NOT NULL,
[EffectiveDate] [dbo].[bDate] NULL,
[NonExpiring] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vSMAgreement_NonExpiring] DEFAULT ('N'),
[ExpirationDate] [dbo].[bDate] NULL,
[AutoRenew] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vSMAgreement_AutoRenew] DEFAULT ('N'),
[RateTemplate] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[AgreementPrice] [dbo].[bDollar] NULL,
[PricingFrequency] [char] (1) COLLATE Latin1_General_BIN NULL,
[ReportID] [int] NULL,
[Notes] [dbo].[bNotes] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[AgreementType] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[CustomerPO] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[AlternateAgreement] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[PreviousRevision] [int] NULL,
[AmendmentRevision] [int] NULL,
[DateCreated] [dbo].[bDate] NULL
) ON [PRIMARY]
ALTER TABLE [dbo].[vSMAgreement] WITH NOCHECK ADD
CONSTRAINT [FK_vSMAgreement_vRPRTc] FOREIGN KEY ([ReportID]) REFERENCES [dbo].[vRPRTc] ([ReportID])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 3/12/12
-- Description:	Trigger validation for vSMAgreement
-- =============================================
CREATE TRIGGER [dbo].[vtSMAgreementd]
   ON  [dbo].[vSMAgreement]
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF EXISTS(SELECT 1 
		FROM DELETED
		WHERE DateActivated IS NOT NULL)
	BEGIN
    	RAISERROR(N'Changes are not allowed for active agreements.', 11, -1)
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
-- Description:	Trigger validation for vSMAgreement
-- =============================================
CREATE TRIGGER [dbo].[vtSMAgreementi]
   ON  [dbo].[vSMAgreement]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF EXISTS(SELECT 1 
		FROM INSERTED
			INNER JOIN dbo.vSMAgreement ON INSERTED.SMCo = vSMAgreement.SMCo AND INSERTED.Agreement = vSMAgreement.Agreement AND INSERTED.Revision <> vSMAgreement.Revision
		WHERE vSMAgreement.NonExpiring = 'N' AND vSMAgreement.DateActivated IS NOT NULL AND INSERTED.NonExpiring = 'N' AND INSERTED.DateActivated IS NOT NULL AND (INSERTED.EffectiveDate BETWEEN vSMAgreement.EffectiveDate AND vSMAgreement.ExpirationDate OR INSERTED.ExpirationDate BETWEEN vSMAgreement.EffectiveDate AND vSMAgreement.ExpirationDate))
	BEGIN
		RAISERROR(N'Non-expiring active agreements cannot have overlapping terms.', 11, -1)
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
-- Description:	Trigger validation for vSMAgreement
-- Modification: 11/17/12 EricV Allow modification to column UniqueAttchID when agreement is active to allow attachments.
-- =============================================
CREATE TRIGGER [dbo].[vtSMAgreementu]
   ON  [dbo].[vSMAgreement]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF EXISTS(SELECT 1
		FROM dbo.vfColumnsUpdated(COLUMNS_UPDATED(), 'vSMAgreement')
		WHERE ColumnsUpdated NOT IN ('DateTerminated','AmendmentRevision','UniqueAttchID','DateActivated') --Add columns here that are allowed to be changed for active agreements.
		)
	AND EXISTS(SELECT 1 
		FROM DELETED
		WHERE DateActivated IS NOT NULL
		AND DateTerminated IS NULL)
	BEGIN
    	RAISERROR(N'Changes are not allowed for active agreements.', 11, -1)
    	ROLLBACK TRANSACTION
		RETURN
	END

	IF EXISTS(SELECT 1
		FROM dbo.vfColumnsUpdated(COLUMNS_UPDATED(), 'vSMAgreement')
		WHERE ColumnsUpdated NOT IN ('AgreementPrice','UniqueAttchID') --Add columns here that are allowed to be changed for terminated agreements.
		)
	AND EXISTS(SELECT 1 
		FROM DELETED
		WHERE DateTerminated IS NOT NULL)
	BEGIN
    	RAISERROR(N'Changes are not allowed for terminated agreements.', 11, -1)
    	ROLLBACK TRANSACTION
		RETURN
	END

	IF (UPDATE(EffectiveDate) OR UPDATE(DateTerminated) OR UPDATE(ExpirationDate))
		 AND EXISTS(SELECT 1 
		FROM INSERTED
		INNER JOIN dbo.SMAgreementExtended ON INSERTED.SMCo = SMAgreementExtended.SMCo AND INSERTED.Agreement = SMAgreementExtended.Agreement AND INSERTED.Revision <> SMAgreementExtended.Revision
		WHERE SMAgreementExtended.NonExpiring = 'N' AND SMAgreementExtended.DateActivated IS NOT NULL 
		AND INSERTED.NonExpiring = 'N' AND INSERTED.DateActivated IS NOT NULL
		AND (INSERTED.EffectiveDate BETWEEN SMAgreementExtended.EffectiveDate AND SMAgreementExtended.EndDate 
			OR INSERTED.ExpirationDate BETWEEN SMAgreementExtended.EffectiveDate AND SMAgreementExtended.EndDate
			)
		)
	BEGIN
		RAISERROR(N'Non-expiring active agreements cannot have overlapping terms.', 11, -1)
    	ROLLBACK TRANSACTION
		RETURN
	END
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMAgreement_Audit_Delete ON dbo.vSMAgreement
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
								'vSMAgreement' , 
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
								'vSMAgreement' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'AgreementPrice' , 
								CONVERT(VARCHAR(MAX), deleted.[AgreementPrice]) , 								NULL , 
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
								'vSMAgreement' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'AgreementType' , 
								CONVERT(VARCHAR(MAX), deleted.[AgreementType]) , 								NULL , 
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
								'vSMAgreement' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'AlternateAgreement' , 
								CONVERT(VARCHAR(MAX), deleted.[AlternateAgreement]) , 								NULL , 
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
								'vSMAgreement' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'AmendmentRevision' , 
								CONVERT(VARCHAR(MAX), deleted.[AmendmentRevision]) , 								NULL , 
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
								'vSMAgreement' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'AutoRenew' , 
								CONVERT(VARCHAR(MAX), deleted.[AutoRenew]) , 								NULL , 
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
								'vSMAgreement' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'CustGroup' , 
								CONVERT(VARCHAR(MAX), deleted.[CustGroup]) , 								NULL , 
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
								'vSMAgreement' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'Customer' , 
								CONVERT(VARCHAR(MAX), deleted.[Customer]) , 								NULL , 
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
								'vSMAgreement' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'CustomerPO' , 
								CONVERT(VARCHAR(MAX), deleted.[CustomerPO]) , 								NULL , 
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
								'vSMAgreement' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'DateActivated' , 
								CONVERT(VARCHAR(MAX), deleted.[DateActivated]) , 								NULL , 
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
								'vSMAgreement' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'DateCancelled' , 
								CONVERT(VARCHAR(MAX), deleted.[DateCancelled]) , 								NULL , 
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
								'vSMAgreement' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'DateCreated' , 
								CONVERT(VARCHAR(MAX), deleted.[DateCreated]) , 								NULL , 
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
								'vSMAgreement' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'DateTerminated' , 
								CONVERT(VARCHAR(MAX), deleted.[DateTerminated]) , 								NULL , 
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
								'vSMAgreement' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'Description' , 
								CONVERT(VARCHAR(MAX), deleted.[Description]) , 								NULL , 
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
								'vSMAgreement' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'EffectiveDate' , 
								CONVERT(VARCHAR(MAX), deleted.[EffectiveDate]) , 								NULL , 
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
								'vSMAgreement' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'ExpirationDate' , 
								CONVERT(VARCHAR(MAX), deleted.[ExpirationDate]) , 								NULL , 
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
								'vSMAgreement' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'NonExpiring' , 
								CONVERT(VARCHAR(MAX), deleted.[NonExpiring]) , 								NULL , 
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
								'vSMAgreement' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'PreviousRevision' , 
								CONVERT(VARCHAR(MAX), deleted.[PreviousRevision]) , 								NULL , 
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
								'vSMAgreement' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'PricingFrequency' , 
								CONVERT(VARCHAR(MAX), deleted.[PricingFrequency]) , 								NULL , 
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
								'vSMAgreement' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'RateTemplate' , 
								CONVERT(VARCHAR(MAX), deleted.[RateTemplate]) , 								NULL , 
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
								'vSMAgreement' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'ReportID' , 
								CONVERT(VARCHAR(MAX), deleted.[ReportID]) , 								NULL , 
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
								'vSMAgreement' , 
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
								'vSMAgreement' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'RevisionType' , 
								CONVERT(VARCHAR(MAX), deleted.[RevisionType]) , 								NULL , 
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
								'vSMAgreement' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'SMAgreementID' , 
								CONVERT(VARCHAR(MAX), deleted.[SMAgreementID]) , 								NULL , 
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
								'vSMAgreement' , 
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
								'vSMAgreement' , 
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

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMAgreement_Audit_Delete] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMAgreement_Audit_Delete]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMAgreement_Audit_Insert ON dbo.vSMAgreement
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
								'vSMAgreement' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Agreement' , 
								NULL , 
								Agreement , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the AgreementPrice column
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
								'vSMAgreement' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'AgreementPrice' , 
								NULL , 
								AgreementPrice , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the AgreementType column
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
								'vSMAgreement' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'AgreementType' , 
								NULL , 
								AgreementType , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the AlternateAgreement column
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
								'vSMAgreement' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'AlternateAgreement' , 
								NULL , 
								AlternateAgreement , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the AmendmentRevision column
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
								'vSMAgreement' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'AmendmentRevision' , 
								NULL , 
								AmendmentRevision , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the AutoRenew column
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
								'vSMAgreement' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'AutoRenew' , 
								NULL , 
								AutoRenew , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

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
							
							SELECT 
								'vSMAgreement' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'CustGroup' , 
								NULL , 
								CustGroup , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

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
							
							SELECT 
								'vSMAgreement' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Customer' , 
								NULL , 
								Customer , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the CustomerPO column
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
								'vSMAgreement' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'CustomerPO' , 
								NULL , 
								CustomerPO , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the DateActivated column
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
								'vSMAgreement' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'DateActivated' , 
								NULL , 
								DateActivated , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the DateCancelled column
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
								'vSMAgreement' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'DateCancelled' , 
								NULL , 
								DateCancelled , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the DateCreated column
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
								'vSMAgreement' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'DateCreated' , 
								NULL , 
								DateCreated , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the DateTerminated column
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
								'vSMAgreement' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'DateTerminated' , 
								NULL , 
								DateTerminated , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

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
								'vSMAgreement' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Description' , 
								NULL , 
								Description , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the EffectiveDate column
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
								'vSMAgreement' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'EffectiveDate' , 
								NULL , 
								EffectiveDate , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the ExpirationDate column
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
								'vSMAgreement' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'ExpirationDate' , 
								NULL , 
								ExpirationDate , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the NonExpiring column
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
								'vSMAgreement' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'NonExpiring' , 
								NULL , 
								NonExpiring , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the PreviousRevision column
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
								'vSMAgreement' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'PreviousRevision' , 
								NULL , 
								PreviousRevision , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the PricingFrequency column
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
								'vSMAgreement' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'PricingFrequency' , 
								NULL , 
								PricingFrequency , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the RateTemplate column
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
								'vSMAgreement' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'RateTemplate' , 
								NULL , 
								RateTemplate , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the ReportID column
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
								'vSMAgreement' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'ReportID' , 
								NULL , 
								ReportID , 
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
								'vSMAgreement' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Revision' , 
								NULL , 
								Revision , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the RevisionType column
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
								'vSMAgreement' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'RevisionType' , 
								NULL , 
								RevisionType , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the SMAgreementID column
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
								'vSMAgreement' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'SMAgreementID' , 
								NULL , 
								SMAgreementID , 
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
								'vSMAgreement' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'SMCo' , 
								NULL , 
								SMCo , 
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
								'vSMAgreement' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'UniqueAttchID' , 
								NULL , 
								UniqueAttchID , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15


 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMAgreement_Audit_Insert] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMAgreement_Audit_Insert]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMAgreement_Audit_Update ON dbo.vSMAgreement
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
								
								SELECT 							'vSMAgreement' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'Agreement' , 								CONVERT(VARCHAR(MAX), deleted.[Agreement]) , 								CONVERT(VARCHAR(MAX), inserted.[Agreement]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementID] = deleted.[SMAgreementID] 
									AND ((inserted.[Agreement] <> deleted.[Agreement]) OR (inserted.[Agreement] IS NULL AND deleted.[Agreement] IS NOT NULL) OR (inserted.[Agreement] IS NOT NULL AND deleted.[Agreement] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([AgreementPrice])
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
								
								SELECT 							'vSMAgreement' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'AgreementPrice' , 								CONVERT(VARCHAR(MAX), deleted.[AgreementPrice]) , 								CONVERT(VARCHAR(MAX), inserted.[AgreementPrice]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementID] = deleted.[SMAgreementID] 
									AND ((inserted.[AgreementPrice] <> deleted.[AgreementPrice]) OR (inserted.[AgreementPrice] IS NULL AND deleted.[AgreementPrice] IS NOT NULL) OR (inserted.[AgreementPrice] IS NOT NULL AND deleted.[AgreementPrice] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([AgreementType])
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
								
								SELECT 							'vSMAgreement' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'AgreementType' , 								CONVERT(VARCHAR(MAX), deleted.[AgreementType]) , 								CONVERT(VARCHAR(MAX), inserted.[AgreementType]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementID] = deleted.[SMAgreementID] 
									AND ((inserted.[AgreementType] <> deleted.[AgreementType]) OR (inserted.[AgreementType] IS NULL AND deleted.[AgreementType] IS NOT NULL) OR (inserted.[AgreementType] IS NOT NULL AND deleted.[AgreementType] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([AlternateAgreement])
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
								
								SELECT 							'vSMAgreement' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'AlternateAgreement' , 								CONVERT(VARCHAR(MAX), deleted.[AlternateAgreement]) , 								CONVERT(VARCHAR(MAX), inserted.[AlternateAgreement]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementID] = deleted.[SMAgreementID] 
									AND ((inserted.[AlternateAgreement] <> deleted.[AlternateAgreement]) OR (inserted.[AlternateAgreement] IS NULL AND deleted.[AlternateAgreement] IS NOT NULL) OR (inserted.[AlternateAgreement] IS NOT NULL AND deleted.[AlternateAgreement] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([AmendmentRevision])
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
								
								SELECT 							'vSMAgreement' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'AmendmentRevision' , 								CONVERT(VARCHAR(MAX), deleted.[AmendmentRevision]) , 								CONVERT(VARCHAR(MAX), inserted.[AmendmentRevision]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementID] = deleted.[SMAgreementID] 
									AND ((inserted.[AmendmentRevision] <> deleted.[AmendmentRevision]) OR (inserted.[AmendmentRevision] IS NULL AND deleted.[AmendmentRevision] IS NOT NULL) OR (inserted.[AmendmentRevision] IS NOT NULL AND deleted.[AmendmentRevision] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([AutoRenew])
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
								
								SELECT 							'vSMAgreement' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'AutoRenew' , 								CONVERT(VARCHAR(MAX), deleted.[AutoRenew]) , 								CONVERT(VARCHAR(MAX), inserted.[AutoRenew]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementID] = deleted.[SMAgreementID] 
									AND ((inserted.[AutoRenew] <> deleted.[AutoRenew]) OR (inserted.[AutoRenew] IS NULL AND deleted.[AutoRenew] IS NOT NULL) OR (inserted.[AutoRenew] IS NOT NULL AND deleted.[AutoRenew] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

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
								
								SELECT 							'vSMAgreement' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'CustGroup' , 								CONVERT(VARCHAR(MAX), deleted.[CustGroup]) , 								CONVERT(VARCHAR(MAX), inserted.[CustGroup]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementID] = deleted.[SMAgreementID] 
									AND ((inserted.[CustGroup] <> deleted.[CustGroup]) OR (inserted.[CustGroup] IS NULL AND deleted.[CustGroup] IS NOT NULL) OR (inserted.[CustGroup] IS NOT NULL AND deleted.[CustGroup] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

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
								
								SELECT 							'vSMAgreement' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'Customer' , 								CONVERT(VARCHAR(MAX), deleted.[Customer]) , 								CONVERT(VARCHAR(MAX), inserted.[Customer]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementID] = deleted.[SMAgreementID] 
									AND ((inserted.[Customer] <> deleted.[Customer]) OR (inserted.[Customer] IS NULL AND deleted.[Customer] IS NOT NULL) OR (inserted.[Customer] IS NOT NULL AND deleted.[Customer] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([CustomerPO])
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
								
								SELECT 							'vSMAgreement' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'CustomerPO' , 								CONVERT(VARCHAR(MAX), deleted.[CustomerPO]) , 								CONVERT(VARCHAR(MAX), inserted.[CustomerPO]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementID] = deleted.[SMAgreementID] 
									AND ((inserted.[CustomerPO] <> deleted.[CustomerPO]) OR (inserted.[CustomerPO] IS NULL AND deleted.[CustomerPO] IS NOT NULL) OR (inserted.[CustomerPO] IS NOT NULL AND deleted.[CustomerPO] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([DateActivated])
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
								
								SELECT 							'vSMAgreement' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'DateActivated' , 								CONVERT(VARCHAR(MAX), deleted.[DateActivated]) , 								CONVERT(VARCHAR(MAX), inserted.[DateActivated]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementID] = deleted.[SMAgreementID] 
									AND ((inserted.[DateActivated] <> deleted.[DateActivated]) OR (inserted.[DateActivated] IS NULL AND deleted.[DateActivated] IS NOT NULL) OR (inserted.[DateActivated] IS NOT NULL AND deleted.[DateActivated] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([DateCancelled])
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
								
								SELECT 							'vSMAgreement' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'DateCancelled' , 								CONVERT(VARCHAR(MAX), deleted.[DateCancelled]) , 								CONVERT(VARCHAR(MAX), inserted.[DateCancelled]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementID] = deleted.[SMAgreementID] 
									AND ((inserted.[DateCancelled] <> deleted.[DateCancelled]) OR (inserted.[DateCancelled] IS NULL AND deleted.[DateCancelled] IS NOT NULL) OR (inserted.[DateCancelled] IS NOT NULL AND deleted.[DateCancelled] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([DateCreated])
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
								
								SELECT 							'vSMAgreement' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'DateCreated' , 								CONVERT(VARCHAR(MAX), deleted.[DateCreated]) , 								CONVERT(VARCHAR(MAX), inserted.[DateCreated]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementID] = deleted.[SMAgreementID] 
									AND ((inserted.[DateCreated] <> deleted.[DateCreated]) OR (inserted.[DateCreated] IS NULL AND deleted.[DateCreated] IS NOT NULL) OR (inserted.[DateCreated] IS NOT NULL AND deleted.[DateCreated] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([DateTerminated])
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
								
								SELECT 							'vSMAgreement' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'DateTerminated' , 								CONVERT(VARCHAR(MAX), deleted.[DateTerminated]) , 								CONVERT(VARCHAR(MAX), inserted.[DateTerminated]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementID] = deleted.[SMAgreementID] 
									AND ((inserted.[DateTerminated] <> deleted.[DateTerminated]) OR (inserted.[DateTerminated] IS NULL AND deleted.[DateTerminated] IS NOT NULL) OR (inserted.[DateTerminated] IS NOT NULL AND deleted.[DateTerminated] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

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
								
								SELECT 							'vSMAgreement' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'Description' , 								CONVERT(VARCHAR(MAX), deleted.[Description]) , 								CONVERT(VARCHAR(MAX), inserted.[Description]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementID] = deleted.[SMAgreementID] 
									AND ((inserted.[Description] <> deleted.[Description]) OR (inserted.[Description] IS NULL AND deleted.[Description] IS NOT NULL) OR (inserted.[Description] IS NOT NULL AND deleted.[Description] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([EffectiveDate])
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
								
								SELECT 							'vSMAgreement' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'EffectiveDate' , 								CONVERT(VARCHAR(MAX), deleted.[EffectiveDate]) , 								CONVERT(VARCHAR(MAX), inserted.[EffectiveDate]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementID] = deleted.[SMAgreementID] 
									AND ((inserted.[EffectiveDate] <> deleted.[EffectiveDate]) OR (inserted.[EffectiveDate] IS NULL AND deleted.[EffectiveDate] IS NOT NULL) OR (inserted.[EffectiveDate] IS NOT NULL AND deleted.[EffectiveDate] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([ExpirationDate])
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
								
								SELECT 							'vSMAgreement' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'ExpirationDate' , 								CONVERT(VARCHAR(MAX), deleted.[ExpirationDate]) , 								CONVERT(VARCHAR(MAX), inserted.[ExpirationDate]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementID] = deleted.[SMAgreementID] 
									AND ((inserted.[ExpirationDate] <> deleted.[ExpirationDate]) OR (inserted.[ExpirationDate] IS NULL AND deleted.[ExpirationDate] IS NOT NULL) OR (inserted.[ExpirationDate] IS NOT NULL AND deleted.[ExpirationDate] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([NonExpiring])
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
								
								SELECT 							'vSMAgreement' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'NonExpiring' , 								CONVERT(VARCHAR(MAX), deleted.[NonExpiring]) , 								CONVERT(VARCHAR(MAX), inserted.[NonExpiring]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementID] = deleted.[SMAgreementID] 
									AND ((inserted.[NonExpiring] <> deleted.[NonExpiring]) OR (inserted.[NonExpiring] IS NULL AND deleted.[NonExpiring] IS NOT NULL) OR (inserted.[NonExpiring] IS NOT NULL AND deleted.[NonExpiring] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([PreviousRevision])
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
								
								SELECT 							'vSMAgreement' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'PreviousRevision' , 								CONVERT(VARCHAR(MAX), deleted.[PreviousRevision]) , 								CONVERT(VARCHAR(MAX), inserted.[PreviousRevision]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementID] = deleted.[SMAgreementID] 
									AND ((inserted.[PreviousRevision] <> deleted.[PreviousRevision]) OR (inserted.[PreviousRevision] IS NULL AND deleted.[PreviousRevision] IS NOT NULL) OR (inserted.[PreviousRevision] IS NOT NULL AND deleted.[PreviousRevision] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([PricingFrequency])
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
								
								SELECT 							'vSMAgreement' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'PricingFrequency' , 								CONVERT(VARCHAR(MAX), deleted.[PricingFrequency]) , 								CONVERT(VARCHAR(MAX), inserted.[PricingFrequency]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementID] = deleted.[SMAgreementID] 
									AND ((inserted.[PricingFrequency] <> deleted.[PricingFrequency]) OR (inserted.[PricingFrequency] IS NULL AND deleted.[PricingFrequency] IS NOT NULL) OR (inserted.[PricingFrequency] IS NOT NULL AND deleted.[PricingFrequency] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([RateTemplate])
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
								
								SELECT 							'vSMAgreement' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'RateTemplate' , 								CONVERT(VARCHAR(MAX), deleted.[RateTemplate]) , 								CONVERT(VARCHAR(MAX), inserted.[RateTemplate]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementID] = deleted.[SMAgreementID] 
									AND ((inserted.[RateTemplate] <> deleted.[RateTemplate]) OR (inserted.[RateTemplate] IS NULL AND deleted.[RateTemplate] IS NOT NULL) OR (inserted.[RateTemplate] IS NOT NULL AND deleted.[RateTemplate] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([ReportID])
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
								
								SELECT 							'vSMAgreement' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'ReportID' , 								CONVERT(VARCHAR(MAX), deleted.[ReportID]) , 								CONVERT(VARCHAR(MAX), inserted.[ReportID]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementID] = deleted.[SMAgreementID] 
									AND ((inserted.[ReportID] <> deleted.[ReportID]) OR (inserted.[ReportID] IS NULL AND deleted.[ReportID] IS NOT NULL) OR (inserted.[ReportID] IS NOT NULL AND deleted.[ReportID] IS NULL))
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
								
								SELECT 							'vSMAgreement' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'Revision' , 								CONVERT(VARCHAR(MAX), deleted.[Revision]) , 								CONVERT(VARCHAR(MAX), inserted.[Revision]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementID] = deleted.[SMAgreementID] 
									AND ((inserted.[Revision] <> deleted.[Revision]) OR (inserted.[Revision] IS NULL AND deleted.[Revision] IS NOT NULL) OR (inserted.[Revision] IS NOT NULL AND deleted.[Revision] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([RevisionType])
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
								
								SELECT 							'vSMAgreement' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'RevisionType' , 								CONVERT(VARCHAR(MAX), deleted.[RevisionType]) , 								CONVERT(VARCHAR(MAX), inserted.[RevisionType]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementID] = deleted.[SMAgreementID] 
									AND ((inserted.[RevisionType] <> deleted.[RevisionType]) OR (inserted.[RevisionType] IS NULL AND deleted.[RevisionType] IS NOT NULL) OR (inserted.[RevisionType] IS NOT NULL AND deleted.[RevisionType] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([SMAgreementID])
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
								
								SELECT 							'vSMAgreement' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'SMAgreementID' , 								CONVERT(VARCHAR(MAX), deleted.[SMAgreementID]) , 								CONVERT(VARCHAR(MAX), inserted.[SMAgreementID]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementID] = deleted.[SMAgreementID] 
									AND ((inserted.[SMAgreementID] <> deleted.[SMAgreementID]) OR (inserted.[SMAgreementID] IS NULL AND deleted.[SMAgreementID] IS NOT NULL) OR (inserted.[SMAgreementID] IS NOT NULL AND deleted.[SMAgreementID] IS NULL))
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
								
								SELECT 							'vSMAgreement' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'SMCo' , 								CONVERT(VARCHAR(MAX), deleted.[SMCo]) , 								CONVERT(VARCHAR(MAX), inserted.[SMCo]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementID] = deleted.[SMAgreementID] 
									AND ((inserted.[SMCo] <> deleted.[SMCo]) OR (inserted.[SMCo] IS NULL AND deleted.[SMCo] IS NOT NULL) OR (inserted.[SMCo] IS NOT NULL AND deleted.[SMCo] IS NULL))
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
								
								SELECT 							'vSMAgreement' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'UniqueAttchID' , 								CONVERT(VARCHAR(MAX), deleted.[UniqueAttchID]) , 								CONVERT(VARCHAR(MAX), inserted.[UniqueAttchID]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementID] = deleted.[SMAgreementID] 
									AND ((inserted.[UniqueAttchID] <> deleted.[UniqueAttchID]) OR (inserted.[UniqueAttchID] IS NULL AND deleted.[UniqueAttchID] IS NOT NULL) OR (inserted.[UniqueAttchID] IS NOT NULL AND deleted.[UniqueAttchID] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 



 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMAgreement_Audit_Update] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMAgreement_Audit_Update]', 'last', 'update', null
GO
ALTER TABLE [dbo].[vSMAgreement] ADD CONSTRAINT [CK_vSMAgreement_Dates] CHECK ((case when [DateActivated] IS NULL then checksum(~[dbo].[vfEqualsNull]([DateCancelled]),(0),~[dbo].[vfEqualsNull]([EffectiveDate]),~[dbo].[vfEqualsNull]([ExpirationDate])) else checksum((0),~[dbo].[vfEqualsNull]([DateTerminated]),(1),[dbo].[vfIsEqual]([NonExpiring],'N')) end=checksum(~[dbo].[vfEqualsNull]([DateCancelled]),~[dbo].[vfEqualsNull]([DateTerminated]),~[dbo].[vfEqualsNull]([EffectiveDate]),~[dbo].[vfEqualsNull]([ExpirationDate])) AND [EffectiveDate]<[ExpirationDate]))
GO
ALTER TABLE [dbo].[vSMAgreement] ADD CONSTRAINT [PK_vSMAgreement] PRIMARY KEY CLUSTERED  ([SMAgreementID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMAgreement] ADD CONSTRAINT [IX_vSMAgreement] UNIQUE NONCLUSTERED  ([SMCo], [Agreement], [Revision]) ON [PRIMARY]
GO

ALTER TABLE [dbo].[vSMAgreement] WITH NOCHECK ADD CONSTRAINT [FK_vSMAgreement_vSMAgreement] FOREIGN KEY ([SMCo], [Agreement], [PreviousRevision]) REFERENCES [dbo].[vSMAgreement] ([SMCo], [Agreement], [Revision])
GO
ALTER TABLE [dbo].[vSMAgreement] WITH NOCHECK ADD CONSTRAINT [FK_vSMAgreement_vSMAgreementType] FOREIGN KEY ([SMCo], [AgreementType]) REFERENCES [dbo].[vSMAgreementType] ([SMCo], [AgreementType])
GO
ALTER TABLE [dbo].[vSMAgreement] WITH NOCHECK ADD CONSTRAINT [FK_vSMAgreement_vSMCustomer] FOREIGN KEY ([SMCo], [CustGroup], [Customer]) REFERENCES [dbo].[vSMCustomer] ([SMCo], [CustGroup], [Customer])
GO
