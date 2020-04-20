CREATE TABLE [dbo].[vSMWorkCompletedARTL]
(
[SMWorkCompletedARTLID] [bigint] NOT NULL IDENTITY(1, 1),
[ARCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[ARTrans] [dbo].[bTrans] NOT NULL,
[ARLine] [smallint] NOT NULL,
[ApplyMth] [dbo].[bMonth] NOT NULL,
[ApplyTrans] [dbo].[bTrans] NOT NULL,
[ApplyLine] [smallint] NOT NULL,
[SMWorkCompletedID] [bigint] NOT NULL,
[SMInvoiceID] [bigint] NOT NULL
) ON [PRIMARY]
ALTER TABLE [dbo].[vSMWorkCompletedARTL] WITH NOCHECK ADD
CONSTRAINT [FK_vSMWorkCompletedARTL_bARTL] FOREIGN KEY ([ARCo], [ApplyMth], [ApplyTrans], [ApplyLine], [Mth], [ARTrans], [ARLine]) REFERENCES [dbo].[bARTL] ([ARCo], [ApplyMth], [ApplyTrans], [ApplyLine], [Mth], [ARTrans], [ARLine])
GO
ALTER TABLE [dbo].[vSMWorkCompletedARTL] ADD CONSTRAINT [PK_vSMWorkCompletedARTL] PRIMARY KEY CLUSTERED  ([SMWorkCompletedARTLID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMWorkCompletedARTL] ADD CONSTRAINT [IX_vSMWorkCompletedARTL_ARCo_Mth_ARTrans_ARLine] UNIQUE NONCLUSTERED  ([ARCo], [Mth], [ARTrans], [ARLine]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMWorkCompletedARTL] ADD CONSTRAINT [IX_vSMWorkCompletedARTL_SMWorkCompletedARTLID_SMWorkCompletedID] UNIQUE NONCLUSTERED  ([SMWorkCompletedARTLID], [SMWorkCompletedID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMWorkCompletedARTL] ADD CONSTRAINT [IX_vSMWorkCompletedARTL_SMWorkCompletedID_ARCo_Mth_ARTrans_ARLine] UNIQUE NONCLUSTERED  ([SMWorkCompletedID], [ARCo], [Mth], [ARTrans], [ARLine]) ON [PRIMARY]
GO

ALTER TABLE [dbo].[vSMWorkCompletedARTL] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompletedARTL_vSMInvoice] FOREIGN KEY ([SMInvoiceID], [ARCo], [ApplyMth], [ApplyTrans]) REFERENCES [dbo].[vSMInvoice] ([SMInvoiceID], [ARCo], [ARPostedMth], [ARTrans])
GO
ALTER TABLE [dbo].[vSMWorkCompletedARTL] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompletedARTL_vSMWorkCompleted] FOREIGN KEY ([SMWorkCompletedID]) REFERENCES [dbo].[vSMWorkCompleted] ([SMWorkCompletedID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vSMWorkCompletedARTL] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompletedARTL_vSMWorkCompletedARTL] FOREIGN KEY ([SMWorkCompletedID], [ARCo], [ApplyMth], [ApplyTrans], [ApplyLine]) REFERENCES [dbo].[vSMWorkCompletedARTL] ([SMWorkCompletedID], [ARCo], [Mth], [ARTrans], [ARLine])
GO
