CREATE TABLE [dbo].[vSMWorkOrderQuoteScope]
(
[SMWorkOrderQuoteScopeID] [int] NOT NULL IDENTITY(1, 1),
[WorkOrderQuote] [varchar] (15) COLLATE Latin1_General_BIN NOT NULL,
[SMCo] [dbo].[bCompany] NOT NULL,
[WorkOrderQuoteScope] [int] NOT NULL,
[WorkScope] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[Description] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[ServiceCenter] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Division] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[CallType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[CustomerPO] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Price] [dbo].[bDollar] NULL,
[NotToExceed] [dbo].[bDollar] NULL,
[PriceMethod] [char] (1) COLLATE Latin1_General_BIN NULL,
[RateTemplate] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[TaxSource] [char] (1) COLLATE Latin1_General_BIN NULL,
[TaxType] [tinyint] NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[TaxRate] [dbo].[bRate] NULL,
[LaborCostEst] [dbo].[bDollar] NULL,
[MaterialCostEst] [dbo].[bDollar] NULL,
[EquipmentCostEst] [dbo].[bDollar] NULL,
[SubcontractCostEst] [dbo].[bDollar] NULL,
[OtherCostEst] [dbo].[bDollar] NULL,
[DueStartDate] [dbo].[bDate] NULL,
[DueEndDate] [dbo].[bDate] NULL,
[DerivedEstimate] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vSMWorkOrderQuoteScope_DerivedEstimate] DEFAULT ('N'),
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
-- Description:	Prevent Insert, Update, Delete on Scopes related to an approved WO Quote
-- Modified:	3/29/12 - LDG Dropped and renamed triggers, also allows you to save to Attachments and Notes.
-- =============================================
CREATE TRIGGER [dbo].[vtSMWorkOrderQuoteScopeiud]
   ON  [dbo].[vSMWorkOrderQuoteScope]
   AFTER INSERT, UPDATE, DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF EXISTS
	(
		SELECT 1
        FROM dbo.vfColumnsUpdated(COLUMNS_UPDATED(), 'vSMWorkOrderQuoteScope')
        WHERE ColumnsUpdated NOT IN ('Notes','UniqueAttchID') --Add columns here that are allowed to be changed
    )
	AND
	EXISTS
	( 
		SELECT 1
		FROM vSMWorkOrderQuote q
			INNER JOIN
			(SELECT SMCo, WorkOrderQuote
			FROM INSERTED
			UNION
			SELECT SMCo, WorkOrderQuote
			FROM DELETED) r ON
				q.SMCo = r.SMCo
				AND q.WorkOrderQuote = r.WorkOrderQuote
		WHERE q.DateApproved IS NOT NULL
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
-- Author:		Scott Alvey
-- Create date: 05/06/2013
-- Description:	Clear Flat Pricing Split or Rate Overrides based on what Pricing Method the record is being changed to
-- =============================================
CREATE TRIGGER [dbo].[vtSMWorkOrderQuoteScopePricingu] 
   ON  [dbo].[vSMWorkOrderQuoteScope]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE 
		@NewPMethod char(1), 
		@OldPMethod char(1);

    IF UPDATE(PriceMethod)
    BEGIN
		SELECT 
			@NewPMethod = I.PriceMethod,
			@OldPMethod = D.PriceMethod
		FROM INSERTED I 
		INNER JOIN DELETED D ON
			I.SMCo = D.SMCo 
			and I.WorkOrderQuote = D.WorkOrderQuote
			and I.WorkOrderQuoteScope = D.WorkOrderQuoteScope

		IF @NewPMethod = 'F' and @OldPMethod = 'T'
		BEGIN
			BEGIN TRY
				DELETE dbo.vSMRateOverrideBaseRate 
				FROM INSERTED I 
				INNER JOIN SMEntity ON
					SMEntity.SMCo = I.SMCo
					and SMEntity.WorkOrderQuote = I.WorkOrderQuote
					and SMEntity.WorkOrderQuoteScope = I.WorkOrderQuoteScope
				INNER JOIN dbo.vSMRateOverrideBaseRate ON
					dbo.vSMRateOverrideBaseRate.SMCo = SMEntity.SMCo 
					and dbo.vSMRateOverrideBaseRate.EntitySeq = SMEntity.EntitySeq 
			END TRY

			BEGIN CATCH 
				RAISERROR('Table SMRateOverrideBaseRate could not be cleared.', 11, -1)
				ROLLBACK TRANSACTION
			END CATCH 

			BEGIN TRY
				DELETE dbo.vSMRateOverrideEquipment 
				FROM INSERTED I  
				INNER JOIN SMEntity ON
					SMEntity.SMCo = I.SMCo
					and SMEntity.WorkOrderQuote = I.WorkOrderQuote
					and SMEntity.WorkOrderQuoteScope = I.WorkOrderQuoteScope
				INNER JOIN dbo.vSMRateOverrideEquipment ON
					dbo.vSMRateOverrideEquipment.SMCo = SMEntity.SMCo 
					and dbo.vSMRateOverrideEquipment.EntitySeq = SMEntity.EntitySeq 
			END TRY

			BEGIN CATCH 
				RAISERROR('Table SMRateOverrideEquipment could not be cleared.', 11, -1)
				ROLLBACK TRANSACTION
			END CATCH

			BEGIN TRY
				DELETE dbo.vSMRateOverrideLabor 
				FROM INSERTED I  
				INNER JOIN SMEntity ON
					SMEntity.SMCo = I.SMCo
					and SMEntity.WorkOrderQuote = I.WorkOrderQuote
					and SMEntity.WorkOrderQuoteScope = I.WorkOrderQuoteScope
				INNER JOIN dbo.vSMRateOverrideLabor ON
					dbo.vSMRateOverrideLabor.SMCo = SMEntity.SMCo 
					and dbo.vSMRateOverrideLabor.EntitySeq = SMEntity.EntitySeq 
			END TRY

			BEGIN CATCH 
				RAISERROR('Table SMRateOverrideLabor could not be cleared.', 11, -1)
				ROLLBACK TRANSACTION
			END CATCH

			BEGIN TRY
				DELETE dbo.vSMRateOverrideMaterial 
				FROM INSERTED I  
				INNER JOIN SMEntity ON
					SMEntity.SMCo = I.SMCo
					and SMEntity.WorkOrderQuote = I.WorkOrderQuote
					and SMEntity.WorkOrderQuoteScope = I.WorkOrderQuoteScope
				INNER JOIN dbo.vSMRateOverrideMaterial ON
					dbo.vSMRateOverrideMaterial.SMCo = SMEntity.SMCo 
					and dbo.vSMRateOverrideMaterial.EntitySeq = SMEntity.EntitySeq 
			END TRY

			BEGIN CATCH 
				RAISERROR('Table SMRateOverrideMaterial could not be cleared.', 11, -1)
				ROLLBACK TRANSACTION
			END CATCH

			BEGIN TRY
				DELETE dbo.vSMRateOverrideMatlBP 
				FROM INSERTED I  
				INNER JOIN SMEntity ON
					SMEntity.SMCo = I.SMCo
					and SMEntity.WorkOrderQuote = I.WorkOrderQuote
					and SMEntity.WorkOrderQuoteScope = I.WorkOrderQuoteScope
				INNER JOIN dbo.vSMRateOverrideMatlBP ON
					dbo.vSMRateOverrideMatlBP.SMCo = SMEntity.SMCo 
					and dbo.vSMRateOverrideMatlBP.EntitySeq = SMEntity.EntitySeq 
			END TRY

			BEGIN CATCH 
				RAISERROR('Table SMRateOverrideMatlBP could not be cleared.', 11, -1)
				ROLLBACK TRANSACTION
			END CATCH

			BEGIN TRY
				DELETE dbo.vSMRateOverrideStandardItem 
				FROM INSERTED I  
				INNER JOIN SMEntity ON
					SMEntity.SMCo = I.SMCo
					and SMEntity.WorkOrderQuote = I.WorkOrderQuote
					and SMEntity.WorkOrderQuoteScope = I.WorkOrderQuoteScope
				INNER JOIN dbo.vSMRateOverrideStandardItem ON
					dbo.vSMRateOverrideStandardItem.SMCo = SMEntity.SMCo 
					and dbo.vSMRateOverrideStandardItem.EntitySeq = SMEntity.EntitySeq 
			END TRY

			BEGIN CATCH 
				RAISERROR('Table SMRateOverrideStandardItem could not be cleared.', 11, -1)
				ROLLBACK TRANSACTION
			END CATCH
		END

		IF @NewPMethod = 'T' and @OldPMethod = 'F'
		BEGIN
			BEGIN TRY
				DELETE dbo.vSMFlatPriceRevenueSplit
				FROM INSERTED I  
				INNER JOIN SMEntity ON
					SMEntity.SMCo = I.SMCo
					and SMEntity.WorkOrderQuote = I.WorkOrderQuote
					and SMEntity.WorkOrderQuoteScope = I.WorkOrderQuoteScope
				INNER JOIN dbo.vSMFlatPriceRevenueSplit ON
					dbo.vSMFlatPriceRevenueSplit.SMCo = SMEntity.SMCo 
					and dbo.vSMFlatPriceRevenueSplit.EntitySeq = SMEntity.EntitySeq
			END TRY

			BEGIN CATCH 
				RAISERROR('Table SMFlatPriceRevenueSplit could not be cleared.', 11, -1)
				ROLLBACK TRANSACTION
			END CATCH
		END
    END
END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMWorkOrderQuoteScope_Audit_Delete ON dbo.vSMWorkOrderQuoteScope
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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'CallType' , 
								CONVERT(VARCHAR(MAX), deleted.[CallType]) , 								NULL , 
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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'CustomerPO' , 
								CONVERT(VARCHAR(MAX), deleted.[CustomerPO]) , 								NULL , 
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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'DerivedEstimate' , 
								CONVERT(VARCHAR(MAX), deleted.[DerivedEstimate]) , 								NULL , 
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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'Division' , 
								CONVERT(VARCHAR(MAX), deleted.[Division]) , 								NULL , 
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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'DueEndDate' , 
								CONVERT(VARCHAR(MAX), deleted.[DueEndDate]) , 								NULL , 
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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'DueStartDate' , 
								CONVERT(VARCHAR(MAX), deleted.[DueStartDate]) , 								NULL , 
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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'EquipmentCostEst' , 
								CONVERT(VARCHAR(MAX), deleted.[EquipmentCostEst]) , 								NULL , 
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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'LaborCostEst' , 
								CONVERT(VARCHAR(MAX), deleted.[LaborCostEst]) , 								NULL , 
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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'MaterialCostEst' , 
								CONVERT(VARCHAR(MAX), deleted.[MaterialCostEst]) , 								NULL , 
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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'NotToExceed' , 
								CONVERT(VARCHAR(MAX), deleted.[NotToExceed]) , 								NULL , 
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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'OtherCostEst' , 
								CONVERT(VARCHAR(MAX), deleted.[OtherCostEst]) , 								NULL , 
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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'Price' , 
								CONVERT(VARCHAR(MAX), deleted.[Price]) , 								NULL , 
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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'PriceMethod' , 
								CONVERT(VARCHAR(MAX), deleted.[PriceMethod]) , 								NULL , 
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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'RateTemplate' , 
								CONVERT(VARCHAR(MAX), deleted.[RateTemplate]) , 								NULL , 
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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'SubcontractCostEst' , 
								CONVERT(VARCHAR(MAX), deleted.[SubcontractCostEst]) , 								NULL , 
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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'TaxCode' , 
								CONVERT(VARCHAR(MAX), deleted.[TaxCode]) , 								NULL , 
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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'TaxGroup' , 
								CONVERT(VARCHAR(MAX), deleted.[TaxGroup]) , 								NULL , 
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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'TaxRate' , 
								CONVERT(VARCHAR(MAX), deleted.[TaxRate]) , 								NULL , 
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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'TaxSource' , 
								CONVERT(VARCHAR(MAX), deleted.[TaxSource]) , 								NULL , 
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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'TaxType' , 
								CONVERT(VARCHAR(MAX), deleted.[TaxType]) , 								NULL , 
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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'WorkOrderQuote' , 
								CONVERT(VARCHAR(MAX), deleted.[WorkOrderQuote]) , 								NULL , 
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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'WorkOrderQuoteScope' , 
								CONVERT(VARCHAR(MAX), deleted.[WorkOrderQuoteScope]) , 								NULL , 
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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'WorkScope' , 
								CONVERT(VARCHAR(MAX), deleted.[WorkScope]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							
 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMWorkOrderQuoteScope_Audit_Delete] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMWorkOrderQuoteScope_Audit_Delete]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMWorkOrderQuoteScope_Audit_Insert ON dbo.vSMWorkOrderQuoteScope
 AFTER INSERT
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspAuditTriggersCreate

 BEGIN TRY 

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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'CallType' , 
								NULL , 
								[CallType] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'CustomerPO' , 
								NULL , 
								[CustomerPO] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

