CREATE TABLE [dbo].[vSMInvoiceARBH]
(
[SMInvoiceID] [bigint] NOT NULL,
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMInvoiceARBH] ADD CONSTRAINT [PK_vSMInvoiceARBH] PRIMARY KEY CLUSTERED  ([SMInvoiceID], [Co], [Mth], [BatchId], [BatchSeq]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMInvoiceARBH] WITH NOCHECK ADD CONSTRAINT [FK_vSMInvoiceARBH_bARBH] FOREIGN KEY ([Co], [Mth], [BatchId], [BatchSeq]) REFERENCES [dbo].[bARBH] ([Co], [Mth], [BatchId], [BatchSeq]) ON DELETE CASCADE
GO
