CREATE TABLE [dbo].[vSMWorkCompleted]
(
[SMWorkCompletedID] [bigint] NOT NULL IDENTITY(1, 1),
[SMCo] [dbo].[bCompany] NOT NULL,
[WorkOrder] [int] NOT NULL,
[WorkCompleted] [int] NOT NULL,
[Type] [tinyint] NOT NULL,
[IsDeleted] [bit] NOT NULL CONSTRAINT [DF_vSMWorkCompleted_IsDeleted] DEFAULT ((0)),
[UniqueAttchID] [uniqueidentifier] NULL,
[SMWorkCompletedARTLID] [bigint] NULL,
[InitialCostsCaptured] [bit] NOT NULL CONSTRAINT [DF_vSMWorkCompleted_InitialCostsCaptured] DEFAULT ((0)),
[CostsCaptured] [bit] NOT NULL CONSTRAINT [DF_vSMWorkCompleted_CostsCaptured] DEFAULT ((0)),
[CostCo] [dbo].[bCompany] NULL,
[CostMth] [dbo].[bMonth] NULL,
[CostTrans] [dbo].[bTrans] NULL,
[PRGroup] [dbo].[bGroup] NULL,
[PREndDate] [smalldatetime] NULL,
[PREmployee] [dbo].[bEmployee] NULL,
[PRPaySeq] [tinyint] NULL,
[PRPostSeq] [smallint] NULL,
[PRPostDate] [smalldatetime] NULL,
[APCo] [dbo].[bCompany] NULL,
[APInUseMth] [dbo].[bMonth] NULL,
[APInUseBatchId] [dbo].[bBatchID] NULL,
[APTLKeyID] [bigint] NULL,
[JCCo] [dbo].[bCompany] NULL,
[JCMth] [dbo].[bMonth] NULL,
[JCCostTrans] [dbo].[bTrans] NULL,
[JCCostTaxTrans] [dbo].[bTrans] NULL,
[JCCostEntryID] [bigint] NULL,
[Provisional] [bit] NOT NULL CONSTRAINT [DF_vSMWorkCompleted_Provisional] DEFAULT ((0)),
[AutoAdded] [bit] NOT NULL CONSTRAINT [DF_vSMWorkCompleted_AutoAdded] DEFAULT ((0)),
[ReferenceNo] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[RevenueGLEntryID] [bigint] NULL,
[RevenueSMWIPGLEntryID] [bigint] NULL,
[RevenueJCWIPGLEntryID] [bigint] NULL,
[PRLedgerUpdateMonthID] [bigint] NULL,
[CostDetailID] [bigint] NULL,
[NonBillable] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vSMWorkCompleted_NonBillable] DEFAULT ('N')
) ON [PRIMARY]
ALTER TABLE [dbo].[vSMWorkCompleted] WITH NOCHECK ADD
CONSTRAINT [FK_vSMWorkCompleted_bJCCD_TaxTrans] FOREIGN KEY ([JCCostTaxTrans], [JCMth], [JCCo]) REFERENCES [dbo].[bJCCD] ([CostTrans], [Mth], [JCCo])
ALTER TABLE [dbo].[vSMWorkCompleted] WITH NOCHECK ADD
CONSTRAINT [FK_vSMWorkCompleted_bJCCD] FOREIGN KEY ([JCCostTrans], [JCMth], [JCCo]) REFERENCES [dbo].[bJCCD] ([CostTrans], [Mth], [JCCo])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Lane Gresham
-- Create date: May 13, 2011
-- Description:	Do now allow deletes if the work order is closed or canceled.
-- Modification: LDG 05/13/11 Added check to see if there are any canceled workorders.
-- =============================================
CREATE TRIGGER [dbo].[vtSMWorkCompletedd]
   ON  [dbo].[vSMWorkCompleted]
   AFTER DELETE
AS 
BEGIN

	SET NOCOUNT ON; 
	
	-- Checks to see if there are any canceled workorders
	IF EXISTS(
		SELECT 1 FROM INSERTED
		INNER JOIN dbo.vSMWorkOrder
			ON INSERTED.SMCo = vSMWorkOrder.SMCo
			AND INSERTED.WorkOrder = vSMWorkOrder.WorkOrder
		WHERE vSMWorkOrder.WOStatus = 2
	)
	BEGIN
	
		RAISERROR('Workcompleted can''t be deleted to a canceled workorder - cannot deleted Work Completed!', 11, -1)
		ROLLBACK TRANSACTION
		
	END

END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Vaterlaus
-- Create date: Dec 1, 2010
-- Description:	Do now allow updates if the work order is closed or canceled.
-- Modification: ECV 02/07/11 Remove restriction on updates to closed work orders.
-- Modification: LDG 05/12/11 Added check to see if there are any canceled workorders.
-- =============================================
CREATE TRIGGER [dbo].[vtSMWorkCompletedi]
   ON  [dbo].[vSMWorkCompleted]
   AFTER INSERT
AS 
BEGIN

	SET NOCOUNT ON; 
	
	-- Checks to see if there are any canceled workorders
	IF EXISTS(
		SELECT 1 FROM INSERTED
		INNER JOIN dbo.vSMWorkOrder
			ON INSERTED.SMCo = vSMWorkOrder.SMCo
			AND INSERTED.WorkOrder = vSMWorkOrder.WorkOrder
		WHERE vSMWorkOrder.WOStatus = 2
	)
	BEGIN
	
		RAISERROR('Workcompleted can''t be added to a canceled workorder - cannot insert Work Completed!', 11, -1)
		ROLLBACK TRANSACTION
		
	END
