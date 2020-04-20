CREATE TABLE [dbo].[bMSAP]
(
[MSCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[PayCode] [dbo].[bPayCode] NOT NULL,
[PayRate] [dbo].[bUnitCost] NOT NULL,
[TransMth] [dbo].[bMonth] NOT NULL,
[MSTrans] [dbo].[bTrans] NOT NULL,
[PayBasis] [dbo].[bUnits] NOT NULL,
[PayTotal] [dbo].[bDollar] NOT NULL,
[DiscOff] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bMSAP_DiscOff] DEFAULT ((0)),
[HaulPayTaxType] [tinyint] NULL,
[HaulPayTaxCode] [dbo].[bTaxCode] NULL,
[HaulPayTaxAmt] [dbo].[bDollar] NULL,
[TaxGroup] [dbo].[bGroup] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biMSAP] ON [dbo].[bMSAP] ([MSCo], [Mth], [BatchId], [BatchSeq], [GLCo], [GLAcct], [PayCode], [PayRate], [TransMth], [MSTrans]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
