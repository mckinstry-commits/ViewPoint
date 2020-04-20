CREATE TABLE [dbo].[bJBJC]
(
[JBCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[JCCo] [dbo].[bCompany] NOT NULL,
[Contract] [dbo].[bContract] NOT NULL,
[BatchSeq] [int] NOT NULL,
[Item] [dbo].[bContractItem] NOT NULL,
[OldNew] [tinyint] NOT NULL,
[ARTrans] [dbo].[bTrans] NULL,
[ARLine] [smallint] NULL,
[Description] [dbo].[bDesc] NULL,
[ActDate] [dbo].[bDate] NULL,
[GLCo] [dbo].[bCompany] NULL,
[GLAcct] [dbo].[bGLAcct] NULL,
[Invoice] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[BilledUnits] [dbo].[bUnits] NULL,
[BilledAmt] [dbo].[bDollar] NULL,
[Retainage] [dbo].[bDollar] NULL,
[BilledTax] [dbo].[bDollar] NULL,
[JBTransType] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bJBJC_JBTransType] DEFAULT ('J')
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biJBJC] ON [dbo].[bJBJC] ([JBCo], [Mth], [BatchId], [JCCo], [Contract], [BatchSeq], [Item], [OldNew], [JBTransType]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