END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Lane Gresham
-- Create date: May 13, 2011
-- Description:	Do now allow updates if the work order is closed or canceled.
-- Modification: LDG 05/13/11 Added check to see if there are any canceled workorders.
-- =============================================
CREATE TRIGGER [dbo].[vtSMWorkCompletedu]
   ON  [dbo].[vSMWorkCompleted]
   AFTER UPDATE
AS 
BEGIN

	SET NOCOUNT ON; 
	
	-- Checks to see if there are any canceled workorders
	IF EXISTS(
		SELECT 1 FROM INSERTED
		INNER JOIN dbo.vSMWorkOrder
			ON INSERTED.SMCo = vSMWorkOrder.SMCo
			AND INSERTED.WorkOrder = vSMWorkOrder.WorkOrder
		WHERE vSMWorkOrder.WOStatus = 2
	)
	BEGIN
	
		RAISERROR('Workcompleted can''t be updated to a canceled workorder - cannot update Work Completed!', 11, -1)
		ROLLBACK TRANSACTION
		
	END
	
	--Prevent marking work completed as deleted when it is still tied to an invoice.
	IF UPDATE(IsDeleted) AND
		EXISTS(
		SELECT 1
		FROM dbo.SMWorkCompletedDetail
			INNER JOIN INSERTED ON SMWorkCompletedDetail.SMWorkCompletedID = INSERTED.SMWorkCompletedID
		WHERE INSERTED.IsDeleted = 1 AND SMWorkCompletedDetail.SMInvoiceID IS NOT NULL)
	BEGIN
		RAISERROR('Work Completed can''t be deleted when it is still associated with an invoice - cannot deleted Work Completed!', 11, -1)
		ROLLBACK TRANSACTION
	END
