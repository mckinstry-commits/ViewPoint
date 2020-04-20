CREATE TABLE [dbo].[bMSMG]
(
[MSCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[BatchSeq] [int] NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[MatlVendor] [dbo].[bVendor] NOT NULL,
[APRef] [dbo].[bAPReference] NOT NULL,
[InvDescription] [dbo].[bDesc] NULL,
[InvDate] [dbo].[bDate] NOT NULL,
[APTrans] [dbo].[bTrans] NULL,
[Amount] [dbo].[bDollar] NOT NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biMSMG] ON [dbo].[bMSMG] ([MSCo], [Mth], [BatchId], [GLCo], [GLAcct], [BatchSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
