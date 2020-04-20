CREATE TABLE [dbo].[bJBBM]
(
[JBCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[CustGroup] [dbo].[bGroup] NOT NULL,
[MiscDistCode] [char] (10) COLLATE Latin1_General_BIN NOT NULL,
[BatchSeq] [int] NOT NULL,
[BatchTransType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[ARTrans] [dbo].[bTrans] NULL,
[DistDate] [dbo].[bDate] NULL,
[Description] [dbo].[bDesc] NULL,
[Amount] [dbo].[bDollar] NULL,
[oldDistDate] [dbo].[bDate] NULL,
[oldDescription] [dbo].[bDesc] NULL,
[oldAmount] [dbo].[bDollar] NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biJBBM] ON [dbo].[bJBBM] ([JBCo], [Mth], [BatchId], [CustGroup], [BatchSeq], [MiscDistCode]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