END


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMWorkCompleted_Audit_Delete ON dbo.vSMWorkCompleted
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'APCo' , 
								CONVERT(VARCHAR(MAX), deleted.[APCo]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'APInUseBatchId' , 
								CONVERT(VARCHAR(MAX), deleted.[APInUseBatchId]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'APInUseMth' , 
								CONVERT(VARCHAR(MAX), deleted.[APInUseMth]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'APTLKeyID' , 
								CONVERT(VARCHAR(MAX), deleted.[APTLKeyID]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'AutoAdded' , 
								CONVERT(VARCHAR(MAX), deleted.[AutoAdded]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'CostCo' , 
								CONVERT(VARCHAR(MAX), deleted.[CostCo]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'CostDetailID' , 
								CONVERT(VARCHAR(MAX), deleted.[CostDetailID]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'CostMth' , 
								CONVERT(VARCHAR(MAX), deleted.[CostMth]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'CostTrans' , 
								CONVERT(VARCHAR(MAX), deleted.[CostTrans]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'CostsCaptured' , 
								CONVERT(VARCHAR(MAX), deleted.[CostsCaptured]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'InitialCostsCaptured' , 
								CONVERT(VARCHAR(MAX), deleted.[InitialCostsCaptured]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'IsDeleted' , 
								CONVERT(VARCHAR(MAX), deleted.[IsDeleted]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'JCCo' , 
								CONVERT(VARCHAR(MAX), deleted.[JCCo]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'JCCostEntryID' , 
								CONVERT(VARCHAR(MAX), deleted.[JCCostEntryID]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'JCCostTaxTrans' , 
								CONVERT(VARCHAR(MAX), deleted.[JCCostTaxTrans]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'JCCostTrans' , 
								CONVERT(VARCHAR(MAX), deleted.[JCCostTrans]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'JCMth' , 
								CONVERT(VARCHAR(MAX), deleted.[JCMth]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'NonBillable' , 
								CONVERT(VARCHAR(MAX), deleted.[NonBillable]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'PREmployee' , 
								CONVERT(VARCHAR(MAX), deleted.[PREmployee]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'PREndDate' , 
								CONVERT(VARCHAR(MAX), deleted.[PREndDate]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'PRGroup' , 
								CONVERT(VARCHAR(MAX), deleted.[PRGroup]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'PRLedgerUpdateMonthID' , 
								CONVERT(VARCHAR(MAX), deleted.[PRLedgerUpdateMonthID]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'PRPaySeq' , 
								CONVERT(VARCHAR(MAX), deleted.[PRPaySeq]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'PRPostDate' , 
								CONVERT(VARCHAR(MAX), deleted.[PRPostDate]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'PRPostSeq' , 
								CONVERT(VARCHAR(MAX), deleted.[PRPostSeq]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'Provisional' , 
								CONVERT(VARCHAR(MAX), deleted.[Provisional]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'ReferenceNo' , 
								CONVERT(VARCHAR(MAX), deleted.[ReferenceNo]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'RevenueGLEntryID' , 
								CONVERT(VARCHAR(MAX), deleted.[RevenueGLEntryID]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'RevenueJCWIPGLEntryID' , 
								CONVERT(VARCHAR(MAX), deleted.[RevenueJCWIPGLEntryID]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'RevenueSMWIPGLEntryID' , 
								CONVERT(VARCHAR(MAX), deleted.[RevenueSMWIPGLEntryID]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'SMCo' , 
								CONVERT(VARCHAR(MAX), deleted.[SMCo]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'SMWorkCompletedARTLID' , 
								CONVERT(VARCHAR(MAX), deleted.[SMWorkCompletedARTLID]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'SMWorkCompletedID' , 
								CONVERT(VARCHAR(MAX), deleted.[SMWorkCompletedID]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'Type' , 
								CONVERT(VARCHAR(MAX), deleted.[Type]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'UniqueAttchID' , 
								CONVERT(VARCHAR(MAX), deleted.[UniqueAttchID]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'WorkCompleted' , 
								CONVERT(VARCHAR(MAX), deleted.[WorkCompleted]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'WorkOrder' , 
								CONVERT(VARCHAR(MAX), deleted.[WorkOrder]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							
 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMWorkCompleted_Audit_Delete] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMWorkCompleted_Audit_Delete]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMWorkCompleted_Audit_Insert ON dbo.vSMWorkCompleted
 AFTER INSERT
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspAuditTriggersCreate

 BEGIN TRY 

-- log additions to the APCo column
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'APCo' , 
								NULL , 
								APCo , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the APInUseBatchId column
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'APInUseBatchId' , 
								NULL , 
								APInUseBatchId , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the APInUseMth column
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'APInUseMth' , 
								NULL , 
								APInUseMth , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the APTLKeyID column
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'APTLKeyID' , 
								NULL , 
								APTLKeyID , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the AutoAdded column
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'AutoAdded' , 
								NULL , 
								AutoAdded , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the CostCo column
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'CostCo' , 
								NULL , 
								CostCo , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the CostDetailID column
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'CostDetailID' , 
								NULL , 
								CostDetailID , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the CostMth column
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'CostMth' , 
								NULL , 
								CostMth , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the CostTrans column
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'CostTrans' , 
								NULL , 
								CostTrans , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the CostsCaptured column
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'CostsCaptured' , 
								NULL , 
								CostsCaptured , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the InitialCostsCaptured column
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'InitialCostsCaptured' , 
								NULL , 
								InitialCostsCaptured , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the IsDeleted column
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'IsDeleted' , 
								NULL , 
								IsDeleted , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the JCCo column
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'JCCo' , 
								NULL , 
								JCCo , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the JCCostEntryID column
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'JCCostEntryID' , 
								NULL , 
								JCCostEntryID , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the JCCostTaxTrans column
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'JCCostTaxTrans' , 
								NULL , 
								JCCostTaxTrans , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the JCCostTrans column
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'JCCostTrans' , 
								NULL , 
								JCCostTrans , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the JCMth column
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'JCMth' , 
								NULL , 
								JCMth , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the NonBillable column
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'NonBillable' , 
								NULL , 
								NonBillable , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the PREmployee column
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'PREmployee' , 
								NULL , 
								PREmployee , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the PREndDate column
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'PREndDate' , 
								NULL , 
								PREndDate , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the PRGroup column
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'PRGroup' , 
								NULL , 
								PRGroup , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the PRLedgerUpdateMonthID column
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'PRLedgerUpdateMonthID' , 
								NULL , 
								PRLedgerUpdateMonthID , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the PRPaySeq column
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'PRPaySeq' , 
								NULL , 
								PRPaySeq , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the PRPostDate column
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'PRPostDate' , 
								NULL , 
								PRPostDate , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the PRPostSeq column
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'PRPostSeq' , 
								NULL , 
								PRPostSeq , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the Provisional column
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Provisional' , 
								NULL , 
								Provisional , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the ReferenceNo column
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'ReferenceNo' , 
								NULL , 
								ReferenceNo , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the RevenueGLEntryID column
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'RevenueGLEntryID' , 
								NULL , 
								RevenueGLEntryID , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the RevenueJCWIPGLEntryID column
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'RevenueJCWIPGLEntryID' , 
								NULL , 
								RevenueJCWIPGLEntryID , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the RevenueSMWIPGLEntryID column
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'RevenueSMWIPGLEntryID' , 
								NULL , 
								RevenueSMWIPGLEntryID , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'SMCo' , 
								NULL , 
								SMCo , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the SMWorkCompletedARTLID column
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'SMWorkCompletedARTLID' , 
								NULL , 
								SMWorkCompletedARTLID , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the SMWorkCompletedID column
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'SMWorkCompletedID' , 
								NULL , 
								SMWorkCompletedID , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the Type column
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Type' , 
								NULL , 
								Type , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'UniqueAttchID' , 
								NULL , 
								UniqueAttchID , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the WorkCompleted column
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'WorkCompleted' , 
								NULL , 
								WorkCompleted , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the WorkOrder column
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
								'vSMWorkCompleted' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'WorkOrder' , 
								NULL , 
								WorkOrder , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14


 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMWorkCompleted_Audit_Insert] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMWorkCompleted_Audit_Insert]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMWorkCompleted_Audit_Update ON dbo.vSMWorkCompleted
 AFTER UPDATE 
 NOT FOR REPLICATION AS 
 SET NOCOUNT ON 
 -- generated by vspAuditTriggersCreate

 BEGIN TRY 

							IF UPDATE([APCo])
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
								
								SELECT 							'vSMWorkCompleted' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'APCo' , 								CONVERT(VARCHAR(MAX), deleted.[APCo]) , 								CONVERT(VARCHAR(MAX), inserted.[APCo]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedID] = deleted.[SMWorkCompletedID] 
									AND ((inserted.[APCo] <> deleted.[APCo]) OR (inserted.[APCo] IS NULL AND deleted.[APCo] IS NOT NULL) OR (inserted.[APCo] IS NOT NULL AND deleted.[APCo] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([APInUseBatchId])
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
								
								SELECT 							'vSMWorkCompleted' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'APInUseBatchId' , 								CONVERT(VARCHAR(MAX), deleted.[APInUseBatchId]) , 								CONVERT(VARCHAR(MAX), inserted.[APInUseBatchId]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedID] = deleted.[SMWorkCompletedID] 
									AND ((inserted.[APInUseBatchId] <> deleted.[APInUseBatchId]) OR (inserted.[APInUseBatchId] IS NULL AND deleted.[APInUseBatchId] IS NOT NULL) OR (inserted.[APInUseBatchId] IS NOT NULL AND deleted.[APInUseBatchId] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([APInUseMth])
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
								
								SELECT 							'vSMWorkCompleted' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'APInUseMth' , 								CONVERT(VARCHAR(MAX), deleted.[APInUseMth]) , 								CONVERT(VARCHAR(MAX), inserted.[APInUseMth]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedID] = deleted.[SMWorkCompletedID] 
									AND ((inserted.[APInUseMth] <> deleted.[APInUseMth]) OR (inserted.[APInUseMth] IS NULL AND deleted.[APInUseMth] IS NOT NULL) OR (inserted.[APInUseMth] IS NOT NULL AND deleted.[APInUseMth] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([APTLKeyID])
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
								
								SELECT 							'vSMWorkCompleted' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'APTLKeyID' , 								CONVERT(VARCHAR(MAX), deleted.[APTLKeyID]) , 								CONVERT(VARCHAR(MAX), inserted.[APTLKeyID]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedID] = deleted.[SMWorkCompletedID] 
									AND ((inserted.[APTLKeyID] <> deleted.[APTLKeyID]) OR (inserted.[APTLKeyID] IS NULL AND deleted.[APTLKeyID] IS NOT NULL) OR (inserted.[APTLKeyID] IS NOT NULL AND deleted.[APTLKeyID] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([AutoAdded])
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
								
								SELECT 							'vSMWorkCompleted' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'AutoAdded' , 								CONVERT(VARCHAR(MAX), deleted.[AutoAdded]) , 								CONVERT(VARCHAR(MAX), inserted.[AutoAdded]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedID] = deleted.[SMWorkCompletedID] 
									AND ((inserted.[AutoAdded] <> deleted.[AutoAdded]) OR (inserted.[AutoAdded] IS NULL AND deleted.[AutoAdded] IS NOT NULL) OR (inserted.[AutoAdded] IS NOT NULL AND deleted.[AutoAdded] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([CostCo])
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
								
								SELECT 							'vSMWorkCompleted' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'CostCo' , 								CONVERT(VARCHAR(MAX), deleted.[CostCo]) , 								CONVERT(VARCHAR(MAX), inserted.[CostCo]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedID] = deleted.[SMWorkCompletedID] 
									AND ((inserted.[CostCo] <> deleted.[CostCo]) OR (inserted.[CostCo] IS NULL AND deleted.[CostCo] IS NOT NULL) OR (inserted.[CostCo] IS NOT NULL AND deleted.[CostCo] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([CostDetailID])
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
								
								SELECT 							'vSMWorkCompleted' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'CostDetailID' , 								CONVERT(VARCHAR(MAX), deleted.[CostDetailID]) , 								CONVERT(VARCHAR(MAX), inserted.[CostDetailID]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedID] = deleted.[SMWorkCompletedID] 
									AND ((inserted.[CostDetailID] <> deleted.[CostDetailID]) OR (inserted.[CostDetailID] IS NULL AND deleted.[CostDetailID] IS NOT NULL) OR (inserted.[CostDetailID] IS NOT NULL AND deleted.[CostDetailID] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([CostMth])
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
								
								SELECT 							'vSMWorkCompleted' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'CostMth' , 								CONVERT(VARCHAR(MAX), deleted.[CostMth]) , 								CONVERT(VARCHAR(MAX), inserted.[CostMth]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedID] = deleted.[SMWorkCompletedID] 
									AND ((inserted.[CostMth] <> deleted.[CostMth]) OR (inserted.[CostMth] IS NULL AND deleted.[CostMth] IS NOT NULL) OR (inserted.[CostMth] IS NOT NULL AND deleted.[CostMth] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([CostTrans])
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
								
								SELECT 							'vSMWorkCompleted' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'CostTrans' , 								CONVERT(VARCHAR(MAX), deleted.[CostTrans]) , 								CONVERT(VARCHAR(MAX), inserted.[CostTrans]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedID] = deleted.[SMWorkCompletedID] 
									AND ((inserted.[CostTrans] <> deleted.[CostTrans]) OR (inserted.[CostTrans] IS NULL AND deleted.[CostTrans] IS NOT NULL) OR (inserted.[CostTrans] IS NOT NULL AND deleted.[CostTrans] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([CostsCaptured])
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
								
								SELECT 							'vSMWorkCompleted' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'CostsCaptured' , 								CONVERT(VARCHAR(MAX), deleted.[CostsCaptured]) , 								CONVERT(VARCHAR(MAX), inserted.[CostsCaptured]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedID] = deleted.[SMWorkCompletedID] 
									AND ((inserted.[CostsCaptured] <> deleted.[CostsCaptured]) OR (inserted.[CostsCaptured] IS NULL AND deleted.[CostsCaptured] IS NOT NULL) OR (inserted.[CostsCaptured] IS NOT NULL AND deleted.[CostsCaptured] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([InitialCostsCaptured])
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
								
								SELECT 							'vSMWorkCompleted' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'InitialCostsCaptured' , 								CONVERT(VARCHAR(MAX), deleted.[InitialCostsCaptured]) , 								CONVERT(VARCHAR(MAX), inserted.[InitialCostsCaptured]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedID] = deleted.[SMWorkCompletedID] 
									AND ((inserted.[InitialCostsCaptured] <> deleted.[InitialCostsCaptured]) OR (inserted.[InitialCostsCaptured] IS NULL AND deleted.[InitialCostsCaptured] IS NOT NULL) OR (inserted.[InitialCostsCaptured] IS NOT NULL AND deleted.[InitialCostsCaptured] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([IsDeleted])
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
								
								SELECT 							'vSMWorkCompleted' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'IsDeleted' , 								CONVERT(VARCHAR(MAX), deleted.[IsDeleted]) , 								CONVERT(VARCHAR(MAX), inserted.[IsDeleted]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedID] = deleted.[SMWorkCompletedID] 
									AND ((inserted.[IsDeleted] <> deleted.[IsDeleted]) OR (inserted.[IsDeleted] IS NULL AND deleted.[IsDeleted] IS NOT NULL) OR (inserted.[IsDeleted] IS NOT NULL AND deleted.[IsDeleted] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([JCCo])
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
								
								SELECT 							'vSMWorkCompleted' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'JCCo' , 								CONVERT(VARCHAR(MAX), deleted.[JCCo]) , 								CONVERT(VARCHAR(MAX), inserted.[JCCo]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedID] = deleted.[SMWorkCompletedID] 
									AND ((inserted.[JCCo] <> deleted.[JCCo]) OR (inserted.[JCCo] IS NULL AND deleted.[JCCo] IS NOT NULL) OR (inserted.[JCCo] IS NOT NULL AND deleted.[JCCo] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([JCCostEntryID])
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
								
								SELECT 							'vSMWorkCompleted' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'JCCostEntryID' , 								CONVERT(VARCHAR(MAX), deleted.[JCCostEntryID]) , 								CONVERT(VARCHAR(MAX), inserted.[JCCostEntryID]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedID] = deleted.[SMWorkCompletedID] 
									AND ((inserted.[JCCostEntryID] <> deleted.[JCCostEntryID]) OR (inserted.[JCCostEntryID] IS NULL AND deleted.[JCCostEntryID] IS NOT NULL) OR (inserted.[JCCostEntryID] IS NOT NULL AND deleted.[JCCostEntryID] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([JCCostTaxTrans])
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
								
								SELECT 							'vSMWorkCompleted' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'JCCostTaxTrans' , 								CONVERT(VARCHAR(MAX), deleted.[JCCostTaxTrans]) , 								CONVERT(VARCHAR(MAX), inserted.[JCCostTaxTrans]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedID] = deleted.[SMWorkCompletedID] 
									AND ((inserted.[JCCostTaxTrans] <> deleted.[JCCostTaxTrans]) OR (inserted.[JCCostTaxTrans] IS NULL AND deleted.[JCCostTaxTrans] IS NOT NULL) OR (inserted.[JCCostTaxTrans] IS NOT NULL AND deleted.[JCCostTaxTrans] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([JCCostTrans])
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
								
								SELECT 							'vSMWorkCompleted' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'JCCostTrans' , 								CONVERT(VARCHAR(MAX), deleted.[JCCostTrans]) , 								CONVERT(VARCHAR(MAX), inserted.[JCCostTrans]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedID] = deleted.[SMWorkCompletedID] 
									AND ((inserted.[JCCostTrans] <> deleted.[JCCostTrans]) OR (inserted.[JCCostTrans] IS NULL AND deleted.[JCCostTrans] IS NOT NULL) OR (inserted.[JCCostTrans] IS NOT NULL AND deleted.[JCCostTrans] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([JCMth])
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
								
								SELECT 							'vSMWorkCompleted' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'JCMth' , 								CONVERT(VARCHAR(MAX), deleted.[JCMth]) , 								CONVERT(VARCHAR(MAX), inserted.[JCMth]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedID] = deleted.[SMWorkCompletedID] 
									AND ((inserted.[JCMth] <> deleted.[JCMth]) OR (inserted.[JCMth] IS NULL AND deleted.[JCMth] IS NOT NULL) OR (inserted.[JCMth] IS NOT NULL AND deleted.[JCMth] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([NonBillable])
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
								
								SELECT 							'vSMWorkCompleted' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'NonBillable' , 								CONVERT(VARCHAR(MAX), deleted.[NonBillable]) , 								CONVERT(VARCHAR(MAX), inserted.[NonBillable]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedID] = deleted.[SMWorkCompletedID] 
									AND ((inserted.[NonBillable] <> deleted.[NonBillable]) OR (inserted.[NonBillable] IS NULL AND deleted.[NonBillable] IS NOT NULL) OR (inserted.[NonBillable] IS NOT NULL AND deleted.[NonBillable] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([PREmployee])
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
								
								SELECT 							'vSMWorkCompleted' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'PREmployee' , 								CONVERT(VARCHAR(MAX), deleted.[PREmployee]) , 								CONVERT(VARCHAR(MAX), inserted.[PREmployee]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedID] = deleted.[SMWorkCompletedID] 
									AND ((inserted.[PREmployee] <> deleted.[PREmployee]) OR (inserted.[PREmployee] IS NULL AND deleted.[PREmployee] IS NOT NULL) OR (inserted.[PREmployee] IS NOT NULL AND deleted.[PREmployee] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([PREndDate])
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
								
								SELECT 							'vSMWorkCompleted' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'PREndDate' , 								CONVERT(VARCHAR(MAX), deleted.[PREndDate]) , 								CONVERT(VARCHAR(MAX), inserted.[PREndDate]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedID] = deleted.[SMWorkCompletedID] 
									AND ((inserted.[PREndDate] <> deleted.[PREndDate]) OR (inserted.[PREndDate] IS NULL AND deleted.[PREndDate] IS NOT NULL) OR (inserted.[PREndDate] IS NOT NULL AND deleted.[PREndDate] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([PRGroup])
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
								
								SELECT 							'vSMWorkCompleted' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'PRGroup' , 								CONVERT(VARCHAR(MAX), deleted.[PRGroup]) , 								CONVERT(VARCHAR(MAX), inserted.[PRGroup]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedID] = deleted.[SMWorkCompletedID] 
									AND ((inserted.[PRGroup] <> deleted.[PRGroup]) OR (inserted.[PRGroup] IS NULL AND deleted.[PRGroup] IS NOT NULL) OR (inserted.[PRGroup] IS NOT NULL AND deleted.[PRGroup] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([PRLedgerUpdateMonthID])
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
								
								SELECT 							'vSMWorkCompleted' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'PRLedgerUpdateMonthID' , 								CONVERT(VARCHAR(MAX), deleted.[PRLedgerUpdateMonthID]) , 								CONVERT(VARCHAR(MAX), inserted.[PRLedgerUpdateMonthID]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedID] = deleted.[SMWorkCompletedID] 
									AND ((inserted.[PRLedgerUpdateMonthID] <> deleted.[PRLedgerUpdateMonthID]) OR (inserted.[PRLedgerUpdateMonthID] IS NULL AND deleted.[PRLedgerUpdateMonthID] IS NOT NULL) OR (inserted.[PRLedgerUpdateMonthID] IS NOT NULL AND deleted.[PRLedgerUpdateMonthID] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([PRPaySeq])
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
								
								SELECT 							'vSMWorkCompleted' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'PRPaySeq' , 								CONVERT(VARCHAR(MAX), deleted.[PRPaySeq]) , 								CONVERT(VARCHAR(MAX), inserted.[PRPaySeq]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedID] = deleted.[SMWorkCompletedID] 
									AND ((inserted.[PRPaySeq] <> deleted.[PRPaySeq]) OR (inserted.[PRPaySeq] IS NULL AND deleted.[PRPaySeq] IS NOT NULL) OR (inserted.[PRPaySeq] IS NOT NULL AND deleted.[PRPaySeq] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([PRPostDate])
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
								
								SELECT 							'vSMWorkCompleted' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'PRPostDate' , 								CONVERT(VARCHAR(MAX), deleted.[PRPostDate]) , 								CONVERT(VARCHAR(MAX), inserted.[PRPostDate]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedID] = deleted.[SMWorkCompletedID] 
									AND ((inserted.[PRPostDate] <> deleted.[PRPostDate]) OR (inserted.[PRPostDate] IS NULL AND deleted.[PRPostDate] IS NOT NULL) OR (inserted.[PRPostDate] IS NOT NULL AND deleted.[PRPostDate] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([PRPostSeq])
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
								
								SELECT 							'vSMWorkCompleted' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'PRPostSeq' , 								CONVERT(VARCHAR(MAX), deleted.[PRPostSeq]) , 								CONVERT(VARCHAR(MAX), inserted.[PRPostSeq]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedID] = deleted.[SMWorkCompletedID] 
									AND ((inserted.[PRPostSeq] <> deleted.[PRPostSeq]) OR (inserted.[PRPostSeq] IS NULL AND deleted.[PRPostSeq] IS NOT NULL) OR (inserted.[PRPostSeq] IS NOT NULL AND deleted.[PRPostSeq] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([Provisional])
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
								
								SELECT 							'vSMWorkCompleted' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'Provisional' , 								CONVERT(VARCHAR(MAX), deleted.[Provisional]) , 								CONVERT(VARCHAR(MAX), inserted.[Provisional]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedID] = deleted.[SMWorkCompletedID] 
									AND ((inserted.[Provisional] <> deleted.[Provisional]) OR (inserted.[Provisional] IS NULL AND deleted.[Provisional] IS NOT NULL) OR (inserted.[Provisional] IS NOT NULL AND deleted.[Provisional] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([ReferenceNo])
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
								
								SELECT 							'vSMWorkCompleted' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'ReferenceNo' , 								CONVERT(VARCHAR(MAX), deleted.[ReferenceNo]) , 								CONVERT(VARCHAR(MAX), inserted.[ReferenceNo]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedID] = deleted.[SMWorkCompletedID] 
									AND ((inserted.[ReferenceNo] <> deleted.[ReferenceNo]) OR (inserted.[ReferenceNo] IS NULL AND deleted.[ReferenceNo] IS NOT NULL) OR (inserted.[ReferenceNo] IS NOT NULL AND deleted.[ReferenceNo] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([RevenueGLEntryID])
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
								
								SELECT 							'vSMWorkCompleted' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'RevenueGLEntryID' , 								CONVERT(VARCHAR(MAX), deleted.[RevenueGLEntryID]) , 								CONVERT(VARCHAR(MAX), inserted.[RevenueGLEntryID]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedID] = deleted.[SMWorkCompletedID] 
									AND ((inserted.[RevenueGLEntryID] <> deleted.[RevenueGLEntryID]) OR (inserted.[RevenueGLEntryID] IS NULL AND deleted.[RevenueGLEntryID] IS NOT NULL) OR (inserted.[RevenueGLEntryID] IS NOT NULL AND deleted.[RevenueGLEntryID] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([RevenueJCWIPGLEntryID])
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
								
								SELECT 							'vSMWorkCompleted' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'RevenueJCWIPGLEntryID' , 								CONVERT(VARCHAR(MAX), deleted.[RevenueJCWIPGLEntryID]) , 								CONVERT(VARCHAR(MAX), inserted.[RevenueJCWIPGLEntryID]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedID] = deleted.[SMWorkCompletedID] 
									AND ((inserted.[RevenueJCWIPGLEntryID] <> deleted.[RevenueJCWIPGLEntryID]) OR (inserted.[RevenueJCWIPGLEntryID] IS NULL AND deleted.[RevenueJCWIPGLEntryID] IS NOT NULL) OR (inserted.[RevenueJCWIPGLEntryID] IS NOT NULL AND deleted.[RevenueJCWIPGLEntryID] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([RevenueSMWIPGLEntryID])
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
								
								SELECT 							'vSMWorkCompleted' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'RevenueSMWIPGLEntryID' , 								CONVERT(VARCHAR(MAX), deleted.[RevenueSMWIPGLEntryID]) , 								CONVERT(VARCHAR(MAX), inserted.[RevenueSMWIPGLEntryID]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedID] = deleted.[SMWorkCompletedID] 
									AND ((inserted.[RevenueSMWIPGLEntryID] <> deleted.[RevenueSMWIPGLEntryID]) OR (inserted.[RevenueSMWIPGLEntryID] IS NULL AND deleted.[RevenueSMWIPGLEntryID] IS NOT NULL) OR (inserted.[RevenueSMWIPGLEntryID] IS NOT NULL AND deleted.[RevenueSMWIPGLEntryID] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

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
								
								SELECT 							'vSMWorkCompleted' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'SMCo' , 								CONVERT(VARCHAR(MAX), deleted.[SMCo]) , 								CONVERT(VARCHAR(MAX), inserted.[SMCo]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedID] = deleted.[SMWorkCompletedID] 
									AND ((inserted.[SMCo] <> deleted.[SMCo]) OR (inserted.[SMCo] IS NULL AND deleted.[SMCo] IS NOT NULL) OR (inserted.[SMCo] IS NOT NULL AND deleted.[SMCo] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([SMWorkCompletedARTLID])
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
								
								SELECT 							'vSMWorkCompleted' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'SMWorkCompletedARTLID' , 								CONVERT(VARCHAR(MAX), deleted.[SMWorkCompletedARTLID]) , 								CONVERT(VARCHAR(MAX), inserted.[SMWorkCompletedARTLID]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedID] = deleted.[SMWorkCompletedID] 
									AND ((inserted.[SMWorkCompletedARTLID] <> deleted.[SMWorkCompletedARTLID]) OR (inserted.[SMWorkCompletedARTLID] IS NULL AND deleted.[SMWorkCompletedARTLID] IS NOT NULL) OR (inserted.[SMWorkCompletedARTLID] IS NOT NULL AND deleted.[SMWorkCompletedARTLID] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([SMWorkCompletedID])
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
								
								SELECT 							'vSMWorkCompleted' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'SMWorkCompletedID' , 								CONVERT(VARCHAR(MAX), deleted.[SMWorkCompletedID]) , 								CONVERT(VARCHAR(MAX), inserted.[SMWorkCompletedID]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedID] = deleted.[SMWorkCompletedID] 
									AND ((inserted.[SMWorkCompletedID] <> deleted.[SMWorkCompletedID]) OR (inserted.[SMWorkCompletedID] IS NULL AND deleted.[SMWorkCompletedID] IS NOT NULL) OR (inserted.[SMWorkCompletedID] IS NOT NULL AND deleted.[SMWorkCompletedID] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([Type])
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
								
								SELECT 							'vSMWorkCompleted' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'Type' , 								CONVERT(VARCHAR(MAX), deleted.[Type]) , 								CONVERT(VARCHAR(MAX), inserted.[Type]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedID] = deleted.[SMWorkCompletedID] 
									AND ((inserted.[Type] <> deleted.[Type]) OR (inserted.[Type] IS NULL AND deleted.[Type] IS NOT NULL) OR (inserted.[Type] IS NOT NULL AND deleted.[Type] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

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
								
								SELECT 							'vSMWorkCompleted' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'UniqueAttchID' , 								CONVERT(VARCHAR(MAX), deleted.[UniqueAttchID]) , 								CONVERT(VARCHAR(MAX), inserted.[UniqueAttchID]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedID] = deleted.[SMWorkCompletedID] 
									AND ((inserted.[UniqueAttchID] <> deleted.[UniqueAttchID]) OR (inserted.[UniqueAttchID] IS NULL AND deleted.[UniqueAttchID] IS NOT NULL) OR (inserted.[UniqueAttchID] IS NOT NULL AND deleted.[UniqueAttchID] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([WorkCompleted])
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
								
								SELECT 							'vSMWorkCompleted' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'WorkCompleted' , 								CONVERT(VARCHAR(MAX), deleted.[WorkCompleted]) , 								CONVERT(VARCHAR(MAX), inserted.[WorkCompleted]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedID] = deleted.[SMWorkCompletedID] 
									AND ((inserted.[WorkCompleted] <> deleted.[WorkCompleted]) OR (inserted.[WorkCompleted] IS NULL AND deleted.[WorkCompleted] IS NOT NULL) OR (inserted.[WorkCompleted] IS NOT NULL AND deleted.[WorkCompleted] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([WorkOrder])
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
								
								SELECT 							'vSMWorkCompleted' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'WorkOrder' , 								CONVERT(VARCHAR(MAX), deleted.[WorkOrder]) , 								CONVERT(VARCHAR(MAX), inserted.[WorkOrder]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedID] = deleted.[SMWorkCompletedID] 
									AND ((inserted.[WorkOrder] <> deleted.[WorkOrder]) OR (inserted.[WorkOrder] IS NULL AND deleted.[WorkOrder] IS NOT NULL) OR (inserted.[WorkOrder] IS NOT NULL AND deleted.[WorkOrder] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 



 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMWorkCompleted_Audit_Update] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMWorkCompleted_Audit_Update]', 'last', 'update', null
GO
ALTER TABLE [dbo].[vSMWorkCompleted] ADD CONSTRAINT [CK_vSMWorkCompleted_NonBillable] CHECK (([NonBillable]='Y' OR [NonBillable]='N'))
GO
ALTER TABLE [dbo].[vSMWorkCompleted] ADD CONSTRAINT [PK_vSMWorkCompleted] PRIMARY KEY CLUSTERED  ([SMWorkCompletedID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMWorkCompleted] ADD CONSTRAINT [IX_vSMWorkCompleted_SMCo_WorkOrder_WorkCompleted] UNIQUE NONCLUSTERED  ([SMCo], [WorkOrder], [WorkCompleted]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMWorkCompleted] ADD CONSTRAINT [IX_vSMWorkCompleted_SMWorkCompletedID_SMCo] UNIQUE NONCLUSTERED  ([SMWorkCompletedID], [SMCo]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMWorkCompleted] ADD CONSTRAINT [IX_vSMWorkCompleted_SMWorkCompletedID_SMCo_WorkOrder_WorkCompleted] UNIQUE NONCLUSTERED  ([SMWorkCompletedID], [SMCo], [WorkOrder], [WorkCompleted]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMWorkCompleted] ADD CONSTRAINT [IX_vSMWorkCompleted_SMWorkCompletedID_Type] UNIQUE NONCLUSTERED  ([SMWorkCompletedID], [Type]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMWorkCompleted] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompleted_vHQDetail] FOREIGN KEY ([CostDetailID]) REFERENCES [dbo].[vHQDetail] ([HQDetailID])
GO
ALTER TABLE [dbo].[vSMWorkCompleted] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompleted_vSMWorkCompletedJCCostEntry] FOREIGN KEY ([JCCostEntryID], [SMWorkCompletedID]) REFERENCES [dbo].[vSMWorkCompletedJCCostEntry] ([JCCostEntryID], [SMWorkCompletedID])
GO

GO

GO
ALTER TABLE [dbo].[vSMWorkCompleted] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompleted_vPRLedgerUpdateMonth] FOREIGN KEY ([PRLedgerUpdateMonthID]) REFERENCES [dbo].[vPRLedgerUpdateMonth] ([PRLedgerUpdateMonthID]) ON DELETE SET NULL
GO
ALTER TABLE [dbo].[vSMWorkCompleted] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompleted_vSMWorkCompletedGLEntryRevenue] FOREIGN KEY ([RevenueGLEntryID], [SMWorkCompletedID]) REFERENCES [dbo].[vSMWorkCompletedGLEntry] ([GLEntryID], [SMWorkCompletedID])
GO
ALTER TABLE [dbo].[vSMWorkCompleted] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompleted_vGLEntryRevenueJCWIP] FOREIGN KEY ([RevenueJCWIPGLEntryID]) REFERENCES [dbo].[vGLEntry] ([GLEntryID])
GO
ALTER TABLE [dbo].[vSMWorkCompleted] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompleted_vSMWorkCompletedGLEntryRevenueSMWIP] FOREIGN KEY ([RevenueSMWIPGLEntryID], [SMWorkCompletedID]) REFERENCES [dbo].[vSMWorkCompletedGLEntry] ([GLEntryID], [SMWorkCompletedID])
GO
ALTER TABLE [dbo].[vSMWorkCompleted] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompleted_vSMWorkCompletedARTL] FOREIGN KEY ([SMWorkCompletedARTLID], [SMWorkCompletedID]) REFERENCES [dbo].[vSMWorkCompletedARTL] ([SMWorkCompletedARTLID], [SMWorkCompletedID])
GO
ALTER TABLE [dbo].[vSMWorkCompleted] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompleted_vSMWorkOrder] FOREIGN KEY ([WorkOrder], [SMCo]) REFERENCES [dbo].[vSMWorkOrder] ([WorkOrder], [SMCo])
GO
