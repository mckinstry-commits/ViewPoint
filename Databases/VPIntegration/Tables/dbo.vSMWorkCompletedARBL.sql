CREATE TABLE [dbo].[vSMWorkCompletedARBL]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[ARLine] [smallint] NULL,
[SMInvoiceID] [bigint] NOT NULL,
[SMWorkCompletedID] [bigint] NOT NULL,
[IsReversing] [bit] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMWorkCompletedARBL] ADD CONSTRAINT [PK_vSMWorkCompletedARBL] PRIMARY KEY CLUSTERED  ([SMWorkCompletedID], [IsReversing]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMWorkCompletedARBL] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompletedARBL_bARBL] FOREIGN KEY ([Co], [Mth], [BatchId], [BatchSeq], [ARLine]) REFERENCES [dbo].[bARBL] ([Co], [Mth], [BatchId], [BatchSeq], [ARLine]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vSMWorkCompletedARBL] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompletedARBL_vSMInvoiceARBH] FOREIGN KEY ([SMInvoiceID], [Co], [Mth], [BatchId], [BatchSeq]) REFERENCES [dbo].[vSMInvoiceARBH] ([SMInvoiceID], [Co], [Mth], [BatchId], [BatchSeq]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vSMWorkCompletedARBL] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompletedARBL_vSMWorkCompleted] FOREIGN KEY ([SMWorkCompletedID]) REFERENCES [dbo].[vSMWorkCompleted] ([SMWorkCompletedID])
GO
