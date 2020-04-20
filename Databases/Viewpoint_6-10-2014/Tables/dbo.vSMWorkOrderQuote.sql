CREATE TABLE [dbo].[vSMWorkOrderQuote]
(
[SMWorkOrderQuoteID] [int] NOT NULL IDENTITY(1, 1),
[SMWorkOrderID] [int] NULL,
[SMCo] [dbo].[bCompany] NOT NULL,
[WorkOrderQuote] [varchar] (15) COLLATE Latin1_General_BIN NOT NULL,
[Description] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[EnteredBy] [dbo].[bVPUserName] NULL,
[EnteredDate] [datetime] NULL,
[PRCo] [dbo].[bCompany] NULL,
[SalesPerson] [dbo].[bEmployee] NULL,
[RequestedBy] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[RequestedPhone] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[RequestedDate] [datetime] NULL,
[RequestedTime] [datetime] NULL,
[CustGroup] [dbo].[bGroup] NULL,
[Customer] [dbo].[bCustomer] NULL,
[CustomerName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[CustomerAddress1] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[CustomerAddress2] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[CustomerCity] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[CustomerState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[CustomerZip] [dbo].[bZip] NULL,
[CustomerCountry] [char] (2) COLLATE Latin1_General_BIN NULL,
[CustomerContactName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[CustomerContactPhone] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[ServiceCenter] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[ServiceSite] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[ServiceSiteDescription] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ServiceSiteAddress1] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ServiceSiteAddress2] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ServiceSiteCity] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ServiceSiteState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[ServiceSiteZip] [dbo].[bZip] NULL,
[ServiceSiteCountry] [char] (2) COLLATE Latin1_General_BIN NULL,
[DateCanceled] [datetime] NULL,
[DateApproved] [datetime] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Scott Alvey
-- Create date: 3/19/12
-- Description:	Prevent Update, Delete to an approved WO Quote
--
-- Modified:	3/29/12 - LDG Dropped and renamed triggers, also allows you to save to Attachments and Notes.
-- =============================================
CREATE TRIGGER [dbo].[vtSMWorkOrderQuoteiud]
   ON  [dbo].[vSMWorkOrderQuote]
   AFTER INSERT, UPDATE, DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF EXISTS
	(
		SELECT 1
        FROM dbo.vfColumnsUpdated(COLUMNS_UPDATED(), 'vSMWorkOrderQuote')
        WHERE ColumnsUpdated NOT IN ('Notes','UniqueAttchID','DateApproved') --Add columns here that are allowed to be changed
    )
	AND
	EXISTS
	( 
		SELECT 1
		FROM deleted d
		LEFT OUTER JOIN inserted i ON
			d.SMCo = i.SMCo and d.WorkOrderQuote = i.WorkOrderQuote
		WHERE d.DateApproved IS NOT NULL
	)
	BEGIN
		RAISERROR(N'Changes are not allowed for approved work order quotes.', 11, -1)
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
-- Author:		Lane Gresham
-- Create date: 4/18/13
-- Description:	Updates made to Tasks when Service Site is changed.
--
-- =============================================
CREATE TRIGGER [dbo].[vtSMWorkOrderQuoteServiceSiteUpdated]
   ON  [dbo].[vSMWorkOrderQuote]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF UPDATE(ServiceSite)
	BEGIN
		UPDATE vSMRequiredTasks 
		SET ServiceSite = inserted.ServiceSite
		FROM inserted
			INNER JOIN dbo.vSMEntity ON inserted.SMCo = vSMEntity.SMCo AND inserted.WorkOrderQuote = vSMEntity.WorkOrderQuote
			INNER JOIN dbo.vSMRequiredTasks ON vSMEntity.SMCo = vSMRequiredTasks.SMCo AND vSMEntity.EntitySeq = vSMRequiredTasks.EntitySeq
	END
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- ============================================================================
-- Author:      Lane Gresham
-- Create date:	05/14/2013
-- Description: Checks to see if the Center or Site on the SM WorkOrder Quote
--              has been changed, and syncs all scopes for the correct tax
--              information.
-- ============================================================================
CREATE TRIGGER [dbo].[vtSMWorkOrderQuoteTaxSyncu] 
   ON  [dbo].[vSMWorkOrderQuote]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
       
	IF UPDATE(ServiceCenter) OR UPDATE(ServiceSite)
    BEGIN

		DECLARE @QuoteScopeTaxRate TABLE 
		(
			SMCo bCompany NOT NULL, 
			WorkOrderQuote varchar(15) NOT NULL, 
			WorkOrderQuoteScope int NOT NULL, 
			TaxGroup bGroup NULL, 
			TaxCode bTaxCode NULL, 
			TaxRate bRate NULL
		)

		DECLARE @rcode int, @msg varchar(60), @TodaysDate bDate, @TaxGroup bGroup, @TaxCode bTaxCode, @TaxRate bRate
		SET @TodaysDate = dbo.vfDateOnly()

		INSERT @QuoteScopeTaxRate 
		(
			SMCo, 
			WorkOrderQuote, 
			WorkOrderQuoteScope, 
			TaxGroup, 
			TaxCode
		)
		SELECT SMWorkOrderQuoteScope.SMCo, 
			SMWorkOrderQuoteScope.WorkOrderQuote, 
			SMWorkOrderQuoteScope.WorkOrderQuoteScope,
			SMServiceCenter.TaxGroup, 
			SMServiceCenter.TaxCode
		FROM inserted
			INNER JOIN SMWorkOrderQuoteScope ON inserted.SMCo = SMWorkOrderQuoteScope.SMCo
				AND inserted.WorkOrderQuote = SMWorkOrderQuoteScope.WorkOrderQuote 
			LEFT JOIN SMServiceCenter ON inserted.SMCo = SMServiceCenter.SMCo 
				AND inserted.ServiceCenter = SMServiceCenter.ServiceCenter
		WHERE SMWorkOrderQuoteScope.TaxSource = 'C'

		INSERT @QuoteScopeTaxRate 
		(
			SMCo, 
			WorkOrderQuote, 
			WorkOrderQuoteScope, 
			TaxGroup, 
			TaxCode
		)
		SELECT SMWorkOrderQuoteScope.SMCo,
			SMWorkOrderQuoteScope.WorkOrderQuote, 
			SMWorkOrderQuoteScope.WorkOrderQuoteScope, 
			SMServiceSite.TaxGroup, 
			SMServiceSite.TaxCode
		FROM inserted
			INNER JOIN SMWorkOrderQuoteScope ON inserted.SMCo = SMWorkOrderQuoteScope.SMCo
				AND inserted.WorkOrderQuote = SMWorkOrderQuoteScope.WorkOrderQuote 
			LEFT JOIN SMServiceSite ON inserted.SMCo = SMServiceSite.SMCo 
				AND inserted.ServiceSite = SMServiceSite.ServiceSite
		WHERE SMWorkOrderQuoteScope.TaxSource = 'S'

		WHILE EXISTS(SELECT 1 FROM @QuoteScopeTaxRate WHERE TaxGroup IS NOT NULL AND TaxCode IS NOT NULL AND TaxRate IS NULL)
		BEGIN

			SELECT TOP 1 @TaxGroup = TaxGroup, @TaxCode = TaxCode
			FROM @QuoteScopeTaxRate
			WHERE TaxGroup IS NOT NULL AND TaxCode IS NOT NULL AND TaxRate IS NULL

			EXEC @rcode = dbo.vspHQTaxRateGet @taxgroup = @TaxGroup, @taxcode = @TaxCode, @compdate = @TodaysDate, @taxrate = @TaxRate OUTPUT,
				@valueadd = NULL , @gstrate = NULL, 
				@crdGLAcct = NULL, @crdRetgGLAcct = NULL, @dbtGLAcct = NULL, 
				@dbtRetgGLAcct = NULL, @crdGLAcctPST = NULL, @crdRetgGLAcctPST = NULL, 
				@msg = @msg OUTPUT

			UPDATE @QuoteScopeTaxRate
			SET TaxRate = @TaxRate
			WHERE TaxGroup = @TaxGroup AND TaxCode = @TaxCode

		END

		UPDATE SMWorkOrderQuoteScope
		SET TaxType = CASE WHEN QuoteScopeTaxRate.TaxCode IS NULL THEN NULL WHEN HQCO.DefaultCountry = 'US' THEN 1 ELSE 3 END,
			TaxGroup = ISNULL(QuoteScopeTaxRate.TaxGroup, HQCO.TaxGroup),
			TaxCode = QuoteScopeTaxRate.TaxCode,
			TaxRate = QuoteScopeTaxRate.TaxRate
		FROM @QuoteScopeTaxRate QuoteScopeTaxRate
			INNER JOIN SMWorkOrderQuoteScope ON  QuoteScopeTaxRate.SMCo = SMWorkOrderQuoteScope.SMCo
				AND  QuoteScopeTaxRate.WorkOrderQuote = SMWorkOrderQuoteScope.WorkOrderQuote 
			INNER JOIN SMCO ON QuoteScopeTaxRate.SMCo = SMCO.SMCo
			INNER JOIN HQCO ON SMCO.ARCo = HQCO.HQCo
		AND  QuoteScopeTaxRate.WorkOrderQuoteScope = SMWorkOrderQuoteScope.WorkOrderQuoteScope 

	END

END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMWorkOrderQuote_Audit_Delete ON dbo.vSMWorkOrderQuote
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'CustGroup' , 
								CONVERT(VARCHAR(MAX), deleted.[CustGroup]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'Customer' , 
								CONVERT(VARCHAR(MAX), deleted.[Customer]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'CustomerAddress1' , 
								CONVERT(VARCHAR(MAX), deleted.[CustomerAddress1]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'CustomerAddress2' , 
								CONVERT(VARCHAR(MAX), deleted.[CustomerAddress2]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'CustomerCity' , 
								CONVERT(VARCHAR(MAX), deleted.[CustomerCity]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'CustomerContactName' , 
								CONVERT(VARCHAR(MAX), deleted.[CustomerContactName]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'CustomerContactPhone' , 
								CONVERT(VARCHAR(MAX), deleted.[CustomerContactPhone]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'CustomerCountry' , 
								CONVERT(VARCHAR(MAX), deleted.[CustomerCountry]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'CustomerName' , 
								CONVERT(VARCHAR(MAX), deleted.[CustomerName]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'CustomerState' , 
								CONVERT(VARCHAR(MAX), deleted.[CustomerState]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'CustomerZip' , 
								CONVERT(VARCHAR(MAX), deleted.[CustomerZip]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'DateApproved' , 
								CONVERT(VARCHAR(MAX), deleted.[DateApproved]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'DateCanceled' , 
								CONVERT(VARCHAR(MAX), deleted.[DateCanceled]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'EnteredBy' , 
								CONVERT(VARCHAR(MAX), deleted.[EnteredBy]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'EnteredDate' , 
								CONVERT(VARCHAR(MAX), deleted.[EnteredDate]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'PRCo' , 
								CONVERT(VARCHAR(MAX), deleted.[PRCo]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'RequestedBy' , 
								CONVERT(VARCHAR(MAX), deleted.[RequestedBy]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'RequestedDate' , 
								CONVERT(VARCHAR(MAX), deleted.[RequestedDate]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'RequestedPhone' , 
								CONVERT(VARCHAR(MAX), deleted.[RequestedPhone]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'RequestedTime' , 
								CONVERT(VARCHAR(MAX), deleted.[RequestedTime]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'SMCo' , 
								CONVERT(VARCHAR(MAX), deleted.[SMCo]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'SMWorkOrderID' , 
								CONVERT(VARCHAR(MAX), deleted.[SMWorkOrderID]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'SMWorkOrderQuoteID' , 
								CONVERT(VARCHAR(MAX), deleted.[SMWorkOrderQuoteID]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'SalesPerson' , 
								CONVERT(VARCHAR(MAX), deleted.[SalesPerson]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'ServiceCenter' , 
								CONVERT(VARCHAR(MAX), deleted.[ServiceCenter]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'ServiceSite' , 
								CONVERT(VARCHAR(MAX), deleted.[ServiceSite]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'ServiceSiteAddress1' , 
								CONVERT(VARCHAR(MAX), deleted.[ServiceSiteAddress1]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'ServiceSiteAddress2' , 
								CONVERT(VARCHAR(MAX), deleted.[ServiceSiteAddress2]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'ServiceSiteCity' , 
								CONVERT(VARCHAR(MAX), deleted.[ServiceSiteCity]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'ServiceSiteCountry' , 
								CONVERT(VARCHAR(MAX), deleted.[ServiceSiteCountry]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'ServiceSiteDescription' , 
								CONVERT(VARCHAR(MAX), deleted.[ServiceSiteDescription]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'ServiceSiteState' , 
								CONVERT(VARCHAR(MAX), deleted.[ServiceSiteState]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'ServiceSiteZip' , 
								CONVERT(VARCHAR(MAX), deleted.[ServiceSiteZip]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'WorkOrderQuote' , 
								CONVERT(VARCHAR(MAX), deleted.[WorkOrderQuote]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							
 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMWorkOrderQuote_Audit_Delete] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMWorkOrderQuote_Audit_Delete]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMWorkOrderQuote_Audit_Insert ON dbo.vSMWorkOrderQuote
 AFTER INSERT
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspAuditTriggersCreate

 BEGIN TRY 

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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'CustGroup' , 
								NULL , 
								[CustGroup] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Customer' , 
								NULL , 
								[Customer] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

-- log additions to the CustomerAddress1 column
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'CustomerAddress1' , 
								NULL , 
								[CustomerAddress1] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

-- log additions to the CustomerAddress2 column
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'CustomerAddress2' , 
								NULL , 
								[CustomerAddress2] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

-- log additions to the CustomerCity column
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'CustomerCity' , 
								NULL , 
								[CustomerCity] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

-- log additions to the CustomerContactName column
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'CustomerContactName' , 
								NULL , 
								[CustomerContactName] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

-- log additions to the CustomerContactPhone column
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'CustomerContactPhone' , 
								NULL , 
								[CustomerContactPhone] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

-- log additions to the CustomerCountry column
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'CustomerCountry' , 
								NULL , 
								[CustomerCountry] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

-- log additions to the CustomerName column
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'CustomerName' , 
								NULL , 
								[CustomerName] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

-- log additions to the CustomerState column
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'CustomerState' , 
								NULL , 
								[CustomerState] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

-- log additions to the CustomerZip column
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'CustomerZip' , 
								NULL , 
								[CustomerZip] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

-- log additions to the DateApproved column
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'DateApproved' , 
								NULL , 
								[DateApproved] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

-- log additions to the DateCanceled column
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'DateCanceled' , 
								NULL , 
								[DateCanceled] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

-- log additions to the EnteredBy column
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'EnteredBy' , 
								NULL , 
								[EnteredBy] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

-- log additions to the EnteredDate column
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'EnteredDate' , 
								NULL , 
								[EnteredDate] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

-- log additions to the PRCo column
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'PRCo' , 
								NULL , 
								[PRCo] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

-- log additions to the RequestedBy column
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'RequestedBy' , 
								NULL , 
								[RequestedBy] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

-- log additions to the RequestedDate column
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'RequestedDate' , 
								NULL , 
								[RequestedDate] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

-- log additions to the RequestedPhone column
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'RequestedPhone' , 
								NULL , 
								[RequestedPhone] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

-- log additions to the RequestedTime column
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'RequestedTime' , 
								NULL , 
								[RequestedTime] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'SMCo' , 
								NULL , 
								[SMCo] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

-- log additions to the SMWorkOrderID column
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'SMWorkOrderID' , 
								NULL , 
								[SMWorkOrderID] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

-- log additions to the SMWorkOrderQuoteID column
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'SMWorkOrderQuoteID' , 
								NULL , 
								[SMWorkOrderQuoteID] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

-- log additions to the SalesPerson column
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'SalesPerson' , 
								NULL , 
								[SalesPerson] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'ServiceCenter' , 
								NULL , 
								[ServiceCenter] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'ServiceSite' , 
								NULL , 
								[ServiceSite] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

-- log additions to the ServiceSiteAddress1 column
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'ServiceSiteAddress1' , 
								NULL , 
								[ServiceSiteAddress1] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

-- log additions to the ServiceSiteAddress2 column
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'ServiceSiteAddress2' , 
								NULL , 
								[ServiceSiteAddress2] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

-- log additions to the ServiceSiteCity column
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'ServiceSiteCity' , 
								NULL , 
								[ServiceSiteCity] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

-- log additions to the ServiceSiteCountry column
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'ServiceSiteCountry' , 
								NULL , 
								[ServiceSiteCountry] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

-- log additions to the ServiceSiteDescription column
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'ServiceSiteDescription' , 
								NULL , 
								[ServiceSiteDescription] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

-- log additions to the ServiceSiteState column
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'ServiceSiteState' , 
								NULL , 
								[ServiceSiteState] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

-- log additions to the ServiceSiteZip column
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'ServiceSiteZip' , 
								NULL , 
								[ServiceSiteZip] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

-- log additions to the WorkOrderQuote column
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
								'vSMWorkOrderQuote' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'WorkOrderQuote' , 
								NULL , 
								[WorkOrderQuote] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21


 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMWorkOrderQuote_Audit_Insert] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMWorkOrderQuote_Audit_Insert]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMWorkOrderQuote_Audit_Update ON dbo.vSMWorkOrderQuote
 AFTER UPDATE 
 NOT FOR REPLICATION AS 
 SET NOCOUNT ON 
 -- generated by vspAuditTriggersCreate

 BEGIN TRY 

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
								
								SELECT 							'vSMWorkOrderQuote' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'CustGroup' , 								CONVERT(VARCHAR(MAX), deleted.[CustGroup]) , 								CONVERT(VARCHAR(MAX), inserted.[CustGroup]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteID] = deleted.[SMWorkOrderQuoteID] 
									AND ((inserted.[CustGroup] <> deleted.[CustGroup]) OR (inserted.[CustGroup] IS NULL AND deleted.[CustGroup] IS NOT NULL) OR (inserted.[CustGroup] IS NOT NULL AND deleted.[CustGroup] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

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
								
								SELECT 							'vSMWorkOrderQuote' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'Customer' , 								CONVERT(VARCHAR(MAX), deleted.[Customer]) , 								CONVERT(VARCHAR(MAX), inserted.[Customer]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteID] = deleted.[SMWorkOrderQuoteID] 
									AND ((inserted.[Customer] <> deleted.[Customer]) OR (inserted.[Customer] IS NULL AND deleted.[Customer] IS NOT NULL) OR (inserted.[Customer] IS NOT NULL AND deleted.[Customer] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([CustomerAddress1])
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
								
								SELECT 							'vSMWorkOrderQuote' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'CustomerAddress1' , 								CONVERT(VARCHAR(MAX), deleted.[CustomerAddress1]) , 								CONVERT(VARCHAR(MAX), inserted.[CustomerAddress1]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteID] = deleted.[SMWorkOrderQuoteID] 
									AND ((inserted.[CustomerAddress1] <> deleted.[CustomerAddress1]) OR (inserted.[CustomerAddress1] IS NULL AND deleted.[CustomerAddress1] IS NOT NULL) OR (inserted.[CustomerAddress1] IS NOT NULL AND deleted.[CustomerAddress1] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([CustomerAddress2])
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
								
								SELECT 							'vSMWorkOrderQuote' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'CustomerAddress2' , 								CONVERT(VARCHAR(MAX), deleted.[CustomerAddress2]) , 								CONVERT(VARCHAR(MAX), inserted.[CustomerAddress2]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteID] = deleted.[SMWorkOrderQuoteID] 
									AND ((inserted.[CustomerAddress2] <> deleted.[CustomerAddress2]) OR (inserted.[CustomerAddress2] IS NULL AND deleted.[CustomerAddress2] IS NOT NULL) OR (inserted.[CustomerAddress2] IS NOT NULL AND deleted.[CustomerAddress2] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([CustomerCity])
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
								
								SELECT 							'vSMWorkOrderQuote' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'CustomerCity' , 								CONVERT(VARCHAR(MAX), deleted.[CustomerCity]) , 								CONVERT(VARCHAR(MAX), inserted.[CustomerCity]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteID] = deleted.[SMWorkOrderQuoteID] 
									AND ((inserted.[CustomerCity] <> deleted.[CustomerCity]) OR (inserted.[CustomerCity] IS NULL AND deleted.[CustomerCity] IS NOT NULL) OR (inserted.[CustomerCity] IS NOT NULL AND deleted.[CustomerCity] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([CustomerContactName])
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
								
								SELECT 							'vSMWorkOrderQuote' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'CustomerContactName' , 								CONVERT(VARCHAR(MAX), deleted.[CustomerContactName]) , 								CONVERT(VARCHAR(MAX), inserted.[CustomerContactName]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteID] = deleted.[SMWorkOrderQuoteID] 
									AND ((inserted.[CustomerContactName] <> deleted.[CustomerContactName]) OR (inserted.[CustomerContactName] IS NULL AND deleted.[CustomerContactName] IS NOT NULL) OR (inserted.[CustomerContactName] IS NOT NULL AND deleted.[CustomerContactName] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([CustomerContactPhone])
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
								
								SELECT 							'vSMWorkOrderQuote' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'CustomerContactPhone' , 								CONVERT(VARCHAR(MAX), deleted.[CustomerContactPhone]) , 								CONVERT(VARCHAR(MAX), inserted.[CustomerContactPhone]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteID] = deleted.[SMWorkOrderQuoteID] 
									AND ((inserted.[CustomerContactPhone] <> deleted.[CustomerContactPhone]) OR (inserted.[CustomerContactPhone] IS NULL AND deleted.[CustomerContactPhone] IS NOT NULL) OR (inserted.[CustomerContactPhone] IS NOT NULL AND deleted.[CustomerContactPhone] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([CustomerCountry])
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
								
								SELECT 							'vSMWorkOrderQuote' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'CustomerCountry' , 								CONVERT(VARCHAR(MAX), deleted.[CustomerCountry]) , 								CONVERT(VARCHAR(MAX), inserted.[CustomerCountry]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteID] = deleted.[SMWorkOrderQuoteID] 
									AND ((inserted.[CustomerCountry] <> deleted.[CustomerCountry]) OR (inserted.[CustomerCountry] IS NULL AND deleted.[CustomerCountry] IS NOT NULL) OR (inserted.[CustomerCountry] IS NOT NULL AND deleted.[CustomerCountry] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([CustomerName])
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
								
								SELECT 							'vSMWorkOrderQuote' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'CustomerName' , 								CONVERT(VARCHAR(MAX), deleted.[CustomerName]) , 								CONVERT(VARCHAR(MAX), inserted.[CustomerName]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteID] = deleted.[SMWorkOrderQuoteID] 
									AND ((inserted.[CustomerName] <> deleted.[CustomerName]) OR (inserted.[CustomerName] IS NULL AND deleted.[CustomerName] IS NOT NULL) OR (inserted.[CustomerName] IS NOT NULL AND deleted.[CustomerName] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([CustomerState])
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
								
								SELECT 							'vSMWorkOrderQuote' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'CustomerState' , 								CONVERT(VARCHAR(MAX), deleted.[CustomerState]) , 								CONVERT(VARCHAR(MAX), inserted.[CustomerState]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteID] = deleted.[SMWorkOrderQuoteID] 
									AND ((inserted.[CustomerState] <> deleted.[CustomerState]) OR (inserted.[CustomerState] IS NULL AND deleted.[CustomerState] IS NOT NULL) OR (inserted.[CustomerState] IS NOT NULL AND deleted.[CustomerState] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([CustomerZip])
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
								
								SELECT 							'vSMWorkOrderQuote' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'CustomerZip' , 								CONVERT(VARCHAR(MAX), deleted.[CustomerZip]) , 								CONVERT(VARCHAR(MAX), inserted.[CustomerZip]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteID] = deleted.[SMWorkOrderQuoteID] 
									AND ((inserted.[CustomerZip] <> deleted.[CustomerZip]) OR (inserted.[CustomerZip] IS NULL AND deleted.[CustomerZip] IS NOT NULL) OR (inserted.[CustomerZip] IS NOT NULL AND deleted.[CustomerZip] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([DateApproved])
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
								
								SELECT 							'vSMWorkOrderQuote' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'DateApproved' , 								CONVERT(VARCHAR(MAX), deleted.[DateApproved]) , 								CONVERT(VARCHAR(MAX), inserted.[DateApproved]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteID] = deleted.[SMWorkOrderQuoteID] 
									AND ((inserted.[DateApproved] <> deleted.[DateApproved]) OR (inserted.[DateApproved] IS NULL AND deleted.[DateApproved] IS NOT NULL) OR (inserted.[DateApproved] IS NOT NULL AND deleted.[DateApproved] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([DateCanceled])
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
								
								SELECT 							'vSMWorkOrderQuote' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'DateCanceled' , 								CONVERT(VARCHAR(MAX), deleted.[DateCanceled]) , 								CONVERT(VARCHAR(MAX), inserted.[DateCanceled]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteID] = deleted.[SMWorkOrderQuoteID] 
									AND ((inserted.[DateCanceled] <> deleted.[DateCanceled]) OR (inserted.[DateCanceled] IS NULL AND deleted.[DateCanceled] IS NOT NULL) OR (inserted.[DateCanceled] IS NOT NULL AND deleted.[DateCanceled] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([EnteredBy])
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
								
								SELECT 							'vSMWorkOrderQuote' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'EnteredBy' , 								CONVERT(VARCHAR(MAX), deleted.[EnteredBy]) , 								CONVERT(VARCHAR(MAX), inserted.[EnteredBy]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteID] = deleted.[SMWorkOrderQuoteID] 
									AND ((inserted.[EnteredBy] <> deleted.[EnteredBy]) OR (inserted.[EnteredBy] IS NULL AND deleted.[EnteredBy] IS NOT NULL) OR (inserted.[EnteredBy] IS NOT NULL AND deleted.[EnteredBy] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([EnteredDate])
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
								
								SELECT 							'vSMWorkOrderQuote' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'EnteredDate' , 								CONVERT(VARCHAR(MAX), deleted.[EnteredDate]) , 								CONVERT(VARCHAR(MAX), inserted.[EnteredDate]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteID] = deleted.[SMWorkOrderQuoteID] 
									AND ((inserted.[EnteredDate] <> deleted.[EnteredDate]) OR (inserted.[EnteredDate] IS NULL AND deleted.[EnteredDate] IS NOT NULL) OR (inserted.[EnteredDate] IS NOT NULL AND deleted.[EnteredDate] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([PRCo])
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
								
								SELECT 							'vSMWorkOrderQuote' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'PRCo' , 								CONVERT(VARCHAR(MAX), deleted.[PRCo]) , 								CONVERT(VARCHAR(MAX), inserted.[PRCo]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteID] = deleted.[SMWorkOrderQuoteID] 
									AND ((inserted.[PRCo] <> deleted.[PRCo]) OR (inserted.[PRCo] IS NULL AND deleted.[PRCo] IS NOT NULL) OR (inserted.[PRCo] IS NOT NULL AND deleted.[PRCo] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([RequestedBy])
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
								
								SELECT 							'vSMWorkOrderQuote' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'RequestedBy' , 								CONVERT(VARCHAR(MAX), deleted.[RequestedBy]) , 								CONVERT(VARCHAR(MAX), inserted.[RequestedBy]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteID] = deleted.[SMWorkOrderQuoteID] 
									AND ((inserted.[RequestedBy] <> deleted.[RequestedBy]) OR (inserted.[RequestedBy] IS NULL AND deleted.[RequestedBy] IS NOT NULL) OR (inserted.[RequestedBy] IS NOT NULL AND deleted.[RequestedBy] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([RequestedDate])
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
								
								SELECT 							'vSMWorkOrderQuote' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'RequestedDate' , 								CONVERT(VARCHAR(MAX), deleted.[RequestedDate]) , 								CONVERT(VARCHAR(MAX), inserted.[RequestedDate]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteID] = deleted.[SMWorkOrderQuoteID] 
									AND ((inserted.[RequestedDate] <> deleted.[RequestedDate]) OR (inserted.[RequestedDate] IS NULL AND deleted.[RequestedDate] IS NOT NULL) OR (inserted.[RequestedDate] IS NOT NULL AND deleted.[RequestedDate] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([RequestedPhone])
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
								
								SELECT 							'vSMWorkOrderQuote' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'RequestedPhone' , 								CONVERT(VARCHAR(MAX), deleted.[RequestedPhone]) , 								CONVERT(VARCHAR(MAX), inserted.[RequestedPhone]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteID] = deleted.[SMWorkOrderQuoteID] 
									AND ((inserted.[RequestedPhone] <> deleted.[RequestedPhone]) OR (inserted.[RequestedPhone] IS NULL AND deleted.[RequestedPhone] IS NOT NULL) OR (inserted.[RequestedPhone] IS NOT NULL AND deleted.[RequestedPhone] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([RequestedTime])
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
								
								SELECT 							'vSMWorkOrderQuote' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'RequestedTime' , 								CONVERT(VARCHAR(MAX), deleted.[RequestedTime]) , 								CONVERT(VARCHAR(MAX), inserted.[RequestedTime]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteID] = deleted.[SMWorkOrderQuoteID] 
									AND ((inserted.[RequestedTime] <> deleted.[RequestedTime]) OR (inserted.[RequestedTime] IS NULL AND deleted.[RequestedTime] IS NOT NULL) OR (inserted.[RequestedTime] IS NOT NULL AND deleted.[RequestedTime] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

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
								
								SELECT 							'vSMWorkOrderQuote' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'SMCo' , 								CONVERT(VARCHAR(MAX), deleted.[SMCo]) , 								CONVERT(VARCHAR(MAX), inserted.[SMCo]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteID] = deleted.[SMWorkOrderQuoteID] 
									AND ((inserted.[SMCo] <> deleted.[SMCo]) OR (inserted.[SMCo] IS NULL AND deleted.[SMCo] IS NOT NULL) OR (inserted.[SMCo] IS NOT NULL AND deleted.[SMCo] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([SMWorkOrderID])
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
								
								SELECT 							'vSMWorkOrderQuote' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'SMWorkOrderID' , 								CONVERT(VARCHAR(MAX), deleted.[SMWorkOrderID]) , 								CONVERT(VARCHAR(MAX), inserted.[SMWorkOrderID]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteID] = deleted.[SMWorkOrderQuoteID] 
									AND ((inserted.[SMWorkOrderID] <> deleted.[SMWorkOrderID]) OR (inserted.[SMWorkOrderID] IS NULL AND deleted.[SMWorkOrderID] IS NOT NULL) OR (inserted.[SMWorkOrderID] IS NOT NULL AND deleted.[SMWorkOrderID] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([SMWorkOrderQuoteID])
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
								
								SELECT 							'vSMWorkOrderQuote' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'SMWorkOrderQuoteID' , 								CONVERT(VARCHAR(MAX), deleted.[SMWorkOrderQuoteID]) , 								CONVERT(VARCHAR(MAX), inserted.[SMWorkOrderQuoteID]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteID] = deleted.[SMWorkOrderQuoteID] 
									AND ((inserted.[SMWorkOrderQuoteID] <> deleted.[SMWorkOrderQuoteID]) OR (inserted.[SMWorkOrderQuoteID] IS NULL AND deleted.[SMWorkOrderQuoteID] IS NOT NULL) OR (inserted.[SMWorkOrderQuoteID] IS NOT NULL AND deleted.[SMWorkOrderQuoteID] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([SalesPerson])
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
								
								SELECT 							'vSMWorkOrderQuote' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'SalesPerson' , 								CONVERT(VARCHAR(MAX), deleted.[SalesPerson]) , 								CONVERT(VARCHAR(MAX), inserted.[SalesPerson]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteID] = deleted.[SMWorkOrderQuoteID] 
									AND ((inserted.[SalesPerson] <> deleted.[SalesPerson]) OR (inserted.[SalesPerson] IS NULL AND deleted.[SalesPerson] IS NOT NULL) OR (inserted.[SalesPerson] IS NOT NULL AND deleted.[SalesPerson] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

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
								
								SELECT 							'vSMWorkOrderQuote' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'ServiceCenter' , 								CONVERT(VARCHAR(MAX), deleted.[ServiceCenter]) , 								CONVERT(VARCHAR(MAX), inserted.[ServiceCenter]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteID] = deleted.[SMWorkOrderQuoteID] 
									AND ((inserted.[ServiceCenter] <> deleted.[ServiceCenter]) OR (inserted.[ServiceCenter] IS NULL AND deleted.[ServiceCenter] IS NOT NULL) OR (inserted.[ServiceCenter] IS NOT NULL AND deleted.[ServiceCenter] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

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
								
								SELECT 							'vSMWorkOrderQuote' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'ServiceSite' , 								CONVERT(VARCHAR(MAX), deleted.[ServiceSite]) , 								CONVERT(VARCHAR(MAX), inserted.[ServiceSite]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteID] = deleted.[SMWorkOrderQuoteID] 
									AND ((inserted.[ServiceSite] <> deleted.[ServiceSite]) OR (inserted.[ServiceSite] IS NULL AND deleted.[ServiceSite] IS NOT NULL) OR (inserted.[ServiceSite] IS NOT NULL AND deleted.[ServiceSite] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([ServiceSiteAddress1])
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
								
								SELECT 							'vSMWorkOrderQuote' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'ServiceSiteAddress1' , 								CONVERT(VARCHAR(MAX), deleted.[ServiceSiteAddress1]) , 								CONVERT(VARCHAR(MAX), inserted.[ServiceSiteAddress1]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteID] = deleted.[SMWorkOrderQuoteID] 
									AND ((inserted.[ServiceSiteAddress1] <> deleted.[ServiceSiteAddress1]) OR (inserted.[ServiceSiteAddress1] IS NULL AND deleted.[ServiceSiteAddress1] IS NOT NULL) OR (inserted.[ServiceSiteAddress1] IS NOT NULL AND deleted.[ServiceSiteAddress1] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([ServiceSiteAddress2])
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
								
								SELECT 							'vSMWorkOrderQuote' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'ServiceSiteAddress2' , 								CONVERT(VARCHAR(MAX), deleted.[ServiceSiteAddress2]) , 								CONVERT(VARCHAR(MAX), inserted.[ServiceSiteAddress2]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteID] = deleted.[SMWorkOrderQuoteID] 
									AND ((inserted.[ServiceSiteAddress2] <> deleted.[ServiceSiteAddress2]) OR (inserted.[ServiceSiteAddress2] IS NULL AND deleted.[ServiceSiteAddress2] IS NOT NULL) OR (inserted.[ServiceSiteAddress2] IS NOT NULL AND deleted.[ServiceSiteAddress2] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([ServiceSiteCity])
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
								
								SELECT 							'vSMWorkOrderQuote' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'ServiceSiteCity' , 								CONVERT(VARCHAR(MAX), deleted.[ServiceSiteCity]) , 								CONVERT(VARCHAR(MAX), inserted.[ServiceSiteCity]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteID] = deleted.[SMWorkOrderQuoteID] 
									AND ((inserted.[ServiceSiteCity] <> deleted.[ServiceSiteCity]) OR (inserted.[ServiceSiteCity] IS NULL AND deleted.[ServiceSiteCity] IS NOT NULL) OR (inserted.[ServiceSiteCity] IS NOT NULL AND deleted.[ServiceSiteCity] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([ServiceSiteCountry])
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
								
								SELECT 							'vSMWorkOrderQuote' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'ServiceSiteCountry' , 								CONVERT(VARCHAR(MAX), deleted.[ServiceSiteCountry]) , 								CONVERT(VARCHAR(MAX), inserted.[ServiceSiteCountry]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteID] = deleted.[SMWorkOrderQuoteID] 
									AND ((inserted.[ServiceSiteCountry] <> deleted.[ServiceSiteCountry]) OR (inserted.[ServiceSiteCountry] IS NULL AND deleted.[ServiceSiteCountry] IS NOT NULL) OR (inserted.[ServiceSiteCountry] IS NOT NULL AND deleted.[ServiceSiteCountry] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([ServiceSiteDescription])
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
								
								SELECT 							'vSMWorkOrderQuote' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'ServiceSiteDescription' , 								CONVERT(VARCHAR(MAX), deleted.[ServiceSiteDescription]) , 								CONVERT(VARCHAR(MAX), inserted.[ServiceSiteDescription]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteID] = deleted.[SMWorkOrderQuoteID] 
									AND ((inserted.[ServiceSiteDescription] <> deleted.[ServiceSiteDescription]) OR (inserted.[ServiceSiteDescription] IS NULL AND deleted.[ServiceSiteDescription] IS NOT NULL) OR (inserted.[ServiceSiteDescription] IS NOT NULL AND deleted.[ServiceSiteDescription] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([ServiceSiteState])
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
								
								SELECT 							'vSMWorkOrderQuote' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'ServiceSiteState' , 								CONVERT(VARCHAR(MAX), deleted.[ServiceSiteState]) , 								CONVERT(VARCHAR(MAX), inserted.[ServiceSiteState]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteID] = deleted.[SMWorkOrderQuoteID] 
									AND ((inserted.[ServiceSiteState] <> deleted.[ServiceSiteState]) OR (inserted.[ServiceSiteState] IS NULL AND deleted.[ServiceSiteState] IS NOT NULL) OR (inserted.[ServiceSiteState] IS NOT NULL AND deleted.[ServiceSiteState] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([ServiceSiteZip])
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
								
								SELECT 							'vSMWorkOrderQuote' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'ServiceSiteZip' , 								CONVERT(VARCHAR(MAX), deleted.[ServiceSiteZip]) , 								CONVERT(VARCHAR(MAX), inserted.[ServiceSiteZip]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteID] = deleted.[SMWorkOrderQuoteID] 
									AND ((inserted.[ServiceSiteZip] <> deleted.[ServiceSiteZip]) OR (inserted.[ServiceSiteZip] IS NULL AND deleted.[ServiceSiteZip] IS NOT NULL) OR (inserted.[ServiceSiteZip] IS NOT NULL AND deleted.[ServiceSiteZip] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([WorkOrderQuote])
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
								
								SELECT 							'vSMWorkOrderQuote' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'WorkOrderQuote' , 								CONVERT(VARCHAR(MAX), deleted.[WorkOrderQuote]) , 								CONVERT(VARCHAR(MAX), inserted.[WorkOrderQuote]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteID] = deleted.[SMWorkOrderQuoteID] 
									AND ((inserted.[WorkOrderQuote] <> deleted.[WorkOrderQuote]) OR (inserted.[WorkOrderQuote] IS NULL AND deleted.[WorkOrderQuote] IS NOT NULL) OR (inserted.[WorkOrderQuote] IS NOT NULL AND deleted.[WorkOrderQuote] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 



 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMWorkOrderQuote_Audit_Update] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMWorkOrderQuote_Audit_Update]', 'last', 'update', null
GO
ALTER TABLE [dbo].[vSMWorkOrderQuote] ADD CONSTRAINT [PK_SMWorkOrderQuote] PRIMARY KEY CLUSTERED  ([SMWorkOrderQuoteID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMWorkOrderQuote] ADD CONSTRAINT [IX_vSMWorkOrderQuote_SMCo_WorkOrderQuote] UNIQUE NONCLUSTERED  ([SMCo], [WorkOrderQuote]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMWorkOrderQuote] ADD CONSTRAINT [IX_vSMWorkOrderQuote_SMCo_WorkOrderQuote_ServiceCenter] UNIQUE NONCLUSTERED  ([SMCo], [WorkOrderQuote], [ServiceCenter]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMWorkOrderQuote] ADD CONSTRAINT [IX_vSMWorkOrderQuote_SMCo_WorkOrderQuote_ServiceSite] UNIQUE NONCLUSTERED  ([SMCo], [WorkOrderQuote], [ServiceSite]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMWorkOrderQuote] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkOrderQuote_bPREH] FOREIGN KEY ([PRCo], [SalesPerson]) REFERENCES [dbo].[bPREH] ([PRCo], [Employee])
GO
ALTER TABLE [dbo].[vSMWorkOrderQuote] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkOrderQuote_vSMCustomer] FOREIGN KEY ([SMCo], [CustGroup], [Customer]) REFERENCES [dbo].[vSMCustomer] ([SMCo], [CustGroup], [Customer])
GO
ALTER TABLE [dbo].[vSMWorkOrderQuote] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkOrderQuote_vSMServiceCenter] FOREIGN KEY ([SMCo], [ServiceCenter]) REFERENCES [dbo].[vSMServiceCenter] ([SMCo], [ServiceCenter])
GO
ALTER TABLE [dbo].[vSMWorkOrderQuote] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkOrderQuote_vSMServiceSite] FOREIGN KEY ([SMCo], [ServiceSite]) REFERENCES [dbo].[vSMServiceSite] ([SMCo], [ServiceSite])
GO
ALTER TABLE [dbo].[vSMWorkOrderQuote] NOCHECK CONSTRAINT [FK_vSMWorkOrderQuote_bPREH]
GO
ALTER TABLE [dbo].[vSMWorkOrderQuote] NOCHECK CONSTRAINT [FK_vSMWorkOrderQuote_vSMCustomer]
GO
ALTER TABLE [dbo].[vSMWorkOrderQuote] NOCHECK CONSTRAINT [FK_vSMWorkOrderQuote_vSMServiceCenter]
GO
ALTER TABLE [dbo].[vSMWorkOrderQuote] NOCHECK CONSTRAINT [FK_vSMWorkOrderQuote_vSMServiceSite]
GO
