CREATE TABLE [dbo].[vSMDetailTransaction]
(
[SMDetailTransactionID] [bigint] NOT NULL IDENTITY(1, 1),
[IsReversing] [bit] NOT NULL,
[Posted] [bit] NOT NULL,
[HQBatchLineID] [bigint] NULL,
[HQBatchDistributionID] [bigint] NULL,
[PRLedgerUpdateDistributionID] [bigint] NULL,
[HQDetailID] [bigint] NULL,
[SMAgreementID] [bigint] NULL,
[SMAgreementBillingScheduleID] [bigint] NULL,
[SMWorkCompletedID] [bigint] NULL,
[SMWorkOrderScopeID] [int] NULL,
[SMWorkOrderID] [int] NULL,
[LineType] [tinyint] NULL,
[TransactionType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[SourceCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NULL,
[PRMth] [dbo].[bMonth] NULL,
[GLInterfaceLevel] [tinyint] NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAccount] [dbo].[bGLAcct] NOT NULL,
[Amount] [dbo].[bDollar] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMDetailTransaction] ADD CONSTRAINT [PK_vSMDetailTransaction] PRIMARY KEY CLUSTERED  ([SMDetailTransactionID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMDetailTransaction] WITH NOCHECK ADD CONSTRAINT [FK_vSMDetailTransaction_vHQBatchDistribution] FOREIGN KEY ([HQBatchDistributionID], [Posted]) REFERENCES [dbo].[vHQBatchDistribution] ([HQBatchDistributionID], [Posted]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vSMDetailTransaction] WITH NOCHECK ADD CONSTRAINT [FK_vSMDetailTransaction_vHQBatchLine] FOREIGN KEY ([HQBatchLineID]) REFERENCES [dbo].[vHQBatchLine] ([HQBatchLineID])
GO
ALTER TABLE [dbo].[vSMDetailTransaction] WITH NOCHECK ADD CONSTRAINT [FK_vSMDetailTransaction_vHQDetail] FOREIGN KEY ([HQDetailID]) REFERENCES [dbo].[vHQDetail] ([HQDetailID]) ON DELETE SET NULL
GO
ALTER TABLE [dbo].[vSMDetailTransaction] WITH NOCHECK ADD CONSTRAINT [FK_vSMDetailTransaction_vPRLedgerUpdateDistribution] FOREIGN KEY ([PRLedgerUpdateDistributionID], [Posted]) REFERENCES [dbo].[vPRLedgerUpdateDistribution] ([PRLedgerUpdateDistributionID], [Posted]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vSMDetailTransaction] WITH NOCHECK ADD CONSTRAINT [FK_vSMDetailTransaction_vSMAgreementBillingSchedule] FOREIGN KEY ([SMAgreementBillingScheduleID]) REFERENCES [dbo].[vSMAgreementBillingSchedule] ([SMAgreementBillingScheduleID]) ON DELETE SET NULL
GO

ALTER TABLE [dbo].[vSMDetailTransaction] WITH NOCHECK ADD CONSTRAINT [FK_vSMDetailTransaction_vSMWorkCompleted] FOREIGN KEY ([SMWorkCompletedID]) REFERENCES [dbo].[vSMWorkCompleted] ([SMWorkCompletedID]) ON DELETE SET NULL
GO
ALTER TABLE [dbo].[vSMDetailTransaction] WITH NOCHECK ADD CONSTRAINT [FK_vSMDetailTransaction_vSMWorkOrder] FOREIGN KEY ([SMWorkOrderID]) REFERENCES [dbo].[vSMWorkOrder] ([SMWorkOrderID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vSMDetailTransaction] WITH NOCHECK ADD CONSTRAINT [FK_vSMDetailTransaction_vSMWorkOrderScope] FOREIGN KEY ([SMWorkOrderScopeID]) REFERENCES [dbo].[vSMWorkOrderScope] ([SMWorkOrderScopeID]) ON DELETE SET NULL
GO
