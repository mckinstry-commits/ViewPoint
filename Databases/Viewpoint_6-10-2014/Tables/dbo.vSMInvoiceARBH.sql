CREATE TABLE [dbo].[vSMInvoiceARBH]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[SMCo] [dbo].[bCompany] NOT NULL,
[Invoice] [int] NOT NULL,
[IsReversing] [bit] NOT NULL,
[VoidInvoice] [bit] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMInvoiceARBH] ADD CONSTRAINT [PK_vSMInvoiceARBH] PRIMARY KEY CLUSTERED  ([SMCo], [Invoice], [IsReversing], [Co], [Mth], [BatchId]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMInvoiceARBH] WITH NOCHECK ADD CONSTRAINT [FK_vSMInvoiceARBH_bARBH] FOREIGN KEY ([Co], [Mth], [BatchId], [BatchSeq]) REFERENCES [dbo].[bARBH] ([Co], [Mth], [BatchId], [BatchSeq]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vSMInvoiceARBH] WITH NOCHECK ADD CONSTRAINT [FK_vSMInvoiceARBH_vSMInvoice] FOREIGN KEY ([SMCo], [Invoice]) REFERENCES [dbo].[vSMInvoice] ([SMCo], [Invoice])
GO
ALTER TABLE [dbo].[vSMInvoiceARBH] NOCHECK CONSTRAINT [FK_vSMInvoiceARBH_bARBH]
GO
ALTER TABLE [dbo].[vSMInvoiceARBH] NOCHECK CONSTRAINT [FK_vSMInvoiceARBH_vSMInvoice]
GO
