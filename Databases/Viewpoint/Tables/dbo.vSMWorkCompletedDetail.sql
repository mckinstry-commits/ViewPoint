CREATE TABLE [dbo].[vSMWorkCompletedDetail]
(
[SMWorkCompletedDetailID] [bigint] NOT NULL IDENTITY(1, 1),
[SMWorkCompletedID] [bigint] NOT NULL,
[IsSession] [bit] NOT NULL,
[SMCo] [dbo].[bCompany] NOT NULL,
[WorkOrder] [int] NOT NULL,
[WorkCompleted] [int] NOT NULL,
[Scope] [int] NOT NULL,
[Date] [dbo].[bDate] NOT NULL,
[Agreement] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[Revision] [int] NULL,
[Coverage] [char] (1) COLLATE Latin1_General_BIN NULL,
[Technician] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[ServiceSite] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[ServiceItem] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[SMCostType] [smallint] NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[JCCostType] [dbo].[bJCCType] NULL,
[PriceRate] [dbo].[bUnitCost] NULL,
[PriceTotal] [dbo].[bDollar] NULL,
[TaxType] [tinyint] NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[TaxBasis] [dbo].[bDollar] NULL,
[TaxAmount] [dbo].[bDollar] NULL,
[NoCharge] [dbo].[bYN] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[CostAccount] [dbo].[bGLAcct] NOT NULL,
[CostWIPAccount] [dbo].[bGLAcct] NOT NULL,
[RevenueAccount] [dbo].[bGLAcct] NOT NULL,
[RevenueWIPAccount] [dbo].[bGLAcct] NOT NULL,
[SMInvoiceID] [bigint] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[vSMWorkCompletedDetail] WITH NOCHECK ADD
CONSTRAINT [FK_vSMWorkCompletedDetail_bGLCO] FOREIGN KEY ([GLCo]) REFERENCES [dbo].[bGLCO] ([GLCo])
ALTER TABLE [dbo].[vSMWorkCompletedDetail] WITH NOCHECK ADD
CONSTRAINT [FK_vSMWorkCompletedDetail_bGLAC_CostAccount] FOREIGN KEY ([GLCo], [CostAccount]) REFERENCES [dbo].[bGLAC] ([GLCo], [GLAcct])
ALTER TABLE [dbo].[vSMWorkCompletedDetail] WITH NOCHECK ADD
CONSTRAINT [FK_vSMWorkCompletedDetail_bGLAC_CostWIPAccount] FOREIGN KEY ([GLCo], [CostWIPAccount]) REFERENCES [dbo].[bGLAC] ([GLCo], [GLAcct])
ALTER TABLE [dbo].[vSMWorkCompletedDetail] WITH NOCHECK ADD
CONSTRAINT [FK_vSMWorkCompletedDetail_bGLAC_RevenueAccount] FOREIGN KEY ([GLCo], [RevenueAccount]) REFERENCES [dbo].[bGLAC] ([GLCo], [GLAcct])
ALTER TABLE [dbo].[vSMWorkCompletedDetail] WITH NOCHECK ADD
CONSTRAINT [FK_vSMWorkCompletedDetail_bGLAC_RevenueWIPAccount] FOREIGN KEY ([GLCo], [RevenueWIPAccount]) REFERENCES [dbo].[bGLAC] ([GLCo], [GLAcct])
ALTER TABLE [dbo].[vSMWorkCompletedDetail] WITH NOCHECK ADD
CONSTRAINT [FK_vSMWorkCompletedDetail_bJCCT] FOREIGN KEY ([PhaseGroup], [JCCostType]) REFERENCES [dbo].[bJCCT] ([PhaseGroup], [CostType])
ALTER TABLE [dbo].[vSMWorkCompletedDetail] WITH NOCHECK ADD
CONSTRAINT [FK_vSMWorkCompletedDetail_bHQTX] FOREIGN KEY ([TaxGroup], [TaxCode]) REFERENCES [dbo].[bHQTX] ([TaxGroup], [TaxCode])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 4/14/11
-- Description:	Will automatically revert a work completed record if the backup record exists
-- =============================================
CREATE TRIGGER [dbo].[vtSMWorkCompletedDetaild]
   ON  [dbo].[vSMWorkCompletedDetail]
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    UPDATE dbo.vSMWorkCompletedDetail
    SET IsSession = 0
    FROM dbo.vSMWorkCompletedDetail
		INNER JOIN DELETED CurrentRecordsDeleted ON vSMWorkCompletedDetail.SMWorkCompletedID = CurrentRecordsDeleted.SMWorkCompletedID AND CurrentRecordsDeleted.IsSession = 0
	WHERE vSMWorkCompletedDetail.IsSession = 1
END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 4/14/11
-- Description:	Prevents users from changing records that shouldn't be updated.
-- =============================================
CREATE TRIGGER [dbo].[vtSMWorkCompletedDetailiu]
   ON  [dbo].[vSMWorkCompletedDetail]
   AFTER INSERT, UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	IF dbo.vfOnlyColumnUpdated(COLUMNS_UPDATED(), 'vSMWorkCompletedDetail', 'UniqueAttchID') <> 1
		AND dbo.vfOnlyColumnUpdated(COLUMNS_UPDATED(), 'vSMWorkCompletedDetail', 'SMInvoiceID') <> 1
    BEGIN 
    
		/*IF EXISTS(SELECT 1
		FROM INSERTED
			LEFT JOIN dbo.vSMWorkCompletedSessionInvoice ON INSERTED.SMWorkCompletedID = vSMWorkCompletedSessionInvoice.SMWorkCompletedID
		WHERE IsSession <> CASE WHEN vSMWorkCompletedSessionInvoice.SMWorkCompletedID IS NULL THEN 0 ELSE 1 END)
		BEGIN
			RAISERROR('Inserting/updating record that doesn''t match session state', 11, -1)
			ROLLBACK TRANSACTION
		END*/
		
		IF EXISTS(SELECT 1
			FROM INSERTED
				INNER JOIN dbo.vSMWorkCompletedDetail ON INSERTED.SMWorkCompletedID = vSMWorkCompletedDetail.SMWorkCompletedID --Get both the backup and current work completed records because one may be in the invoice while the other is not.
				INNER JOIN dbo.vSMInvoiceSession ON	vSMWorkCompletedDetail.SMInvoiceID = vSMInvoiceSession.SMInvoiceID
				INNER JOIN dbo.vSMSession WITH (NOLOCK) ON vSMInvoiceSession.SMSessionID = vSMSession.SMSessionID --It is important to read from vSMSession with nolock since someone may have a lock on the record in a transaction with their username being set
				LEFT JOIN dbo.vSMMyTimesheetLink ON vSMMyTimesheetLink.SMWorkCompletedID = INSERTED.SMWorkCompletedID
				LEFT JOIN dbo.vSMBC ON vSMBC.SMWorkCompletedID = INSERTED.SMWorkCompletedID
			WHERE (vSMSession.UserName IS NULL OR vSMSession.UserName <> SUSER_NAME()) 
					AND ISNULL(vSMMyTimesheetLink.UpdateInProgress,0)=0
					AND ISNULL(vSMBC.UpdateInProgress,0)=0
					)
		BEGIN
			RAISERROR('This record is being edited in a session', 11, -1)
			ROLLBACK TRANSACTION
		END
		
		/*IF EXISTS(SELECT 1
			FROM INSERTED
				INNER JOIN dbo.vSMWorkCompletedSessionInvoice ON INSERTED.SMWorkCompletedID = vSMWorkCompletedSessionInvoice.SMWorkCompletedID
				INNER JOIN dbo.vSMSession WITH (NOLOCK) ON vSMWorkCompletedSessionInvoice.SMSessionID = vSMSession.SMSessionID
			WHERE vSMSession.UserName IS NULL OR vSMSession.UserName <> SUSER_NAME())
		BEGIN
			RAISERROR('This record is being edited in a session', 11, -1)
			ROLLBACK TRANSACTION
		END*/
		
    END  

END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMWorkCompletedDetail_Audit_Delete ON dbo.vSMWorkCompletedDetail
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'Agreement' , 
								CONVERT(VARCHAR(MAX), deleted.[Agreement]) , 								NULL , 
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'CostAccount' , 
								CONVERT(VARCHAR(MAX), deleted.[CostAccount]) , 								NULL , 
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'CostWIPAccount' , 
								CONVERT(VARCHAR(MAX), deleted.[CostWIPAccount]) , 								NULL , 
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'Coverage' , 
								CONVERT(VARCHAR(MAX), deleted.[Coverage]) , 								NULL , 
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'Date' , 
								CONVERT(VARCHAR(MAX), deleted.[Date]) , 								NULL , 
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'GLCo' , 
								CONVERT(VARCHAR(MAX), deleted.[GLCo]) , 								NULL , 
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'IsSession' , 
								CONVERT(VARCHAR(MAX), deleted.[IsSession]) , 								NULL , 
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'JCCostType' , 
								CONVERT(VARCHAR(MAX), deleted.[JCCostType]) , 								NULL , 
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'NoCharge' , 
								CONVERT(VARCHAR(MAX), deleted.[NoCharge]) , 								NULL , 
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'PhaseGroup' , 
								CONVERT(VARCHAR(MAX), deleted.[PhaseGroup]) , 								NULL , 
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'PriceRate' , 
								CONVERT(VARCHAR(MAX), deleted.[PriceRate]) , 								NULL , 
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'PriceTotal' , 
								CONVERT(VARCHAR(MAX), deleted.[PriceTotal]) , 								NULL , 
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'RevenueAccount' , 
								CONVERT(VARCHAR(MAX), deleted.[RevenueAccount]) , 								NULL , 
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'RevenueWIPAccount' , 
								CONVERT(VARCHAR(MAX), deleted.[RevenueWIPAccount]) , 								NULL , 
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'Revision' , 
								CONVERT(VARCHAR(MAX), deleted.[Revision]) , 								NULL , 
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'SMCostType' , 
								CONVERT(VARCHAR(MAX), deleted.[SMCostType]) , 								NULL , 
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'SMInvoiceID' , 
								CONVERT(VARCHAR(MAX), deleted.[SMInvoiceID]) , 								NULL , 
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'SMWorkCompletedDetailID' , 
								CONVERT(VARCHAR(MAX), deleted.[SMWorkCompletedDetailID]) , 								NULL , 
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'Scope' , 
								CONVERT(VARCHAR(MAX), deleted.[Scope]) , 								NULL , 
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'ServiceItem' , 
								CONVERT(VARCHAR(MAX), deleted.[ServiceItem]) , 								NULL , 
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'ServiceSite' , 
								CONVERT(VARCHAR(MAX), deleted.[ServiceSite]) , 								NULL , 
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'TaxAmount' , 
								CONVERT(VARCHAR(MAX), deleted.[TaxAmount]) , 								NULL , 
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'TaxBasis' , 
								CONVERT(VARCHAR(MAX), deleted.[TaxBasis]) , 								NULL , 
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'TaxCode' , 
								CONVERT(VARCHAR(MAX), deleted.[TaxCode]) , 								NULL , 
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'TaxGroup' , 
								CONVERT(VARCHAR(MAX), deleted.[TaxGroup]) , 								NULL , 
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'TaxType' , 
								CONVERT(VARCHAR(MAX), deleted.[TaxType]) , 								NULL , 
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'Technician' , 
								CONVERT(VARCHAR(MAX), deleted.[Technician]) , 								NULL , 
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
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

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMWorkCompletedDetail_Audit_Delete] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMWorkCompletedDetail_Audit_Delete]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMWorkCompletedDetail_Audit_Insert ON dbo.vSMWorkCompletedDetail
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Agreement' , 
								NULL , 
								Agreement , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the CostAccount column
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'CostAccount' , 
								NULL , 
								CostAccount , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the CostWIPAccount column
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'CostWIPAccount' , 
								NULL , 
								CostWIPAccount , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the Coverage column
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Coverage' , 
								NULL , 
								Coverage , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Date' , 
								NULL , 
								Date , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the GLCo column
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'GLCo' , 
								NULL , 
								GLCo , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the IsSession column
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'IsSession' , 
								NULL , 
								IsSession , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the JCCostType column
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'JCCostType' , 
								NULL , 
								JCCostType , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the NoCharge column
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'NoCharge' , 
								NULL , 
								NoCharge , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the PhaseGroup column
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'PhaseGroup' , 
								NULL , 
								PhaseGroup , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the PriceRate column
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'PriceRate' , 
								NULL , 
								PriceRate , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the PriceTotal column
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'PriceTotal' , 
								NULL , 
								PriceTotal , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the RevenueAccount column
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'RevenueAccount' , 
								NULL , 
								RevenueAccount , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the RevenueWIPAccount column
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'RevenueWIPAccount' , 
								NULL , 
								RevenueWIPAccount , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Revision' , 
								NULL , 
								Revision , 
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'SMCostType' , 
								NULL , 
								SMCostType , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'SMInvoiceID' , 
								NULL , 
								SMInvoiceID , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the SMWorkCompletedDetailID column
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'SMWorkCompletedDetailID' , 
								NULL , 
								SMWorkCompletedDetailID , 
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
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