-- log additions to the DerivedEstimate column
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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'DerivedEstimate' , 
								NULL , 
								[DerivedEstimate] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Division' , 
								NULL , 
								[Division] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

-- log additions to the DueEndDate column
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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'DueEndDate' , 
								NULL , 
								[DueEndDate] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

-- log additions to the DueStartDate column
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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'DueStartDate' , 
								NULL , 
								[DueStartDate] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

-- log additions to the EquipmentCostEst column
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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'EquipmentCostEst' , 
								NULL , 
								[EquipmentCostEst] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

-- log additions to the LaborCostEst column
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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'LaborCostEst' , 
								NULL , 
								[LaborCostEst] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

-- log additions to the MaterialCostEst column
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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'MaterialCostEst' , 
								NULL , 
								[MaterialCostEst] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

-- log additions to the NotToExceed column
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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'NotToExceed' , 
								NULL , 
								[NotToExceed] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

-- log additions to the OtherCostEst column
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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'OtherCostEst' , 
								NULL , 
								[OtherCostEst] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

-- log additions to the Price column
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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Price' , 
								NULL , 
								[Price] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

-- log additions to the PriceMethod column
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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'PriceMethod' , 
								NULL , 
								[PriceMethod] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'RateTemplate' , 
								NULL , 
								[RateTemplate] , 
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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
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

