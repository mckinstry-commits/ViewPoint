CREATE TABLE [dbo].[bARBM]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[CustGroup] [dbo].[bGroup] NOT NULL,
[MiscDistCode] [char] (10) COLLATE Latin1_General_BIN NOT NULL,
[BatchSeq] [int] NOT NULL,
[TransType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[ARTrans] [dbo].[bTrans] NULL,
[DistDate] [dbo].[bDate] NULL,
[Description] [dbo].[bDesc] NULL,
[Amount] [dbo].[bDollar] NULL,
[oldDistDate] [dbo].[bDate] NULL,
[oldDescription] [dbo].[bDesc] NULL,
[oldAmount] [dbo].[bDollar] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biARBM] ON [dbo].[bARBM] ([Co], [Mth], [BatchId], [CustGroup], [MiscDistCode], [BatchSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bARBM] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