-- log additions to the Scope column
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Scope' , 
								NULL , 
								Scope , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the ServiceItem column
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'ServiceItem' , 
								NULL , 
								ServiceItem , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'ServiceSite' , 
								NULL , 
								ServiceSite , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'TaxAmount' , 
								NULL , 
								TaxAmount , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'TaxBasis' , 
								NULL , 
								TaxBasis , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'TaxCode' , 
								NULL , 
								TaxCode , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'TaxGroup' , 
								NULL , 
								TaxGroup , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'TaxType' , 
								NULL , 
								TaxType , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the Technician column
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Technician' , 
								NULL , 
								Technician , 
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
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
								'vSMWorkCompletedDetail' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
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

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMWorkCompletedDetail_Audit_Insert] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMWorkCompletedDetail_Audit_Insert]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMWorkCompletedDetail_Audit_Update ON dbo.vSMWorkCompletedDetail
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
								
								SELECT 							'vSMWorkCompletedDetail' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'Agreement' , 								CONVERT(VARCHAR(MAX), deleted.[Agreement]) , 								CONVERT(VARCHAR(MAX), inserted.[Agreement]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedDetailID] = deleted.[SMWorkCompletedDetailID] 
									AND ((inserted.[Agreement] <> deleted.[Agreement]) OR (inserted.[Agreement] IS NULL AND deleted.[Agreement] IS NOT NULL) OR (inserted.[Agreement] IS NOT NULL AND deleted.[Agreement] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([CostAccount])
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
								
								SELECT 							'vSMWorkCompletedDetail' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'CostAccount' , 								CONVERT(VARCHAR(MAX), deleted.[CostAccount]) , 								CONVERT(VARCHAR(MAX), inserted.[CostAccount]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedDetailID] = deleted.[SMWorkCompletedDetailID] 
									AND ((inserted.[CostAccount] <> deleted.[CostAccount]) OR (inserted.[CostAccount] IS NULL AND deleted.[CostAccount] IS NOT NULL) OR (inserted.[CostAccount] IS NOT NULL AND deleted.[CostAccount] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([CostWIPAccount])
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
								
								SELECT 							'vSMWorkCompletedDetail' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'CostWIPAccount' , 								CONVERT(VARCHAR(MAX), deleted.[CostWIPAccount]) , 								CONVERT(VARCHAR(MAX), inserted.[CostWIPAccount]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedDetailID] = deleted.[SMWorkCompletedDetailID] 
									AND ((inserted.[CostWIPAccount] <> deleted.[CostWIPAccount]) OR (inserted.[CostWIPAccount] IS NULL AND deleted.[CostWIPAccount] IS NOT NULL) OR (inserted.[CostWIPAccount] IS NOT NULL AND deleted.[CostWIPAccount] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([Coverage])
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
								
								SELECT 							'vSMWorkCompletedDetail' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'Coverage' , 								CONVERT(VARCHAR(MAX), deleted.[Coverage]) , 								CONVERT(VARCHAR(MAX), inserted.[Coverage]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedDetailID] = deleted.[SMWorkCompletedDetailID] 
									AND ((inserted.[Coverage] <> deleted.[Coverage]) OR (inserted.[Coverage] IS NULL AND deleted.[Coverage] IS NOT NULL) OR (inserted.[Coverage] IS NOT NULL AND deleted.[Coverage] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

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
								
								SELECT 							'vSMWorkCompletedDetail' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'Date' , 								CONVERT(VARCHAR(MAX), deleted.[Date]) , 								CONVERT(VARCHAR(MAX), inserted.[Date]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedDetailID] = deleted.[SMWorkCompletedDetailID] 
									AND ((inserted.[Date] <> deleted.[Date]) OR (inserted.[Date] IS NULL AND deleted.[Date] IS NOT NULL) OR (inserted.[Date] IS NOT NULL AND deleted.[Date] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([GLCo])
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
								
								SELECT 							'vSMWorkCompletedDetail' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'GLCo' , 								CONVERT(VARCHAR(MAX), deleted.[GLCo]) , 								CONVERT(VARCHAR(MAX), inserted.[GLCo]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedDetailID] = deleted.[SMWorkCompletedDetailID] 
									AND ((inserted.[GLCo] <> deleted.[GLCo]) OR (inserted.[GLCo] IS NULL AND deleted.[GLCo] IS NOT NULL) OR (inserted.[GLCo] IS NOT NULL AND deleted.[GLCo] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([IsSession])
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
								
								SELECT 							'vSMWorkCompletedDetail' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'IsSession' , 								CONVERT(VARCHAR(MAX), deleted.[IsSession]) , 								CONVERT(VARCHAR(MAX), inserted.[IsSession]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedDetailID] = deleted.[SMWorkCompletedDetailID] 
									AND ((inserted.[IsSession] <> deleted.[IsSession]) OR (inserted.[IsSession] IS NULL AND deleted.[IsSession] IS NOT NULL) OR (inserted.[IsSession] IS NOT NULL AND deleted.[IsSession] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([JCCostType])
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
								
								SELECT 							'vSMWorkCompletedDetail' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'JCCostType' , 								CONVERT(VARCHAR(MAX), deleted.[JCCostType]) , 								CONVERT(VARCHAR(MAX), inserted.[JCCostType]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedDetailID] = deleted.[SMWorkCompletedDetailID] 
									AND ((inserted.[JCCostType] <> deleted.[JCCostType]) OR (inserted.[JCCostType] IS NULL AND deleted.[JCCostType] IS NOT NULL) OR (inserted.[JCCostType] IS NOT NULL AND deleted.[JCCostType] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([NoCharge])
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
								
								SELECT 							'vSMWorkCompletedDetail' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'NoCharge' , 								CONVERT(VARCHAR(MAX), deleted.[NoCharge]) , 								CONVERT(VARCHAR(MAX), inserted.[NoCharge]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedDetailID] = deleted.[SMWorkCompletedDetailID] 
									AND ((inserted.[NoCharge] <> deleted.[NoCharge]) OR (inserted.[NoCharge] IS NULL AND deleted.[NoCharge] IS NOT NULL) OR (inserted.[NoCharge] IS NOT NULL AND deleted.[NoCharge] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([PhaseGroup])
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
								
								SELECT 							'vSMWorkCompletedDetail' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'PhaseGroup' , 								CONVERT(VARCHAR(MAX), deleted.[PhaseGroup]) , 								CONVERT(VARCHAR(MAX), inserted.[PhaseGroup]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedDetailID] = deleted.[SMWorkCompletedDetailID] 
									AND ((inserted.[PhaseGroup] <> deleted.[PhaseGroup]) OR (inserted.[PhaseGroup] IS NULL AND deleted.[PhaseGroup] IS NOT NULL) OR (inserted.[PhaseGroup] IS NOT NULL AND deleted.[PhaseGroup] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([PriceRate])
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
								
								SELECT 							'vSMWorkCompletedDetail' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'PriceRate' , 								CONVERT(VARCHAR(MAX), deleted.[PriceRate]) , 								CONVERT(VARCHAR(MAX), inserted.[PriceRate]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedDetailID] = deleted.[SMWorkCompletedDetailID] 
									AND ((inserted.[PriceRate] <> deleted.[PriceRate]) OR (inserted.[PriceRate] IS NULL AND deleted.[PriceRate] IS NOT NULL) OR (inserted.[PriceRate] IS NOT NULL AND deleted.[PriceRate] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([PriceTotal])
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
								
								SELECT 							'vSMWorkCompletedDetail' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'PriceTotal' , 								CONVERT(VARCHAR(MAX), deleted.[PriceTotal]) , 								CONVERT(VARCHAR(MAX), inserted.[PriceTotal]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedDetailID] = deleted.[SMWorkCompletedDetailID] 
									AND ((inserted.[PriceTotal] <> deleted.[PriceTotal]) OR (inserted.[PriceTotal] IS NULL AND deleted.[PriceTotal] IS NOT NULL) OR (inserted.[PriceTotal] IS NOT NULL AND deleted.[PriceTotal] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([RevenueAccount])
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
								
								SELECT 							'vSMWorkCompletedDetail' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'RevenueAccount' , 								CONVERT(VARCHAR(MAX), deleted.[RevenueAccount]) , 								CONVERT(VARCHAR(MAX), inserted.[RevenueAccount]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedDetailID] = deleted.[SMWorkCompletedDetailID] 
									AND ((inserted.[RevenueAccount] <> deleted.[RevenueAccount]) OR (inserted.[RevenueAccount] IS NULL AND deleted.[RevenueAccount] IS NOT NULL) OR (inserted.[RevenueAccount] IS NOT NULL AND deleted.[RevenueAccount] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([RevenueWIPAccount])
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
								
								SELECT 							'vSMWorkCompletedDetail' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'RevenueWIPAccount' , 								CONVERT(VARCHAR(MAX), deleted.[RevenueWIPAccount]) , 								CONVERT(VARCHAR(MAX), inserted.[RevenueWIPAccount]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedDetailID] = deleted.[SMWorkCompletedDetailID] 
									AND ((inserted.[RevenueWIPAccount] <> deleted.[RevenueWIPAccount]) OR (inserted.[RevenueWIPAccount] IS NULL AND deleted.[RevenueWIPAccount] IS NOT NULL) OR (inserted.[RevenueWIPAccount] IS NOT NULL AND deleted.[RevenueWIPAccount] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

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
								
								SELECT 							'vSMWorkCompletedDetail' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'Revision' , 								CONVERT(VARCHAR(MAX), deleted.[Revision]) , 								CONVERT(VARCHAR(MAX), inserted.[Revision]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedDetailID] = deleted.[SMWorkCompletedDetailID] 
									AND ((inserted.[Revision] <> deleted.[Revision]) OR (inserted.[Revision] IS NULL AND deleted.[Revision] IS NOT NULL) OR (inserted.[Revision] IS NOT NULL AND deleted.[Revision] IS NULL))
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
								
								SELECT 							'vSMWorkCompletedDetail' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'SMCo' , 								CONVERT(VARCHAR(MAX), deleted.[SMCo]) , 								CONVERT(VARCHAR(MAX), inserted.[SMCo]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedDetailID] = deleted.[SMWorkCompletedDetailID] 
									AND ((inserted.[SMCo] <> deleted.[SMCo]) OR (inserted.[SMCo] IS NULL AND deleted.[SMCo] IS NOT NULL) OR (inserted.[SMCo] IS NOT NULL AND deleted.[SMCo] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

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
								
								SELECT 							'vSMWorkCompletedDetail' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'SMCostType' , 								CONVERT(VARCHAR(MAX), deleted.[SMCostType]) , 								CONVERT(VARCHAR(MAX), inserted.[SMCostType]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedDetailID] = deleted.[SMWorkCompletedDetailID] 
									AND ((inserted.[SMCostType] <> deleted.[SMCostType]) OR (inserted.[SMCostType] IS NULL AND deleted.[SMCostType] IS NOT NULL) OR (inserted.[SMCostType] IS NOT NULL AND deleted.[SMCostType] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

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
								
								SELECT 							'vSMWorkCompletedDetail' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'SMInvoiceID' , 								CONVERT(VARCHAR(MAX), deleted.[SMInvoiceID]) , 								CONVERT(VARCHAR(MAX), inserted.[SMInvoiceID]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedDetailID] = deleted.[SMWorkCompletedDetailID] 
									AND ((inserted.[SMInvoiceID] <> deleted.[SMInvoiceID]) OR (inserted.[SMInvoiceID] IS NULL AND deleted.[SMInvoiceID] IS NOT NULL) OR (inserted.[SMInvoiceID] IS NOT NULL AND deleted.[SMInvoiceID] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([SMWorkCompletedDetailID])
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
								
								SELECT 							'vSMWorkCompletedDetail' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'SMWorkCompletedDetailID' , 								CONVERT(VARCHAR(MAX), deleted.[SMWorkCompletedDetailID]) , 								CONVERT(VARCHAR(MAX), inserted.[SMWorkCompletedDetailID]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedDetailID] = deleted.[SMWorkCompletedDetailID] 
									AND ((inserted.[SMWorkCompletedDetailID] <> deleted.[SMWorkCompletedDetailID]) OR (inserted.[SMWorkCompletedDetailID] IS NULL AND deleted.[SMWorkCompletedDetailID] IS NOT NULL) OR (inserted.[SMWorkCompletedDetailID] IS NOT NULL AND deleted.[SMWorkCompletedDetailID] IS NULL))
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
								
								SELECT 							'vSMWorkCompletedDetail' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'SMWorkCompletedID' , 								CONVERT(VARCHAR(MAX), deleted.[SMWorkCompletedID]) , 								CONVERT(VARCHAR(MAX), inserted.[SMWorkCompletedID]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedDetailID] = deleted.[SMWorkCompletedDetailID] 
									AND ((inserted.[SMWorkCompletedID] <> deleted.[SMWorkCompletedID]) OR (inserted.[SMWorkCompletedID] IS NULL AND deleted.[SMWorkCompletedID] IS NOT NULL) OR (inserted.[SMWorkCompletedID] IS NOT NULL AND deleted.[SMWorkCompletedID] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([Scope])
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
								
								SELECT 							'vSMWorkCompletedDetail' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'Scope' , 								CONVERT(VARCHAR(MAX), deleted.[Scope]) , 								CONVERT(VARCHAR(MAX), inserted.[Scope]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedDetailID] = deleted.[SMWorkCompletedDetailID] 
									AND ((inserted.[Scope] <> deleted.[Scope]) OR (inserted.[Scope] IS NULL AND deleted.[Scope] IS NOT NULL) OR (inserted.[Scope] IS NOT NULL AND deleted.[Scope] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([ServiceItem])
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
								
								SELECT 							'vSMWorkCompletedDetail' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'ServiceItem' , 								CONVERT(VARCHAR(MAX), deleted.[ServiceItem]) , 								CONVERT(VARCHAR(MAX), inserted.[ServiceItem]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedDetailID] = deleted.[SMWorkCompletedDetailID] 
									AND ((inserted.[ServiceItem] <> deleted.[ServiceItem]) OR (inserted.[ServiceItem] IS NULL AND deleted.[ServiceItem] IS NOT NULL) OR (inserted.[ServiceItem] IS NOT NULL AND deleted.[ServiceItem] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

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
								
								SELECT 							'vSMWorkCompletedDetail' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'ServiceSite' , 								CONVERT(VARCHAR(MAX), deleted.[ServiceSite]) , 								CONVERT(VARCHAR(MAX), inserted.[ServiceSite]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedDetailID] = deleted.[SMWorkCompletedDetailID] 
									AND ((inserted.[ServiceSite] <> deleted.[ServiceSite]) OR (inserted.[ServiceSite] IS NULL AND deleted.[ServiceSite] IS NOT NULL) OR (inserted.[ServiceSite] IS NOT NULL AND deleted.[ServiceSite] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

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
								
								SELECT 							'vSMWorkCompletedDetail' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'TaxAmount' , 								CONVERT(VARCHAR(MAX), deleted.[TaxAmount]) , 								CONVERT(VARCHAR(MAX), inserted.[TaxAmount]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedDetailID] = deleted.[SMWorkCompletedDetailID] 
									AND ((inserted.[TaxAmount] <> deleted.[TaxAmount]) OR (inserted.[TaxAmount] IS NULL AND deleted.[TaxAmount] IS NOT NULL) OR (inserted.[TaxAmount] IS NOT NULL AND deleted.[TaxAmount] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

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
								
								SELECT 							'vSMWorkCompletedDetail' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'TaxBasis' , 								CONVERT(VARCHAR(MAX), deleted.[TaxBasis]) , 								CONVERT(VARCHAR(MAX), inserted.[TaxBasis]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedDetailID] = deleted.[SMWorkCompletedDetailID] 
									AND ((inserted.[TaxBasis] <> deleted.[TaxBasis]) OR (inserted.[TaxBasis] IS NULL AND deleted.[TaxBasis] IS NOT NULL) OR (inserted.[TaxBasis] IS NOT NULL AND deleted.[TaxBasis] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

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
								
								SELECT 							'vSMWorkCompletedDetail' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'TaxCode' , 								CONVERT(VARCHAR(MAX), deleted.[TaxCode]) , 								CONVERT(VARCHAR(MAX), inserted.[TaxCode]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedDetailID] = deleted.[SMWorkCompletedDetailID] 
									AND ((inserted.[TaxCode] <> deleted.[TaxCode]) OR (inserted.[TaxCode] IS NULL AND deleted.[TaxCode] IS NOT NULL) OR (inserted.[TaxCode] IS NOT NULL AND deleted.[TaxCode] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

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
								
								SELECT 							'vSMWorkCompletedDetail' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'TaxGroup' , 								CONVERT(VARCHAR(MAX), deleted.[TaxGroup]) , 								CONVERT(VARCHAR(MAX), inserted.[TaxGroup]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedDetailID] = deleted.[SMWorkCompletedDetailID] 
									AND ((inserted.[TaxGroup] <> deleted.[TaxGroup]) OR (inserted.[TaxGroup] IS NULL AND deleted.[TaxGroup] IS NOT NULL) OR (inserted.[TaxGroup] IS NOT NULL AND deleted.[TaxGroup] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

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
								
								SELECT 							'vSMWorkCompletedDetail' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'TaxType' , 								CONVERT(VARCHAR(MAX), deleted.[TaxType]) , 								CONVERT(VARCHAR(MAX), inserted.[TaxType]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedDetailID] = deleted.[SMWorkCompletedDetailID] 
									AND ((inserted.[TaxType] <> deleted.[TaxType]) OR (inserted.[TaxType] IS NULL AND deleted.[TaxType] IS NOT NULL) OR (inserted.[TaxType] IS NOT NULL AND deleted.[TaxType] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([Technician])
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
								
								SELECT 							'vSMWorkCompletedDetail' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'Technician' , 								CONVERT(VARCHAR(MAX), deleted.[Technician]) , 								CONVERT(VARCHAR(MAX), inserted.[Technician]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedDetailID] = deleted.[SMWorkCompletedDetailID] 
									AND ((inserted.[Technician] <> deleted.[Technician]) OR (inserted.[Technician] IS NULL AND deleted.[Technician] IS NOT NULL) OR (inserted.[Technician] IS NOT NULL AND deleted.[Technician] IS NULL))
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
								
								SELECT 							'vSMWorkCompletedDetail' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'WorkCompleted' , 								CONVERT(VARCHAR(MAX), deleted.[WorkCompleted]) , 								CONVERT(VARCHAR(MAX), inserted.[WorkCompleted]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedDetailID] = deleted.[SMWorkCompletedDetailID] 
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
								
								SELECT 							'vSMWorkCompletedDetail' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'WorkOrder' , 								CONVERT(VARCHAR(MAX), deleted.[WorkOrder]) , 								CONVERT(VARCHAR(MAX), inserted.[WorkOrder]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedDetailID] = deleted.[SMWorkCompletedDetailID] 
									AND ((inserted.[WorkOrder] <> deleted.[WorkOrder]) OR (inserted.[WorkOrder] IS NULL AND deleted.[WorkOrder] IS NOT NULL) OR (inserted.[WorkOrder] IS NOT NULL AND deleted.[WorkOrder] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 



 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMWorkCompletedDetail_Audit_Update] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMWorkCompletedDetail_Audit_Update]', 'last', 'update', null
GO
ALTER TABLE [dbo].[vSMWorkCompletedDetail] ADD CONSTRAINT [PK_vSMWorkCompletedDetail] PRIMARY KEY CLUSTERED  ([SMWorkCompletedDetailID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMWorkCompletedDetail] ADD CONSTRAINT [IX_vSMWorkCompletedDetail_SMWorkCompletedID_IsSession] UNIQUE NONCLUSTERED  ([SMWorkCompletedID], [IsSession]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMWorkCompletedDetail] ADD CONSTRAINT [IX_vSMWorkCompletedDetail_WorkOrder_WorkCompleted_SMCo_IsSession] UNIQUE NONCLUSTERED  ([WorkOrder], [WorkCompleted], [SMCo], [IsSession]) ON [PRIMARY]
GO

ALTER TABLE [dbo].[vSMWorkCompletedDetail] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompletedDetail_vSMServiceItems] FOREIGN KEY ([SMCo], [ServiceSite], [ServiceItem]) REFERENCES [dbo].[vSMServiceItems] ([SMCo], [ServiceSite], [ServiceItem])
GO
ALTER TABLE [dbo].[vSMWorkCompletedDetail] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompletedDetail_vSMCostType] FOREIGN KEY ([SMCo], [SMCostType]) REFERENCES [dbo].[vSMCostType] ([SMCo], [SMCostType])
GO
ALTER TABLE [dbo].[vSMWorkCompletedDetail] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompletedDetail_vSMTechnician] FOREIGN KEY ([SMCo], [Technician]) REFERENCES [dbo].[vSMTechnician] ([SMCo], [Technician])
GO
ALTER TABLE [dbo].[vSMWorkCompletedDetail] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompletedDetail_vSMWorkOrderScope] FOREIGN KEY ([SMCo], [WorkOrder], [Scope]) REFERENCES [dbo].[vSMWorkOrderScope] ([SMCo], [WorkOrder], [Scope])
GO
ALTER TABLE [dbo].[vSMWorkCompletedDetail] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompletedDetail_vSMWorkOrder] FOREIGN KEY ([SMCo], [WorkOrder], [ServiceSite]) REFERENCES [dbo].[vSMWorkOrder] ([SMCo], [WorkOrder], [ServiceSite])
GO
ALTER TABLE [dbo].[vSMWorkCompletedDetail] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompletedDetail_vSMInvoice] FOREIGN KEY ([SMInvoiceID]) REFERENCES [dbo].[vSMInvoice] ([SMInvoiceID])
GO
ALTER TABLE [dbo].[vSMWorkCompletedDetail] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompletedDetail_vSMWorkCompleted] FOREIGN KEY ([SMWorkCompletedID], [SMCo], [WorkOrder], [WorkCompleted]) REFERENCES [dbo].[vSMWorkCompleted] ([SMWorkCompletedID], [SMCo], [WorkOrder], [WorkCompleted]) ON DELETE CASCADE
GO