-- log additions to the SubcontractCostEst column
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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'SubcontractCostEst' , 
								NULL , 
								[SubcontractCostEst] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'TaxCode' , 
								NULL , 
								[TaxCode] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'TaxGroup' , 
								NULL , 
								[TaxGroup] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

-- log additions to the TaxRate column
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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'TaxRate' , 
								NULL , 
								[TaxRate] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'TaxSource' , 
								NULL , 
								[TaxSource] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'TaxType' , 
								NULL , 
								[TaxType] , 
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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
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

-- log additions to the WorkOrderQuoteScope column
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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'WorkOrderQuoteScope' , 
								NULL , 
								[WorkOrderQuoteScope] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

-- log additions to the WorkScope column
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
								'vSMWorkOrderQuoteScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'WorkScope' , 
								NULL , 
								[WorkScope] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21


 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMWorkOrderQuoteScope_Audit_Insert] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMWorkOrderQuoteScope_Audit_Insert]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMWorkOrderQuoteScope_Audit_Update ON dbo.vSMWorkOrderQuoteScope
 AFTER UPDATE 
 NOT FOR REPLICATION AS 
 SET NOCOUNT ON 
 -- generated by vspAuditTriggersCreate

 BEGIN TRY 

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
								
								SELECT 							'vSMWorkOrderQuoteScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'CallType' , 								CONVERT(VARCHAR(MAX), deleted.[CallType]) , 								CONVERT(VARCHAR(MAX), inserted.[CallType]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteScopeID] = deleted.[SMWorkOrderQuoteScopeID] 
									AND ((inserted.[CallType] <> deleted.[CallType]) OR (inserted.[CallType] IS NULL AND deleted.[CallType] IS NOT NULL) OR (inserted.[CallType] IS NOT NULL AND deleted.[CallType] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

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
								
								SELECT 							'vSMWorkOrderQuoteScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'CustomerPO' , 								CONVERT(VARCHAR(MAX), deleted.[CustomerPO]) , 								CONVERT(VARCHAR(MAX), inserted.[CustomerPO]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteScopeID] = deleted.[SMWorkOrderQuoteScopeID] 
									AND ((inserted.[CustomerPO] <> deleted.[CustomerPO]) OR (inserted.[CustomerPO] IS NULL AND deleted.[CustomerPO] IS NOT NULL) OR (inserted.[CustomerPO] IS NOT NULL AND deleted.[CustomerPO] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([DerivedEstimate])
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
								
								SELECT 							'vSMWorkOrderQuoteScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'DerivedEstimate' , 								CONVERT(VARCHAR(MAX), deleted.[DerivedEstimate]) , 								CONVERT(VARCHAR(MAX), inserted.[DerivedEstimate]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteScopeID] = deleted.[SMWorkOrderQuoteScopeID] 
									AND ((inserted.[DerivedEstimate] <> deleted.[DerivedEstimate]) OR (inserted.[DerivedEstimate] IS NULL AND deleted.[DerivedEstimate] IS NOT NULL) OR (inserted.[DerivedEstimate] IS NOT NULL AND deleted.[DerivedEstimate] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

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
								
								SELECT 							'vSMWorkOrderQuoteScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'Division' , 								CONVERT(VARCHAR(MAX), deleted.[Division]) , 								CONVERT(VARCHAR(MAX), inserted.[Division]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteScopeID] = deleted.[SMWorkOrderQuoteScopeID] 
									AND ((inserted.[Division] <> deleted.[Division]) OR (inserted.[Division] IS NULL AND deleted.[Division] IS NOT NULL) OR (inserted.[Division] IS NOT NULL AND deleted.[Division] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([DueEndDate])
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
								
								SELECT 							'vSMWorkOrderQuoteScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'DueEndDate' , 								CONVERT(VARCHAR(MAX), deleted.[DueEndDate]) , 								CONVERT(VARCHAR(MAX), inserted.[DueEndDate]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteScopeID] = deleted.[SMWorkOrderQuoteScopeID] 
									AND ((inserted.[DueEndDate] <> deleted.[DueEndDate]) OR (inserted.[DueEndDate] IS NULL AND deleted.[DueEndDate] IS NOT NULL) OR (inserted.[DueEndDate] IS NOT NULL AND deleted.[DueEndDate] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([DueStartDate])
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
								
								SELECT 							'vSMWorkOrderQuoteScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'DueStartDate' , 								CONVERT(VARCHAR(MAX), deleted.[DueStartDate]) , 								CONVERT(VARCHAR(MAX), inserted.[DueStartDate]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteScopeID] = deleted.[SMWorkOrderQuoteScopeID] 
									AND ((inserted.[DueStartDate] <> deleted.[DueStartDate]) OR (inserted.[DueStartDate] IS NULL AND deleted.[DueStartDate] IS NOT NULL) OR (inserted.[DueStartDate] IS NOT NULL AND deleted.[DueStartDate] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([EquipmentCostEst])
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
								
								SELECT 							'vSMWorkOrderQuoteScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'EquipmentCostEst' , 								CONVERT(VARCHAR(MAX), deleted.[EquipmentCostEst]) , 								CONVERT(VARCHAR(MAX), inserted.[EquipmentCostEst]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteScopeID] = deleted.[SMWorkOrderQuoteScopeID] 
									AND ((inserted.[EquipmentCostEst] <> deleted.[EquipmentCostEst]) OR (inserted.[EquipmentCostEst] IS NULL AND deleted.[EquipmentCostEst] IS NOT NULL) OR (inserted.[EquipmentCostEst] IS NOT NULL AND deleted.[EquipmentCostEst] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([LaborCostEst])
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
								
								SELECT 							'vSMWorkOrderQuoteScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'LaborCostEst' , 								CONVERT(VARCHAR(MAX), deleted.[LaborCostEst]) , 								CONVERT(VARCHAR(MAX), inserted.[LaborCostEst]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteScopeID] = deleted.[SMWorkOrderQuoteScopeID] 
									AND ((inserted.[LaborCostEst] <> deleted.[LaborCostEst]) OR (inserted.[LaborCostEst] IS NULL AND deleted.[LaborCostEst] IS NOT NULL) OR (inserted.[LaborCostEst] IS NOT NULL AND deleted.[LaborCostEst] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([MaterialCostEst])
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
								
								SELECT 							'vSMWorkOrderQuoteScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'MaterialCostEst' , 								CONVERT(VARCHAR(MAX), deleted.[MaterialCostEst]) , 								CONVERT(VARCHAR(MAX), inserted.[MaterialCostEst]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteScopeID] = deleted.[SMWorkOrderQuoteScopeID] 
									AND ((inserted.[MaterialCostEst] <> deleted.[MaterialCostEst]) OR (inserted.[MaterialCostEst] IS NULL AND deleted.[MaterialCostEst] IS NOT NULL) OR (inserted.[MaterialCostEst] IS NOT NULL AND deleted.[MaterialCostEst] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([NotToExceed])
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
								
								SELECT 							'vSMWorkOrderQuoteScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'NotToExceed' , 								CONVERT(VARCHAR(MAX), deleted.[NotToExceed]) , 								CONVERT(VARCHAR(MAX), inserted.[NotToExceed]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteScopeID] = deleted.[SMWorkOrderQuoteScopeID] 
									AND ((inserted.[NotToExceed] <> deleted.[NotToExceed]) OR (inserted.[NotToExceed] IS NULL AND deleted.[NotToExceed] IS NOT NULL) OR (inserted.[NotToExceed] IS NOT NULL AND deleted.[NotToExceed] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([OtherCostEst])
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
								
								SELECT 							'vSMWorkOrderQuoteScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'OtherCostEst' , 								CONVERT(VARCHAR(MAX), deleted.[OtherCostEst]) , 								CONVERT(VARCHAR(MAX), inserted.[OtherCostEst]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteScopeID] = deleted.[SMWorkOrderQuoteScopeID] 
									AND ((inserted.[OtherCostEst] <> deleted.[OtherCostEst]) OR (inserted.[OtherCostEst] IS NULL AND deleted.[OtherCostEst] IS NOT NULL) OR (inserted.[OtherCostEst] IS NOT NULL AND deleted.[OtherCostEst] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([Price])
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
								
								SELECT 							'vSMWorkOrderQuoteScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'Price' , 								CONVERT(VARCHAR(MAX), deleted.[Price]) , 								CONVERT(VARCHAR(MAX), inserted.[Price]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteScopeID] = deleted.[SMWorkOrderQuoteScopeID] 
									AND ((inserted.[Price] <> deleted.[Price]) OR (inserted.[Price] IS NULL AND deleted.[Price] IS NOT NULL) OR (inserted.[Price] IS NOT NULL AND deleted.[Price] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([PriceMethod])
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
								
								SELECT 							'vSMWorkOrderQuoteScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'PriceMethod' , 								CONVERT(VARCHAR(MAX), deleted.[PriceMethod]) , 								CONVERT(VARCHAR(MAX), inserted.[PriceMethod]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteScopeID] = deleted.[SMWorkOrderQuoteScopeID] 
									AND ((inserted.[PriceMethod] <> deleted.[PriceMethod]) OR (inserted.[PriceMethod] IS NULL AND deleted.[PriceMethod] IS NOT NULL) OR (inserted.[PriceMethod] IS NOT NULL AND deleted.[PriceMethod] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

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
								
								SELECT 							'vSMWorkOrderQuoteScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'RateTemplate' , 								CONVERT(VARCHAR(MAX), deleted.[RateTemplate]) , 								CONVERT(VARCHAR(MAX), inserted.[RateTemplate]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteScopeID] = deleted.[SMWorkOrderQuoteScopeID] 
									AND ((inserted.[RateTemplate] <> deleted.[RateTemplate]) OR (inserted.[RateTemplate] IS NULL AND deleted.[RateTemplate] IS NOT NULL) OR (inserted.[RateTemplate] IS NOT NULL AND deleted.[RateTemplate] IS NULL))
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
								
								SELECT 							'vSMWorkOrderQuoteScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'SMCo' , 								CONVERT(VARCHAR(MAX), deleted.[SMCo]) , 								CONVERT(VARCHAR(MAX), inserted.[SMCo]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteScopeID] = deleted.[SMWorkOrderQuoteScopeID] 
									AND ((inserted.[SMCo] <> deleted.[SMCo]) OR (inserted.[SMCo] IS NULL AND deleted.[SMCo] IS NOT NULL) OR (inserted.[SMCo] IS NOT NULL AND deleted.[SMCo] IS NULL))
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
								
								SELECT 							'vSMWorkOrderQuoteScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'ServiceCenter' , 								CONVERT(VARCHAR(MAX), deleted.[ServiceCenter]) , 								CONVERT(VARCHAR(MAX), inserted.[ServiceCenter]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteScopeID] = deleted.[SMWorkOrderQuoteScopeID] 
									AND ((inserted.[ServiceCenter] <> deleted.[ServiceCenter]) OR (inserted.[ServiceCenter] IS NULL AND deleted.[ServiceCenter] IS NOT NULL) OR (inserted.[ServiceCenter] IS NOT NULL AND deleted.[ServiceCenter] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([SubcontractCostEst])
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
								
								SELECT 							'vSMWorkOrderQuoteScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'SubcontractCostEst' , 								CONVERT(VARCHAR(MAX), deleted.[SubcontractCostEst]) , 								CONVERT(VARCHAR(MAX), inserted.[SubcontractCostEst]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteScopeID] = deleted.[SMWorkOrderQuoteScopeID] 
									AND ((inserted.[SubcontractCostEst] <> deleted.[SubcontractCostEst]) OR (inserted.[SubcontractCostEst] IS NULL AND deleted.[SubcontractCostEst] IS NOT NULL) OR (inserted.[SubcontractCostEst] IS NOT NULL AND deleted.[SubcontractCostEst] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

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
								
								SELECT 							'vSMWorkOrderQuoteScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'TaxCode' , 								CONVERT(VARCHAR(MAX), deleted.[TaxCode]) , 								CONVERT(VARCHAR(MAX), inserted.[TaxCode]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteScopeID] = deleted.[SMWorkOrderQuoteScopeID] 
									AND ((inserted.[TaxCode] <> deleted.[TaxCode]) OR (inserted.[TaxCode] IS NULL AND deleted.[TaxCode] IS NOT NULL) OR (inserted.[TaxCode] IS NOT NULL AND deleted.[TaxCode] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

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
								
								SELECT 							'vSMWorkOrderQuoteScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'TaxGroup' , 								CONVERT(VARCHAR(MAX), deleted.[TaxGroup]) , 								CONVERT(VARCHAR(MAX), inserted.[TaxGroup]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteScopeID] = deleted.[SMWorkOrderQuoteScopeID] 
									AND ((inserted.[TaxGroup] <> deleted.[TaxGroup]) OR (inserted.[TaxGroup] IS NULL AND deleted.[TaxGroup] IS NOT NULL) OR (inserted.[TaxGroup] IS NOT NULL AND deleted.[TaxGroup] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([TaxRate])
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
								
								SELECT 							'vSMWorkOrderQuoteScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'TaxRate' , 								CONVERT(VARCHAR(MAX), deleted.[TaxRate]) , 								CONVERT(VARCHAR(MAX), inserted.[TaxRate]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteScopeID] = deleted.[SMWorkOrderQuoteScopeID] 
									AND ((inserted.[TaxRate] <> deleted.[TaxRate]) OR (inserted.[TaxRate] IS NULL AND deleted.[TaxRate] IS NOT NULL) OR (inserted.[TaxRate] IS NOT NULL AND deleted.[TaxRate] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

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
								
								SELECT 							'vSMWorkOrderQuoteScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'TaxSource' , 								CONVERT(VARCHAR(MAX), deleted.[TaxSource]) , 								CONVERT(VARCHAR(MAX), inserted.[TaxSource]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteScopeID] = deleted.[SMWorkOrderQuoteScopeID] 
									AND ((inserted.[TaxSource] <> deleted.[TaxSource]) OR (inserted.[TaxSource] IS NULL AND deleted.[TaxSource] IS NOT NULL) OR (inserted.[TaxSource] IS NOT NULL AND deleted.[TaxSource] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

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
								
								SELECT 							'vSMWorkOrderQuoteScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'TaxType' , 								CONVERT(VARCHAR(MAX), deleted.[TaxType]) , 								CONVERT(VARCHAR(MAX), inserted.[TaxType]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteScopeID] = deleted.[SMWorkOrderQuoteScopeID] 
									AND ((inserted.[TaxType] <> deleted.[TaxType]) OR (inserted.[TaxType] IS NULL AND deleted.[TaxType] IS NOT NULL) OR (inserted.[TaxType] IS NOT NULL AND deleted.[TaxType] IS NULL))
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
								
								SELECT 							'vSMWorkOrderQuoteScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'WorkOrderQuote' , 								CONVERT(VARCHAR(MAX), deleted.[WorkOrderQuote]) , 								CONVERT(VARCHAR(MAX), inserted.[WorkOrderQuote]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteScopeID] = deleted.[SMWorkOrderQuoteScopeID] 
									AND ((inserted.[WorkOrderQuote] <> deleted.[WorkOrderQuote]) OR (inserted.[WorkOrderQuote] IS NULL AND deleted.[WorkOrderQuote] IS NOT NULL) OR (inserted.[WorkOrderQuote] IS NOT NULL AND deleted.[WorkOrderQuote] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([WorkOrderQuoteScope])
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
								
								SELECT 							'vSMWorkOrderQuoteScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'WorkOrderQuoteScope' , 								CONVERT(VARCHAR(MAX), deleted.[WorkOrderQuoteScope]) , 								CONVERT(VARCHAR(MAX), inserted.[WorkOrderQuoteScope]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteScopeID] = deleted.[SMWorkOrderQuoteScopeID] 
									AND ((inserted.[WorkOrderQuoteScope] <> deleted.[WorkOrderQuoteScope]) OR (inserted.[WorkOrderQuoteScope] IS NULL AND deleted.[WorkOrderQuoteScope] IS NOT NULL) OR (inserted.[WorkOrderQuoteScope] IS NOT NULL AND deleted.[WorkOrderQuoteScope] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 

							IF UPDATE([WorkScope])
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
								
								SELECT 							'vSMWorkOrderQuoteScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuote = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuote],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrderQuoteScope = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrderQuoteScope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'WorkScope' , 								CONVERT(VARCHAR(MAX), deleted.[WorkScope]) , 								CONVERT(VARCHAR(MAX), inserted.[WorkScope]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderQuoteScopeID] = deleted.[SMWorkOrderQuoteScopeID] 
									AND ((inserted.[WorkScope] <> deleted.[WorkScope]) OR (inserted.[WorkScope] IS NULL AND deleted.[WorkScope] IS NOT NULL) OR (inserted.[WorkScope] IS NOT NULL AND deleted.[WorkScope] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 21

							END 



 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMWorkOrderQuoteScope_Audit_Update] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMWorkOrderQuoteScope_Audit_Update]', 'last', 'update', null
GO
ALTER TABLE [dbo].[vSMWorkOrderQuoteScope] ADD CONSTRAINT [PK_vSMWorkOrderQuoteScope] PRIMARY KEY CLUSTERED  ([SMWorkOrderQuoteScopeID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMWorkOrderQuoteScope] ADD CONSTRAINT [IX_vSMWorkOrderQuoteScope_SMCo_WorkOrderQuote_WorkScope] UNIQUE NONCLUSTERED  ([SMCo], [WorkOrderQuote], [WorkOrderQuoteScope]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMWorkOrderQuoteScope] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkOrderQuoteScope_vSMCallType] FOREIGN KEY ([SMCo], [CallType]) REFERENCES [dbo].[vSMCallType] ([SMCo], [CallType])
GO
ALTER TABLE [dbo].[vSMWorkOrderQuoteScope] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkOrderQuoteScope_vSMWorkOrderQuote] FOREIGN KEY ([SMCo], [WorkOrderQuote]) REFERENCES [dbo].[vSMWorkOrderQuote] ([SMCo], [WorkOrderQuote])
GO
ALTER TABLE [dbo].[vSMWorkOrderQuoteScope] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkOrderQuoteScope_vSMWorkScope] FOREIGN KEY ([SMCo], [WorkScope]) REFERENCES [dbo].[vSMWorkScope] ([SMCo], [WorkScope])
GO
ALTER TABLE [dbo].[vSMWorkOrderQuoteScope] NOCHECK CONSTRAINT [FK_vSMWorkOrderQuoteScope_vSMCallType]
GO
ALTER TABLE [dbo].[vSMWorkOrderQuoteScope] NOCHECK CONSTRAINT [FK_vSMWorkOrderQuoteScope_vSMWorkOrderQuote]
GO
ALTER TABLE [dbo].[vSMWorkOrderQuoteScope] NOCHECK CONSTRAINT [FK_vSMWorkOrderQuoteScope_vSMWorkScope]
GO
