CREATE TABLE [dbo].[bJCIA]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[BatchSeq] [int] NOT NULL,
[OldNew] [tinyint] NOT NULL,
[ItemTrans] [dbo].[bTrans] NULL,
[Contract] [dbo].[bContract] NULL,
[Item] [dbo].[bContractItem] NULL,
[JCTransType] [varchar] (2) COLLATE Latin1_General_BIN NULL,
[ActDate] [smalldatetime] NULL,
[Description] [dbo].[bTransDesc] NULL,
[Amount] [dbo].[bDollar] NULL CONSTRAINT [DF_bJCIA_Amount] DEFAULT ((0))
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biJCIA] ON [dbo].[bJCIA] ([JCCo], [Mth], [BatchId], [GLCo], [GLAcct], [BatchSeq], [OldNew]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
