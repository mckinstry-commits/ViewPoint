CREATE TABLE [dbo].[vSMAgreementService]
(
[SMAgreementServiceID] [bigint] NOT NULL IDENTITY(1, 1),
[SMCo] [dbo].[bCompany] NOT NULL,
[Agreement] [varchar] (15) COLLATE Latin1_General_BIN NOT NULL,
[Revision] [int] NOT NULL,
[Service] [int] NOT NULL,
[Description] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ServiceSite] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[CallType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[ServiceCenter] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[TaxSource] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[PricingMethod] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[PricingFrequency] [char] (1) COLLATE Latin1_General_BIN NULL,
[PricingPrice] [dbo].[bDollar] NULL,
[BilledSeparately] [dbo].[bYN] NULL CONSTRAINT [DF_vSMAgreementService_BilledSeparately] DEFAULT ('N'),
[PricingRateTemplate] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[ScheOptContactBeforeScheduling] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vSMAgreementService_ScheOptContactBeforeScheduling] DEFAULT ('N'),
[ScheOptDueType] [tinyint] NULL,
[ScheOptDays] [tinyint] NULL,
[RecurringPatternType] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vSMAgreementService_RecurringPatternType] DEFAULT ('D'),
[DailyType] [tinyint] NULL,
[DailyEveryDays] [int] NULL,
[WeeklyEveryWeeks] [int] NULL,
[WeeklyEverySun] [dbo].[bYN] NULL,
[WeeklyEveryMon] [dbo].[bYN] NULL,
[WeeklyEveryTue] [dbo].[bYN] NULL,
[WeeklyEveryWed] [dbo].[bYN] NULL,
[WeeklyEveryThu] [dbo].[bYN] NULL,
[WeeklyEveryFri] [dbo].[bYN] NULL,
[WeeklyEverySat] [dbo].[bYN] NULL,
[MonthlyType] [tinyint] NULL,
[MonthlyDay] [tinyint] NULL,
[MonthlyDayEveryMonths] [tinyint] NULL,
[MonthlyEveryOrdinal] [tinyint] NULL,
[MonthlyEveryDay] [tinyint] NULL,
[MonthlyEveryMonths] [tinyint] NULL,
[MonthlySelectOrdinal] [tinyint] NULL,
[MonthlySelectDay] [tinyint] NULL,
[MonthlyJan] [dbo].[bYN] NULL,
[MonthlyFeb] [dbo].[bYN] NULL,
[MonthlyMar] [dbo].[bYN] NULL,
[MonthlyApr] [dbo].[bYN] NULL,
[MonthlyMay] [dbo].[bYN] NULL,
[MonthlyJun] [dbo].[bYN] NULL,
[MonthlyJul] [dbo].[bYN] NULL,
[MonthlyAug] [dbo].[bYN] NULL,
[MonthlySep] [dbo].[bYN] NULL,
[MonthlyOct] [dbo].[bYN] NULL,
[MonthlyNov] [dbo].[bYN] NULL,
[MonthlyDec] [dbo].[bYN] NULL,
[YearlyType] [tinyint] NULL,
[YearlyEveryYear] [tinyint] NULL,
[YearlyEveryDateMonth] [tinyint] NULL,
[YearlyEveryDateMonthDay] [tinyint] NULL,
[YearlyEveryDayOrdinal] [tinyint] NULL,
[YearlyEveryDayDay] [tinyint] NULL,
[YearlyEveryDayMonth] [tinyint] NULL,
[WasCopied] [bit] NOT NULL CONSTRAINT [DF_vSMAgreementService_WasCopied] DEFAULT ((0)),
[Notes] [dbo].[bNotes] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[Division] [varchar] (10) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 3/12/12
-- Description:	Trigger validation for vSMAgreementService
-- =============================================
CREATE TRIGGER [dbo].[vtSMAgreementServiceiud]
   ON  [dbo].[vSMAgreementService]
   AFTER INSERT,UPDATE,DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF EXISTS(SELECT 1 
		FROM dbo.vSMAgreement
			INNER JOIN (
				SELECT SMCo, Agreement, Revision
				FROM INSERTED
				UNION
				SELECT SMCo, Agreement, Revision
				FROM DELETED) RelatedAgreements ON vSMAgreement.SMCo = RelatedAgreements.SMCo AND vSMAgreement.Agreement = RelatedAgreements.Agreement AND vSMAgreement.Revision = RelatedAgreements.Revision
		WHERE DateActivated IS NOT NULL
		AND DateTerminated IS NULL)
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
-- Author:		Matthew Bradford
-- Create date: 4/29/2013
-- Description:	If pricing is changed away from flat price remove flat price split records.
-- =============================================
CREATE TRIGGER [dbo].[vtSMAgreementServicePricingu] 
   ON  [dbo].[vSMAgreementService]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    IF UPDATE(PricingMethod) OR UPDATE(PricingPrice)
    BEGIN
		DELETE dbo.vSMFlatPriceRevenueSplit FROM 
			inserted INNER JOIN vSMEntity
			ON 
				inserted.SMCo = vSMEntity.SMCo AND
				inserted.Agreement = vSMEntity.Agreement AND
				inserted.Service = vSMEntity.AgreementService AND
				inserted.Revision = vSMEntity.AgreementRevision
			INNER JOIN dbo.vSMFlatPriceRevenueSplit 
			ON
				vSMFlatPriceRevenueSplit.SMCo = vSMEntity.SMCo AND
				vSMFlatPriceRevenueSplit.EntitySeq = vSMEntity.EntitySeq				
		WHERE 
			inserted.PricingMethod <> 'T' OR
			inserted.PricingPrice IS NULL
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
-- Description:	Trigger validation for vSMAgreementService
-- Modification: MDB 2/21/13 Added validation for defferals TFS 40933
-- =============================================
CREATE TRIGGER [dbo].[vtSMAgreementServiceu]
   ON  [dbo].[vSMAgreementService]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF EXISTS(SELECT 1 
		FROM INSERTED
			INNER JOIN dbo.SMAgreementBillingSchedule ON INSERTED.SMCo = SMAgreementBillingSchedule.SMCo AND INSERTED.Agreement = SMAgreementBillingSchedule.Agreement AND INSERTED.Revision = SMAgreementBillingSchedule.Revision AND INSERTED.[Service] = SMAgreementBillingSchedule.[Service]
		WHERE dbo.vfIsEqual(INSERTED.BilledSeparately, 'Y') = 0)
	BEGIN
    	RAISERROR(N'All service billings must be deleted before you can disable bill separately.', 11, -1)
    	ROLLBACK TRANSACTION
		RETURN
	END;
	IF EXISTS (SELECT 1
		FROM INSERTED
			INNER JOIN dbo.SMAgreementRevenueDeferral ON INSERTED.SMCo = dbo.SMAgreementRevenueDeferral.SMCo AND INSERTED.Agreement = dbo.SMAgreementRevenueDeferral.Agreement AND INSERTED.Revision = dbo.SMAgreementRevenueDeferral.Revision AND INSERTED.[Service] = dbo.SMAgreementRevenueDeferral.[Service]
			WHERE dbo.vfIsEqual(INSERTED.BilledSeparately, 'Y') = 0)			
	BEGIN
	    RAISERROR(N'All revenue deferrals must be deleted before you can disable bill seperately.', 11, -1)
    	ROLLBACK TRANSACTION
		RETURN
	END
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMAgreementService_Audit_Delete ON dbo.vSMAgreementService
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
								'vSMAgreementService' , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'BilledSeparately' , 
								CONVERT(VARCHAR(MAX), deleted.[BilledSeparately]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'CallType' , 
								CONVERT(VARCHAR(MAX), deleted.[CallType]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'DailyEveryDays' , 
								CONVERT(VARCHAR(MAX), deleted.[DailyEveryDays]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'DailyType' , 
								CONVERT(VARCHAR(MAX), deleted.[DailyType]) , 								NULL , 
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
								'vSMAgreementService' , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'Division' , 
								CONVERT(VARCHAR(MAX), deleted.[Division]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'MonthlyApr' , 
								CONVERT(VARCHAR(MAX), deleted.[MonthlyApr]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'MonthlyAug' , 
								CONVERT(VARCHAR(MAX), deleted.[MonthlyAug]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'MonthlyDay' , 
								CONVERT(VARCHAR(MAX), deleted.[MonthlyDay]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'MonthlyDayEveryMonths' , 
								CONVERT(VARCHAR(MAX), deleted.[MonthlyDayEveryMonths]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'MonthlyDec' , 
								CONVERT(VARCHAR(MAX), deleted.[MonthlyDec]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'MonthlyEveryDay' , 
								CONVERT(VARCHAR(MAX), deleted.[MonthlyEveryDay]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'MonthlyEveryMonths' , 
								CONVERT(VARCHAR(MAX), deleted.[MonthlyEveryMonths]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'MonthlyEveryOrdinal' , 
								CONVERT(VARCHAR(MAX), deleted.[MonthlyEveryOrdinal]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'MonthlyFeb' , 
								CONVERT(VARCHAR(MAX), deleted.[MonthlyFeb]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'MonthlyJan' , 
								CONVERT(VARCHAR(MAX), deleted.[MonthlyJan]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'MonthlyJul' , 
								CONVERT(VARCHAR(MAX), deleted.[MonthlyJul]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'MonthlyJun' , 
								CONVERT(VARCHAR(MAX), deleted.[MonthlyJun]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'MonthlyMar' , 
								CONVERT(VARCHAR(MAX), deleted.[MonthlyMar]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'MonthlyMay' , 
								CONVERT(VARCHAR(MAX), deleted.[MonthlyMay]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'MonthlyNov' , 
								CONVERT(VARCHAR(MAX), deleted.[MonthlyNov]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'MonthlyOct' , 
								CONVERT(VARCHAR(MAX), deleted.[MonthlyOct]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'MonthlySelectDay' , 
								CONVERT(VARCHAR(MAX), deleted.[MonthlySelectDay]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'MonthlySelectOrdinal' , 
								CONVERT(VARCHAR(MAX), deleted.[MonthlySelectOrdinal]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'MonthlySep' , 
								CONVERT(VARCHAR(MAX), deleted.[MonthlySep]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'MonthlyType' , 
								CONVERT(VARCHAR(MAX), deleted.[MonthlyType]) , 								NULL , 
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
								'vSMAgreementService' , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'PricingMethod' , 
								CONVERT(VARCHAR(MAX), deleted.[PricingMethod]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'PricingPrice' , 
								CONVERT(VARCHAR(MAX), deleted.[PricingPrice]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'PricingRateTemplate' , 
								CONVERT(VARCHAR(MAX), deleted.[PricingRateTemplate]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'RecurringPatternType' , 
								CONVERT(VARCHAR(MAX), deleted.[RecurringPatternType]) , 								NULL , 
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
								'vSMAgreementService' , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'SMAgreementServiceID' , 
								CONVERT(VARCHAR(MAX), deleted.[SMAgreementServiceID]) , 								NULL , 
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
								'vSMAgreementService' , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'ScheOptContactBeforeScheduling' , 
								CONVERT(VARCHAR(MAX), deleted.[ScheOptContactBeforeScheduling]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'ScheOptDays' , 
								CONVERT(VARCHAR(MAX), deleted.[ScheOptDays]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'ScheOptDueType' , 
								CONVERT(VARCHAR(MAX), deleted.[ScheOptDueType]) , 								NULL , 
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
								'vSMAgreementService' , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'ServiceCenter' , 
								CONVERT(VARCHAR(MAX), deleted.[ServiceCenter]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'ServiceSite' , 
								CONVERT(VARCHAR(MAX), deleted.[ServiceSite]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'TaxSource' , 
								CONVERT(VARCHAR(MAX), deleted.[TaxSource]) , 								NULL , 
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
								'vSMAgreementService' , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'WasCopied' , 
								CONVERT(VARCHAR(MAX), deleted.[WasCopied]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'WeeklyEveryFri' , 
								CONVERT(VARCHAR(MAX), deleted.[WeeklyEveryFri]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'WeeklyEveryMon' , 
								CONVERT(VARCHAR(MAX), deleted.[WeeklyEveryMon]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'WeeklyEverySat' , 
								CONVERT(VARCHAR(MAX), deleted.[WeeklyEverySat]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'WeeklyEverySun' , 
								CONVERT(VARCHAR(MAX), deleted.[WeeklyEverySun]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'WeeklyEveryThu' , 
								CONVERT(VARCHAR(MAX), deleted.[WeeklyEveryThu]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'WeeklyEveryTue' , 
								CONVERT(VARCHAR(MAX), deleted.[WeeklyEveryTue]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'WeeklyEveryWed' , 
								CONVERT(VARCHAR(MAX), deleted.[WeeklyEveryWed]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'WeeklyEveryWeeks' , 
								CONVERT(VARCHAR(MAX), deleted.[WeeklyEveryWeeks]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'YearlyEveryDateMonth' , 
								CONVERT(VARCHAR(MAX), deleted.[YearlyEveryDateMonth]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'YearlyEveryDateMonthDay' , 
								CONVERT(VARCHAR(MAX), deleted.[YearlyEveryDateMonthDay]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'YearlyEveryDayDay' , 
								CONVERT(VARCHAR(MAX), deleted.[YearlyEveryDayDay]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'YearlyEveryDayMonth' , 
								CONVERT(VARCHAR(MAX), deleted.[YearlyEveryDayMonth]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'YearlyEveryDayOrdinal' , 
								CONVERT(VARCHAR(MAX), deleted.[YearlyEveryDayOrdinal]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'YearlyEveryYear' , 
								CONVERT(VARCHAR(MAX), deleted.[YearlyEveryYear]) , 								NULL , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'YearlyType' , 
								CONVERT(VARCHAR(MAX), deleted.[YearlyType]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							
 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMAgreementService_Audit_Delete] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMAgreementService_Audit_Delete]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMAgreementService_Audit_Insert ON dbo.vSMAgreementService
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
								'vSMAgreementService' , 
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

-- log additions to the BilledSeparately column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'BilledSeparately' , 
								NULL , 
								[BilledSeparately] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the CallType column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'CallType' , 
								NULL , 
								[CallType] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the DailyEveryDays column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'DailyEveryDays' , 
								NULL , 
								[DailyEveryDays] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the DailyType column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'DailyType' , 
								NULL , 
								[DailyType] , 
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
								'vSMAgreementService' , 
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
							WHERE afc.AuditFlagID = 15

-- log additions to the Division column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Division' , 
								NULL , 
								[Division] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the MonthlyApr column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'MonthlyApr' , 
								NULL , 
								[MonthlyApr] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the MonthlyAug column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'MonthlyAug' , 
								NULL , 
								[MonthlyAug] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the MonthlyDay column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'MonthlyDay' , 
								NULL , 
								[MonthlyDay] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the MonthlyDayEveryMonths column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'MonthlyDayEveryMonths' , 
								NULL , 
								[MonthlyDayEveryMonths] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the MonthlyDec column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'MonthlyDec' , 
								NULL , 
								[MonthlyDec] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the MonthlyEveryDay column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'MonthlyEveryDay' , 
								NULL , 
								[MonthlyEveryDay] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the MonthlyEveryMonths column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'MonthlyEveryMonths' , 
								NULL , 
								[MonthlyEveryMonths] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the MonthlyEveryOrdinal column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'MonthlyEveryOrdinal' , 
								NULL , 
								[MonthlyEveryOrdinal] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the MonthlyFeb column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'MonthlyFeb' , 
								NULL , 
								[MonthlyFeb] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the MonthlyJan column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'MonthlyJan' , 
								NULL , 
								[MonthlyJan] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the MonthlyJul column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'MonthlyJul' , 
								NULL , 
								[MonthlyJul] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the MonthlyJun column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'MonthlyJun' , 
								NULL , 
								[MonthlyJun] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the MonthlyMar column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'MonthlyMar' , 
								NULL , 
								[MonthlyMar] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the MonthlyMay column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'MonthlyMay' , 
								NULL , 
								[MonthlyMay] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the MonthlyNov column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'MonthlyNov' , 
								NULL , 
								[MonthlyNov] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the MonthlyOct column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'MonthlyOct' , 
								NULL , 
								[MonthlyOct] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the MonthlySelectDay column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'MonthlySelectDay' , 
								NULL , 
								[MonthlySelectDay] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the MonthlySelectOrdinal column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'MonthlySelectOrdinal' , 
								NULL , 
								[MonthlySelectOrdinal] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the MonthlySep column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'MonthlySep' , 
								NULL , 
								[MonthlySep] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the MonthlyType column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'MonthlyType' , 
								NULL , 
								[MonthlyType] , 
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'PricingFrequency' , 
								NULL , 
								[PricingFrequency] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the PricingMethod column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'PricingMethod' , 
								NULL , 
								[PricingMethod] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the PricingPrice column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'PricingPrice' , 
								NULL , 
								[PricingPrice] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the PricingRateTemplate column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'PricingRateTemplate' , 
								NULL , 
								[PricingRateTemplate] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the RecurringPatternType column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'RecurringPatternType' , 
								NULL , 
								[RecurringPatternType] , 
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
								'vSMAgreementService' , 
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

-- log additions to the SMAgreementServiceID column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'SMAgreementServiceID' , 
								NULL , 
								[SMAgreementServiceID] , 
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
								'vSMAgreementService' , 
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

-- log additions to the ScheOptContactBeforeScheduling column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'ScheOptContactBeforeScheduling' , 
								NULL , 
								[ScheOptContactBeforeScheduling] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the ScheOptDays column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'ScheOptDays' , 
								NULL , 
								[ScheOptDays] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the ScheOptDueType column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'ScheOptDueType' , 
								NULL , 
								[ScheOptDueType] , 
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
								'vSMAgreementService' , 
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

-- log additions to the ServiceCenter column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'ServiceCenter' , 
								NULL , 
								[ServiceCenter] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the ServiceSite column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'ServiceSite' , 
								NULL , 
								[ServiceSite] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the TaxSource column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'TaxSource' , 
								NULL , 
								[TaxSource] , 
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
								'vSMAgreementService' , 
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

-- log additions to the WasCopied column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'WasCopied' , 
								NULL , 
								[WasCopied] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the WeeklyEveryFri column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'WeeklyEveryFri' , 
								NULL , 
								[WeeklyEveryFri] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the WeeklyEveryMon column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'WeeklyEveryMon' , 
								NULL , 
								[WeeklyEveryMon] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the WeeklyEverySat column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'WeeklyEverySat' , 
								NULL , 
								[WeeklyEverySat] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the WeeklyEverySun column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'WeeklyEverySun' , 
								NULL , 
								[WeeklyEverySun] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the WeeklyEveryThu column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'WeeklyEveryThu' , 
								NULL , 
								[WeeklyEveryThu] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the WeeklyEveryTue column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'WeeklyEveryTue' , 
								NULL , 
								[WeeklyEveryTue] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the WeeklyEveryWed column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'WeeklyEveryWed' , 
								NULL , 
								[WeeklyEveryWed] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the WeeklyEveryWeeks column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'WeeklyEveryWeeks' , 
								NULL , 
								[WeeklyEveryWeeks] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the YearlyEveryDateMonth column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'YearlyEveryDateMonth' , 
								NULL , 
								[YearlyEveryDateMonth] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the YearlyEveryDateMonthDay column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'YearlyEveryDateMonthDay' , 
								NULL , 
								[YearlyEveryDateMonthDay] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the YearlyEveryDayDay column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'YearlyEveryDayDay' , 
								NULL , 
								[YearlyEveryDayDay] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the YearlyEveryDayMonth column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'YearlyEveryDayMonth' , 
								NULL , 
								[YearlyEveryDayMonth] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the YearlyEveryDayOrdinal column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'YearlyEveryDayOrdinal' , 
								NULL , 
								[YearlyEveryDayOrdinal] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the YearlyEveryYear column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'YearlyEveryYear' , 
								NULL , 
								[YearlyEveryYear] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

-- log additions to the YearlyType column
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
								'vSMAgreementService' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'YearlyType' , 
								NULL , 
								[YearlyType] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15


 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMAgreementService_Audit_Insert] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMAgreementService_Audit_Insert]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMAgreementService_Audit_Update ON dbo.vSMAgreementService
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'Agreement' , 								CONVERT(VARCHAR(MAX), deleted.[Agreement]) , 								CONVERT(VARCHAR(MAX), inserted.[Agreement]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[Agreement] <> deleted.[Agreement]) OR (inserted.[Agreement] IS NULL AND deleted.[Agreement] IS NOT NULL) OR (inserted.[Agreement] IS NOT NULL AND deleted.[Agreement] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([BilledSeparately])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'BilledSeparately' , 								CONVERT(VARCHAR(MAX), deleted.[BilledSeparately]) , 								CONVERT(VARCHAR(MAX), inserted.[BilledSeparately]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[BilledSeparately] <> deleted.[BilledSeparately]) OR (inserted.[BilledSeparately] IS NULL AND deleted.[BilledSeparately] IS NOT NULL) OR (inserted.[BilledSeparately] IS NOT NULL AND deleted.[BilledSeparately] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([CallType])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'CallType' , 								CONVERT(VARCHAR(MAX), deleted.[CallType]) , 								CONVERT(VARCHAR(MAX), inserted.[CallType]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[CallType] <> deleted.[CallType]) OR (inserted.[CallType] IS NULL AND deleted.[CallType] IS NOT NULL) OR (inserted.[CallType] IS NOT NULL AND deleted.[CallType] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([DailyEveryDays])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'DailyEveryDays' , 								CONVERT(VARCHAR(MAX), deleted.[DailyEveryDays]) , 								CONVERT(VARCHAR(MAX), inserted.[DailyEveryDays]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[DailyEveryDays] <> deleted.[DailyEveryDays]) OR (inserted.[DailyEveryDays] IS NULL AND deleted.[DailyEveryDays] IS NOT NULL) OR (inserted.[DailyEveryDays] IS NOT NULL AND deleted.[DailyEveryDays] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([DailyType])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'DailyType' , 								CONVERT(VARCHAR(MAX), deleted.[DailyType]) , 								CONVERT(VARCHAR(MAX), inserted.[DailyType]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[DailyType] <> deleted.[DailyType]) OR (inserted.[DailyType] IS NULL AND deleted.[DailyType] IS NOT NULL) OR (inserted.[DailyType] IS NOT NULL AND deleted.[DailyType] IS NULL))
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'Description' , 								CONVERT(VARCHAR(MAX), deleted.[Description]) , 								CONVERT(VARCHAR(MAX), inserted.[Description]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[Description] <> deleted.[Description]) OR (inserted.[Description] IS NULL AND deleted.[Description] IS NOT NULL) OR (inserted.[Description] IS NOT NULL AND deleted.[Description] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([Division])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'Division' , 								CONVERT(VARCHAR(MAX), deleted.[Division]) , 								CONVERT(VARCHAR(MAX), inserted.[Division]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[Division] <> deleted.[Division]) OR (inserted.[Division] IS NULL AND deleted.[Division] IS NOT NULL) OR (inserted.[Division] IS NOT NULL AND deleted.[Division] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([MonthlyApr])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'MonthlyApr' , 								CONVERT(VARCHAR(MAX), deleted.[MonthlyApr]) , 								CONVERT(VARCHAR(MAX), inserted.[MonthlyApr]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[MonthlyApr] <> deleted.[MonthlyApr]) OR (inserted.[MonthlyApr] IS NULL AND deleted.[MonthlyApr] IS NOT NULL) OR (inserted.[MonthlyApr] IS NOT NULL AND deleted.[MonthlyApr] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([MonthlyAug])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'MonthlyAug' , 								CONVERT(VARCHAR(MAX), deleted.[MonthlyAug]) , 								CONVERT(VARCHAR(MAX), inserted.[MonthlyAug]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[MonthlyAug] <> deleted.[MonthlyAug]) OR (inserted.[MonthlyAug] IS NULL AND deleted.[MonthlyAug] IS NOT NULL) OR (inserted.[MonthlyAug] IS NOT NULL AND deleted.[MonthlyAug] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([MonthlyDay])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'MonthlyDay' , 								CONVERT(VARCHAR(MAX), deleted.[MonthlyDay]) , 								CONVERT(VARCHAR(MAX), inserted.[MonthlyDay]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[MonthlyDay] <> deleted.[MonthlyDay]) OR (inserted.[MonthlyDay] IS NULL AND deleted.[MonthlyDay] IS NOT NULL) OR (inserted.[MonthlyDay] IS NOT NULL AND deleted.[MonthlyDay] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([MonthlyDayEveryMonths])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'MonthlyDayEveryMonths' , 								CONVERT(VARCHAR(MAX), deleted.[MonthlyDayEveryMonths]) , 								CONVERT(VARCHAR(MAX), inserted.[MonthlyDayEveryMonths]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[MonthlyDayEveryMonths] <> deleted.[MonthlyDayEveryMonths]) OR (inserted.[MonthlyDayEveryMonths] IS NULL AND deleted.[MonthlyDayEveryMonths] IS NOT NULL) OR (inserted.[MonthlyDayEveryMonths] IS NOT NULL AND deleted.[MonthlyDayEveryMonths] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([MonthlyDec])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'MonthlyDec' , 								CONVERT(VARCHAR(MAX), deleted.[MonthlyDec]) , 								CONVERT(VARCHAR(MAX), inserted.[MonthlyDec]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[MonthlyDec] <> deleted.[MonthlyDec]) OR (inserted.[MonthlyDec] IS NULL AND deleted.[MonthlyDec] IS NOT NULL) OR (inserted.[MonthlyDec] IS NOT NULL AND deleted.[MonthlyDec] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([MonthlyEveryDay])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'MonthlyEveryDay' , 								CONVERT(VARCHAR(MAX), deleted.[MonthlyEveryDay]) , 								CONVERT(VARCHAR(MAX), inserted.[MonthlyEveryDay]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[MonthlyEveryDay] <> deleted.[MonthlyEveryDay]) OR (inserted.[MonthlyEveryDay] IS NULL AND deleted.[MonthlyEveryDay] IS NOT NULL) OR (inserted.[MonthlyEveryDay] IS NOT NULL AND deleted.[MonthlyEveryDay] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([MonthlyEveryMonths])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'MonthlyEveryMonths' , 								CONVERT(VARCHAR(MAX), deleted.[MonthlyEveryMonths]) , 								CONVERT(VARCHAR(MAX), inserted.[MonthlyEveryMonths]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[MonthlyEveryMonths] <> deleted.[MonthlyEveryMonths]) OR (inserted.[MonthlyEveryMonths] IS NULL AND deleted.[MonthlyEveryMonths] IS NOT NULL) OR (inserted.[MonthlyEveryMonths] IS NOT NULL AND deleted.[MonthlyEveryMonths] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([MonthlyEveryOrdinal])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'MonthlyEveryOrdinal' , 								CONVERT(VARCHAR(MAX), deleted.[MonthlyEveryOrdinal]) , 								CONVERT(VARCHAR(MAX), inserted.[MonthlyEveryOrdinal]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[MonthlyEveryOrdinal] <> deleted.[MonthlyEveryOrdinal]) OR (inserted.[MonthlyEveryOrdinal] IS NULL AND deleted.[MonthlyEveryOrdinal] IS NOT NULL) OR (inserted.[MonthlyEveryOrdinal] IS NOT NULL AND deleted.[MonthlyEveryOrdinal] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([MonthlyFeb])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'MonthlyFeb' , 								CONVERT(VARCHAR(MAX), deleted.[MonthlyFeb]) , 								CONVERT(VARCHAR(MAX), inserted.[MonthlyFeb]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[MonthlyFeb] <> deleted.[MonthlyFeb]) OR (inserted.[MonthlyFeb] IS NULL AND deleted.[MonthlyFeb] IS NOT NULL) OR (inserted.[MonthlyFeb] IS NOT NULL AND deleted.[MonthlyFeb] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([MonthlyJan])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'MonthlyJan' , 								CONVERT(VARCHAR(MAX), deleted.[MonthlyJan]) , 								CONVERT(VARCHAR(MAX), inserted.[MonthlyJan]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[MonthlyJan] <> deleted.[MonthlyJan]) OR (inserted.[MonthlyJan] IS NULL AND deleted.[MonthlyJan] IS NOT NULL) OR (inserted.[MonthlyJan] IS NOT NULL AND deleted.[MonthlyJan] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([MonthlyJul])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'MonthlyJul' , 								CONVERT(VARCHAR(MAX), deleted.[MonthlyJul]) , 								CONVERT(VARCHAR(MAX), inserted.[MonthlyJul]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[MonthlyJul] <> deleted.[MonthlyJul]) OR (inserted.[MonthlyJul] IS NULL AND deleted.[MonthlyJul] IS NOT NULL) OR (inserted.[MonthlyJul] IS NOT NULL AND deleted.[MonthlyJul] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([MonthlyJun])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'MonthlyJun' , 								CONVERT(VARCHAR(MAX), deleted.[MonthlyJun]) , 								CONVERT(VARCHAR(MAX), inserted.[MonthlyJun]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[MonthlyJun] <> deleted.[MonthlyJun]) OR (inserted.[MonthlyJun] IS NULL AND deleted.[MonthlyJun] IS NOT NULL) OR (inserted.[MonthlyJun] IS NOT NULL AND deleted.[MonthlyJun] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([MonthlyMar])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'MonthlyMar' , 								CONVERT(VARCHAR(MAX), deleted.[MonthlyMar]) , 								CONVERT(VARCHAR(MAX), inserted.[MonthlyMar]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[MonthlyMar] <> deleted.[MonthlyMar]) OR (inserted.[MonthlyMar] IS NULL AND deleted.[MonthlyMar] IS NOT NULL) OR (inserted.[MonthlyMar] IS NOT NULL AND deleted.[MonthlyMar] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([MonthlyMay])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'MonthlyMay' , 								CONVERT(VARCHAR(MAX), deleted.[MonthlyMay]) , 								CONVERT(VARCHAR(MAX), inserted.[MonthlyMay]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[MonthlyMay] <> deleted.[MonthlyMay]) OR (inserted.[MonthlyMay] IS NULL AND deleted.[MonthlyMay] IS NOT NULL) OR (inserted.[MonthlyMay] IS NOT NULL AND deleted.[MonthlyMay] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([MonthlyNov])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'MonthlyNov' , 								CONVERT(VARCHAR(MAX), deleted.[MonthlyNov]) , 								CONVERT(VARCHAR(MAX), inserted.[MonthlyNov]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[MonthlyNov] <> deleted.[MonthlyNov]) OR (inserted.[MonthlyNov] IS NULL AND deleted.[MonthlyNov] IS NOT NULL) OR (inserted.[MonthlyNov] IS NOT NULL AND deleted.[MonthlyNov] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([MonthlyOct])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'MonthlyOct' , 								CONVERT(VARCHAR(MAX), deleted.[MonthlyOct]) , 								CONVERT(VARCHAR(MAX), inserted.[MonthlyOct]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[MonthlyOct] <> deleted.[MonthlyOct]) OR (inserted.[MonthlyOct] IS NULL AND deleted.[MonthlyOct] IS NOT NULL) OR (inserted.[MonthlyOct] IS NOT NULL AND deleted.[MonthlyOct] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([MonthlySelectDay])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'MonthlySelectDay' , 								CONVERT(VARCHAR(MAX), deleted.[MonthlySelectDay]) , 								CONVERT(VARCHAR(MAX), inserted.[MonthlySelectDay]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[MonthlySelectDay] <> deleted.[MonthlySelectDay]) OR (inserted.[MonthlySelectDay] IS NULL AND deleted.[MonthlySelectDay] IS NOT NULL) OR (inserted.[MonthlySelectDay] IS NOT NULL AND deleted.[MonthlySelectDay] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([MonthlySelectOrdinal])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'MonthlySelectOrdinal' , 								CONVERT(VARCHAR(MAX), deleted.[MonthlySelectOrdinal]) , 								CONVERT(VARCHAR(MAX), inserted.[MonthlySelectOrdinal]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[MonthlySelectOrdinal] <> deleted.[MonthlySelectOrdinal]) OR (inserted.[MonthlySelectOrdinal] IS NULL AND deleted.[MonthlySelectOrdinal] IS NOT NULL) OR (inserted.[MonthlySelectOrdinal] IS NOT NULL AND deleted.[MonthlySelectOrdinal] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([MonthlySep])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'MonthlySep' , 								CONVERT(VARCHAR(MAX), deleted.[MonthlySep]) , 								CONVERT(VARCHAR(MAX), inserted.[MonthlySep]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[MonthlySep] <> deleted.[MonthlySep]) OR (inserted.[MonthlySep] IS NULL AND deleted.[MonthlySep] IS NOT NULL) OR (inserted.[MonthlySep] IS NOT NULL AND deleted.[MonthlySep] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([MonthlyType])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'MonthlyType' , 								CONVERT(VARCHAR(MAX), deleted.[MonthlyType]) , 								CONVERT(VARCHAR(MAX), inserted.[MonthlyType]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[MonthlyType] <> deleted.[MonthlyType]) OR (inserted.[MonthlyType] IS NULL AND deleted.[MonthlyType] IS NOT NULL) OR (inserted.[MonthlyType] IS NOT NULL AND deleted.[MonthlyType] IS NULL))
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'PricingFrequency' , 								CONVERT(VARCHAR(MAX), deleted.[PricingFrequency]) , 								CONVERT(VARCHAR(MAX), inserted.[PricingFrequency]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[PricingFrequency] <> deleted.[PricingFrequency]) OR (inserted.[PricingFrequency] IS NULL AND deleted.[PricingFrequency] IS NOT NULL) OR (inserted.[PricingFrequency] IS NOT NULL AND deleted.[PricingFrequency] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([PricingMethod])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'PricingMethod' , 								CONVERT(VARCHAR(MAX), deleted.[PricingMethod]) , 								CONVERT(VARCHAR(MAX), inserted.[PricingMethod]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[PricingMethod] <> deleted.[PricingMethod]) OR (inserted.[PricingMethod] IS NULL AND deleted.[PricingMethod] IS NOT NULL) OR (inserted.[PricingMethod] IS NOT NULL AND deleted.[PricingMethod] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([PricingPrice])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'PricingPrice' , 								CONVERT(VARCHAR(MAX), deleted.[PricingPrice]) , 								CONVERT(VARCHAR(MAX), inserted.[PricingPrice]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[PricingPrice] <> deleted.[PricingPrice]) OR (inserted.[PricingPrice] IS NULL AND deleted.[PricingPrice] IS NOT NULL) OR (inserted.[PricingPrice] IS NOT NULL AND deleted.[PricingPrice] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([PricingRateTemplate])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'PricingRateTemplate' , 								CONVERT(VARCHAR(MAX), deleted.[PricingRateTemplate]) , 								CONVERT(VARCHAR(MAX), inserted.[PricingRateTemplate]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[PricingRateTemplate] <> deleted.[PricingRateTemplate]) OR (inserted.[PricingRateTemplate] IS NULL AND deleted.[PricingRateTemplate] IS NOT NULL) OR (inserted.[PricingRateTemplate] IS NOT NULL AND deleted.[PricingRateTemplate] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([RecurringPatternType])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'RecurringPatternType' , 								CONVERT(VARCHAR(MAX), deleted.[RecurringPatternType]) , 								CONVERT(VARCHAR(MAX), inserted.[RecurringPatternType]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[RecurringPatternType] <> deleted.[RecurringPatternType]) OR (inserted.[RecurringPatternType] IS NULL AND deleted.[RecurringPatternType] IS NOT NULL) OR (inserted.[RecurringPatternType] IS NOT NULL AND deleted.[RecurringPatternType] IS NULL))
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'Revision' , 								CONVERT(VARCHAR(MAX), deleted.[Revision]) , 								CONVERT(VARCHAR(MAX), inserted.[Revision]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[Revision] <> deleted.[Revision]) OR (inserted.[Revision] IS NULL AND deleted.[Revision] IS NOT NULL) OR (inserted.[Revision] IS NOT NULL AND deleted.[Revision] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([SMAgreementServiceID])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'SMAgreementServiceID' , 								CONVERT(VARCHAR(MAX), deleted.[SMAgreementServiceID]) , 								CONVERT(VARCHAR(MAX), inserted.[SMAgreementServiceID]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[SMAgreementServiceID] <> deleted.[SMAgreementServiceID]) OR (inserted.[SMAgreementServiceID] IS NULL AND deleted.[SMAgreementServiceID] IS NOT NULL) OR (inserted.[SMAgreementServiceID] IS NOT NULL AND deleted.[SMAgreementServiceID] IS NULL))
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'SMCo' , 								CONVERT(VARCHAR(MAX), deleted.[SMCo]) , 								CONVERT(VARCHAR(MAX), inserted.[SMCo]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[SMCo] <> deleted.[SMCo]) OR (inserted.[SMCo] IS NULL AND deleted.[SMCo] IS NOT NULL) OR (inserted.[SMCo] IS NOT NULL AND deleted.[SMCo] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([ScheOptContactBeforeScheduling])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'ScheOptContactBeforeScheduling' , 								CONVERT(VARCHAR(MAX), deleted.[ScheOptContactBeforeScheduling]) , 								CONVERT(VARCHAR(MAX), inserted.[ScheOptContactBeforeScheduling]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[ScheOptContactBeforeScheduling] <> deleted.[ScheOptContactBeforeScheduling]) OR (inserted.[ScheOptContactBeforeScheduling] IS NULL AND deleted.[ScheOptContactBeforeScheduling] IS NOT NULL) OR (inserted.[ScheOptContactBeforeScheduling] IS NOT NULL AND deleted.[ScheOptContactBeforeScheduling] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([ScheOptDays])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'ScheOptDays' , 								CONVERT(VARCHAR(MAX), deleted.[ScheOptDays]) , 								CONVERT(VARCHAR(MAX), inserted.[ScheOptDays]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[ScheOptDays] <> deleted.[ScheOptDays]) OR (inserted.[ScheOptDays] IS NULL AND deleted.[ScheOptDays] IS NOT NULL) OR (inserted.[ScheOptDays] IS NOT NULL AND deleted.[ScheOptDays] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([ScheOptDueType])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'ScheOptDueType' , 								CONVERT(VARCHAR(MAX), deleted.[ScheOptDueType]) , 								CONVERT(VARCHAR(MAX), inserted.[ScheOptDueType]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[ScheOptDueType] <> deleted.[ScheOptDueType]) OR (inserted.[ScheOptDueType] IS NULL AND deleted.[ScheOptDueType] IS NOT NULL) OR (inserted.[ScheOptDueType] IS NOT NULL AND deleted.[ScheOptDueType] IS NULL))
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'Service' , 								CONVERT(VARCHAR(MAX), deleted.[Service]) , 								CONVERT(VARCHAR(MAX), inserted.[Service]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[Service] <> deleted.[Service]) OR (inserted.[Service] IS NULL AND deleted.[Service] IS NOT NULL) OR (inserted.[Service] IS NOT NULL AND deleted.[Service] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([ServiceCenter])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'ServiceCenter' , 								CONVERT(VARCHAR(MAX), deleted.[ServiceCenter]) , 								CONVERT(VARCHAR(MAX), inserted.[ServiceCenter]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[ServiceCenter] <> deleted.[ServiceCenter]) OR (inserted.[ServiceCenter] IS NULL AND deleted.[ServiceCenter] IS NOT NULL) OR (inserted.[ServiceCenter] IS NOT NULL AND deleted.[ServiceCenter] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([ServiceSite])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'ServiceSite' , 								CONVERT(VARCHAR(MAX), deleted.[ServiceSite]) , 								CONVERT(VARCHAR(MAX), inserted.[ServiceSite]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[ServiceSite] <> deleted.[ServiceSite]) OR (inserted.[ServiceSite] IS NULL AND deleted.[ServiceSite] IS NOT NULL) OR (inserted.[ServiceSite] IS NOT NULL AND deleted.[ServiceSite] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([TaxSource])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'TaxSource' , 								CONVERT(VARCHAR(MAX), deleted.[TaxSource]) , 								CONVERT(VARCHAR(MAX), inserted.[TaxSource]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[TaxSource] <> deleted.[TaxSource]) OR (inserted.[TaxSource] IS NULL AND deleted.[TaxSource] IS NOT NULL) OR (inserted.[TaxSource] IS NOT NULL AND deleted.[TaxSource] IS NULL))
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'UniqueAttchID' , 								CONVERT(VARCHAR(MAX), deleted.[UniqueAttchID]) , 								CONVERT(VARCHAR(MAX), inserted.[UniqueAttchID]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[UniqueAttchID] <> deleted.[UniqueAttchID]) OR (inserted.[UniqueAttchID] IS NULL AND deleted.[UniqueAttchID] IS NOT NULL) OR (inserted.[UniqueAttchID] IS NOT NULL AND deleted.[UniqueAttchID] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([WasCopied])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'WasCopied' , 								CONVERT(VARCHAR(MAX), deleted.[WasCopied]) , 								CONVERT(VARCHAR(MAX), inserted.[WasCopied]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[WasCopied] <> deleted.[WasCopied]) OR (inserted.[WasCopied] IS NULL AND deleted.[WasCopied] IS NOT NULL) OR (inserted.[WasCopied] IS NOT NULL AND deleted.[WasCopied] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([WeeklyEveryFri])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'WeeklyEveryFri' , 								CONVERT(VARCHAR(MAX), deleted.[WeeklyEveryFri]) , 								CONVERT(VARCHAR(MAX), inserted.[WeeklyEveryFri]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[WeeklyEveryFri] <> deleted.[WeeklyEveryFri]) OR (inserted.[WeeklyEveryFri] IS NULL AND deleted.[WeeklyEveryFri] IS NOT NULL) OR (inserted.[WeeklyEveryFri] IS NOT NULL AND deleted.[WeeklyEveryFri] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([WeeklyEveryMon])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'WeeklyEveryMon' , 								CONVERT(VARCHAR(MAX), deleted.[WeeklyEveryMon]) , 								CONVERT(VARCHAR(MAX), inserted.[WeeklyEveryMon]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[WeeklyEveryMon] <> deleted.[WeeklyEveryMon]) OR (inserted.[WeeklyEveryMon] IS NULL AND deleted.[WeeklyEveryMon] IS NOT NULL) OR (inserted.[WeeklyEveryMon] IS NOT NULL AND deleted.[WeeklyEveryMon] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([WeeklyEverySat])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'WeeklyEverySat' , 								CONVERT(VARCHAR(MAX), deleted.[WeeklyEverySat]) , 								CONVERT(VARCHAR(MAX), inserted.[WeeklyEverySat]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[WeeklyEverySat] <> deleted.[WeeklyEverySat]) OR (inserted.[WeeklyEverySat] IS NULL AND deleted.[WeeklyEverySat] IS NOT NULL) OR (inserted.[WeeklyEverySat] IS NOT NULL AND deleted.[WeeklyEverySat] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([WeeklyEverySun])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'WeeklyEverySun' , 								CONVERT(VARCHAR(MAX), deleted.[WeeklyEverySun]) , 								CONVERT(VARCHAR(MAX), inserted.[WeeklyEverySun]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[WeeklyEverySun] <> deleted.[WeeklyEverySun]) OR (inserted.[WeeklyEverySun] IS NULL AND deleted.[WeeklyEverySun] IS NOT NULL) OR (inserted.[WeeklyEverySun] IS NOT NULL AND deleted.[WeeklyEverySun] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([WeeklyEveryThu])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'WeeklyEveryThu' , 								CONVERT(VARCHAR(MAX), deleted.[WeeklyEveryThu]) , 								CONVERT(VARCHAR(MAX), inserted.[WeeklyEveryThu]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[WeeklyEveryThu] <> deleted.[WeeklyEveryThu]) OR (inserted.[WeeklyEveryThu] IS NULL AND deleted.[WeeklyEveryThu] IS NOT NULL) OR (inserted.[WeeklyEveryThu] IS NOT NULL AND deleted.[WeeklyEveryThu] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([WeeklyEveryTue])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'WeeklyEveryTue' , 								CONVERT(VARCHAR(MAX), deleted.[WeeklyEveryTue]) , 								CONVERT(VARCHAR(MAX), inserted.[WeeklyEveryTue]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[WeeklyEveryTue] <> deleted.[WeeklyEveryTue]) OR (inserted.[WeeklyEveryTue] IS NULL AND deleted.[WeeklyEveryTue] IS NOT NULL) OR (inserted.[WeeklyEveryTue] IS NOT NULL AND deleted.[WeeklyEveryTue] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([WeeklyEveryWed])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'WeeklyEveryWed' , 								CONVERT(VARCHAR(MAX), deleted.[WeeklyEveryWed]) , 								CONVERT(VARCHAR(MAX), inserted.[WeeklyEveryWed]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[WeeklyEveryWed] <> deleted.[WeeklyEveryWed]) OR (inserted.[WeeklyEveryWed] IS NULL AND deleted.[WeeklyEveryWed] IS NOT NULL) OR (inserted.[WeeklyEveryWed] IS NOT NULL AND deleted.[WeeklyEveryWed] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([WeeklyEveryWeeks])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'WeeklyEveryWeeks' , 								CONVERT(VARCHAR(MAX), deleted.[WeeklyEveryWeeks]) , 								CONVERT(VARCHAR(MAX), inserted.[WeeklyEveryWeeks]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[WeeklyEveryWeeks] <> deleted.[WeeklyEveryWeeks]) OR (inserted.[WeeklyEveryWeeks] IS NULL AND deleted.[WeeklyEveryWeeks] IS NOT NULL) OR (inserted.[WeeklyEveryWeeks] IS NOT NULL AND deleted.[WeeklyEveryWeeks] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([YearlyEveryDateMonth])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'YearlyEveryDateMonth' , 								CONVERT(VARCHAR(MAX), deleted.[YearlyEveryDateMonth]) , 								CONVERT(VARCHAR(MAX), inserted.[YearlyEveryDateMonth]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[YearlyEveryDateMonth] <> deleted.[YearlyEveryDateMonth]) OR (inserted.[YearlyEveryDateMonth] IS NULL AND deleted.[YearlyEveryDateMonth] IS NOT NULL) OR (inserted.[YearlyEveryDateMonth] IS NOT NULL AND deleted.[YearlyEveryDateMonth] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([YearlyEveryDateMonthDay])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'YearlyEveryDateMonthDay' , 								CONVERT(VARCHAR(MAX), deleted.[YearlyEveryDateMonthDay]) , 								CONVERT(VARCHAR(MAX), inserted.[YearlyEveryDateMonthDay]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[YearlyEveryDateMonthDay] <> deleted.[YearlyEveryDateMonthDay]) OR (inserted.[YearlyEveryDateMonthDay] IS NULL AND deleted.[YearlyEveryDateMonthDay] IS NOT NULL) OR (inserted.[YearlyEveryDateMonthDay] IS NOT NULL AND deleted.[YearlyEveryDateMonthDay] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([YearlyEveryDayDay])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'YearlyEveryDayDay' , 								CONVERT(VARCHAR(MAX), deleted.[YearlyEveryDayDay]) , 								CONVERT(VARCHAR(MAX), inserted.[YearlyEveryDayDay]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[YearlyEveryDayDay] <> deleted.[YearlyEveryDayDay]) OR (inserted.[YearlyEveryDayDay] IS NULL AND deleted.[YearlyEveryDayDay] IS NOT NULL) OR (inserted.[YearlyEveryDayDay] IS NOT NULL AND deleted.[YearlyEveryDayDay] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([YearlyEveryDayMonth])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'YearlyEveryDayMonth' , 								CONVERT(VARCHAR(MAX), deleted.[YearlyEveryDayMonth]) , 								CONVERT(VARCHAR(MAX), inserted.[YearlyEveryDayMonth]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[YearlyEveryDayMonth] <> deleted.[YearlyEveryDayMonth]) OR (inserted.[YearlyEveryDayMonth] IS NULL AND deleted.[YearlyEveryDayMonth] IS NOT NULL) OR (inserted.[YearlyEveryDayMonth] IS NOT NULL AND deleted.[YearlyEveryDayMonth] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([YearlyEveryDayOrdinal])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'YearlyEveryDayOrdinal' , 								CONVERT(VARCHAR(MAX), deleted.[YearlyEveryDayOrdinal]) , 								CONVERT(VARCHAR(MAX), inserted.[YearlyEveryDayOrdinal]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[YearlyEveryDayOrdinal] <> deleted.[YearlyEveryDayOrdinal]) OR (inserted.[YearlyEveryDayOrdinal] IS NULL AND deleted.[YearlyEveryDayOrdinal] IS NOT NULL) OR (inserted.[YearlyEveryDayOrdinal] IS NOT NULL AND deleted.[YearlyEveryDayOrdinal] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([YearlyEveryYear])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'YearlyEveryYear' , 								CONVERT(VARCHAR(MAX), deleted.[YearlyEveryYear]) , 								CONVERT(VARCHAR(MAX), inserted.[YearlyEveryYear]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[YearlyEveryYear] <> deleted.[YearlyEveryYear]) OR (inserted.[YearlyEveryYear] IS NULL AND deleted.[YearlyEveryYear] IS NOT NULL) OR (inserted.[YearlyEveryYear] IS NOT NULL AND deleted.[YearlyEveryYear] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 

							IF UPDATE([YearlyType])
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
								
								SELECT 							'vSMAgreementService' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'YearlyType' , 								CONVERT(VARCHAR(MAX), deleted.[YearlyType]) , 								CONVERT(VARCHAR(MAX), inserted.[YearlyType]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMAgreementServiceID] = deleted.[SMAgreementServiceID] 
									AND ((inserted.[YearlyType] <> deleted.[YearlyType]) OR (inserted.[YearlyType] IS NULL AND deleted.[YearlyType] IS NOT NULL) OR (inserted.[YearlyType] IS NOT NULL AND deleted.[YearlyType] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 15

							END 



 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMAgreementService_Audit_Update] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMAgreementService_Audit_Update]', 'last', 'update', null
GO
ALTER TABLE [dbo].[vSMAgreementService] WITH NOCHECK ADD CONSTRAINT [CK_vSMAgreementService_DailyPatternRequired] CHECK ((case when [RecurringPatternType]='D' then checksum((1),[dbo].[vfIsEqual]([DailyType],(1))) else checksum((0),(0)) end=checksum(~[dbo].[vfEqualsNull]([DailyType]),~[dbo].[vfEqualsNull]([DailyEveryDays]))))
GO
ALTER TABLE [dbo].[vSMAgreementService] WITH NOCHECK ADD CONSTRAINT [CK_vSMAgreementService_MonthlyPatterRequired] CHECK ((case when [RecurringPatternType]='M' then checksum((1),[dbo].[vfIsEqual]([MonthlyType],(1)),[dbo].[vfIsEqual]([MonthlyType],(1)),[dbo].[vfIsEqual]([MonthlyType],(2)),[dbo].[vfIsEqual]([MonthlyType],(2)),[dbo].[vfIsEqual]([MonthlyType],(2)),[dbo].[vfIsEqual]([MonthlyType],(3)),[dbo].[vfIsEqual]([MonthlyType],(3)),[dbo].[vfIsEqual]([MonthlyType],(3)),[dbo].[vfIsEqual]([MonthlyType],(3)),[dbo].[vfIsEqual]([MonthlyType],(3)),[dbo].[vfIsEqual]([MonthlyType],(3)),[dbo].[vfIsEqual]([MonthlyType],(3)),[dbo].[vfIsEqual]([MonthlyType],(3)),[dbo].[vfIsEqual]([MonthlyType],(3)),[dbo].[vfIsEqual]([MonthlyType],(3)),[dbo].[vfIsEqual]([MonthlyType],(3)),[dbo].[vfIsEqual]([MonthlyType],(3)),[dbo].[vfIsEqual]([MonthlyType],(3)),[dbo].[vfIsEqual]([MonthlyType],(3))) else checksum((0),(0),(0),(0),(0),(0),(0),(0),(0),(0),(0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) end=checksum(~[dbo].[vfEqualsNull]([MonthlyType]),~[dbo].[vfEqualsNull]([MonthlyDay]),~[dbo].[vfEqualsNull]([MonthlyDayEveryMonths]),~[dbo].[vfEqualsNull]([MonthlyEveryOrdinal]),~[dbo].[vfEqualsNull]([MonthlyEveryDay]),~[dbo].[vfEqualsNull]([MonthlyEveryMonths]),~[dbo].[vfEqualsNull]([MonthlySelectOrdinal]),~[dbo].[vfEqualsNull]([MonthlySelectDay]),~[dbo].[vfEqualsNull]([MonthlyJan]),~[dbo].[vfEqualsNull]([MonthlyFeb]),~[dbo].[vfEqualsNull]([MonthlyMar]),~[dbo].[vfEqualsNull]([MonthlyApr]),~[dbo].[vfEqualsNull]([MonthlyMay]),~[dbo].[vfEqualsNull]([MonthlyJun]),~[dbo].[vfEqualsNull]([MonthlyJul]),~[dbo].[vfEqualsNull]([MonthlyAug]),~[dbo].[vfEqualsNull]([MonthlySep]),~[dbo].[vfEqualsNull]([MonthlyOct]),~[dbo].[vfEqualsNull]([MonthlyNov]),~[dbo].[vfEqualsNull]([MonthlyDec]))))
GO
ALTER TABLE [dbo].[vSMAgreementService] WITH NOCHECK ADD CONSTRAINT [CK_vSMAgreementService_Pricing] CHECK ((([PricingMethod]='T' OR [PricingMethod]='P' OR [PricingMethod]='I') AND case [PricingMethod] when 'I' then checksum((0),(0),(0),(0)) when 'P' then checksum(~[dbo].[vfEqualsNull]([PricingFrequency]),(1),(0),(1)) when 'T' then checksum((0),~[dbo].[vfEqualsNull]([PricingPrice]),[dbo].[vfEqualsNull]([PricingPrice]),(0))  end=checksum(~[dbo].[vfEqualsNull]([PricingFrequency]),~[dbo].[vfEqualsNull]([PricingPrice]),~[dbo].[vfEqualsNull]([PricingRateTemplate]),~[dbo].[vfEqualsNull]([BilledSeparately]))))
GO
ALTER TABLE [dbo].[vSMAgreementService] WITH NOCHECK ADD CONSTRAINT [CK_vSMAgreementService_RecurringPatternType] CHECK (([RecurringPatternType]='Y' OR [RecurringPatternType]='M' OR [RecurringPatternType]='W' OR [RecurringPatternType]='D'))
GO
ALTER TABLE [dbo].[vSMAgreementService] WITH NOCHECK ADD CONSTRAINT [CK_vSMAgreementService_WeeklyPatternRequired] CHECK ((case when [RecurringPatternType]='W' then checksum((1),(1),(1),(1),(1),(1),(1),(1)) else checksum((0),(0),(0),(0),(0),(0),(0),(0)) end=checksum(~[dbo].[vfEqualsNull]([WeeklyEveryWeeks]),~[dbo].[vfEqualsNull]([WeeklyEverySun]),~[dbo].[vfEqualsNull]([WeeklyEveryMon]),~[dbo].[vfEqualsNull]([WeeklyEveryTue]),~[dbo].[vfEqualsNull]([WeeklyEveryWed]),~[dbo].[vfEqualsNull]([WeeklyEveryThu]),~[dbo].[vfEqualsNull]([WeeklyEveryFri]),~[dbo].[vfEqualsNull]([WeeklyEverySat]))))
GO
ALTER TABLE [dbo].[vSMAgreementService] WITH NOCHECK ADD CONSTRAINT [CK_vSMAgreementService_YearlyPatternRequired] CHECK ((case when [RecurringPatternType]='Y' then checksum((1),(1),[dbo].[vfIsEqual]([YearlyType],(1)),[dbo].[vfIsEqual]([YearlyType],(1)),[dbo].[vfIsEqual]([YearlyType],(2)),[dbo].[vfIsEqual]([YearlyType],(2)),[dbo].[vfIsEqual]([YearlyType],(2))) else checksum((0),(0),(0),(0),(0),(0),(0)) end=checksum(~[dbo].[vfEqualsNull]([YearlyType]),~[dbo].[vfEqualsNull]([YearlyEveryYear]),~[dbo].[vfEqualsNull]([YearlyEveryDateMonth]),~[dbo].[vfEqualsNull]([YearlyEveryDateMonthDay]),~[dbo].[vfEqualsNull]([YearlyEveryDayOrdinal]),~[dbo].[vfEqualsNull]([YearlyEveryDayDay]),~[dbo].[vfEqualsNull]([YearlyEveryDayMonth]))))
GO
ALTER TABLE [dbo].[vSMAgreementService] ADD CONSTRAINT [PK_vSMAgreementService] PRIMARY KEY CLUSTERED  ([SMAgreementServiceID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMAgreementService] ADD CONSTRAINT [IX_vSMAgreementService] UNIQUE NONCLUSTERED  ([SMCo], [Agreement], [Revision], [Service]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMAgreementService] WITH NOCHECK ADD CONSTRAINT [FK_vSMAgreementService_vSMAgreement] FOREIGN KEY ([SMCo], [Agreement], [Revision]) REFERENCES [dbo].[vSMAgreement] ([SMCo], [Agreement], [Revision])
GO
ALTER TABLE [dbo].[vSMAgreementService] WITH NOCHECK ADD CONSTRAINT [FK_vSMAgreementService_vSMCallType] FOREIGN KEY ([SMCo], [CallType]) REFERENCES [dbo].[vSMCallType] ([SMCo], [CallType])
GO
ALTER TABLE [dbo].[vSMAgreementService] WITH NOCHECK ADD CONSTRAINT [FK_vSMAgreementService_vSMRateTemplate] FOREIGN KEY ([SMCo], [PricingRateTemplate]) REFERENCES [dbo].[vSMRateTemplate] ([SMCo], [RateTemplate])
GO
ALTER TABLE [dbo].[vSMAgreementService] WITH NOCHECK ADD CONSTRAINT [FK_vSMAgreementService_vSMServiceCenter] FOREIGN KEY ([SMCo], [ServiceCenter]) REFERENCES [dbo].[vSMServiceCenter] ([SMCo], [ServiceCenter])
GO
ALTER TABLE [dbo].[vSMAgreementService] WITH NOCHECK ADD CONSTRAINT [FK_vSMAgreementService_vSMDivision] FOREIGN KEY ([SMCo], [ServiceCenter], [Division]) REFERENCES [dbo].[vSMDivision] ([SMCo], [ServiceCenter], [Division])
GO
ALTER TABLE [dbo].[vSMAgreementService] WITH NOCHECK ADD CONSTRAINT [FK_vSMAgreementService_vSMServiceSite] FOREIGN KEY ([SMCo], [ServiceSite]) REFERENCES [dbo].[vSMServiceSite] ([SMCo], [ServiceSite])
GO
ALTER TABLE [dbo].[vSMAgreementService] NOCHECK CONSTRAINT [FK_vSMAgreementService_vSMAgreement]
GO
ALTER TABLE [dbo].[vSMAgreementService] NOCHECK CONSTRAINT [FK_vSMAgreementService_vSMCallType]
GO
ALTER TABLE [dbo].[vSMAgreementService] NOCHECK CONSTRAINT [FK_vSMAgreementService_vSMRateTemplate]
GO
ALTER TABLE [dbo].[vSMAgreementService] NOCHECK CONSTRAINT [FK_vSMAgreementService_vSMServiceCenter]
GO
ALTER TABLE [dbo].[vSMAgreementService] NOCHECK CONSTRAINT [FK_vSMAgreementService_vSMDivision]
GO
ALTER TABLE [dbo].[vSMAgreementService] NOCHECK CONSTRAINT [FK_vSMAgreementService_vSMServiceSite]
GO
