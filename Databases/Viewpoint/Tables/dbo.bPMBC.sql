CREATE TABLE [dbo].[bPMBC]
(
[Co] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchTable] [varchar] (4) COLLATE Latin1_General_BIN NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchCo] [dbo].[bCompany] NOT NULL,
[SLSeq] [int] NULL,
[SL] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[SLItem] [dbo].[bItem] NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[POItem] [dbo].[bItem] NULL,
[ChangeOrderHeaderBatch] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMBC_ChangeOrderHeaderBatch] DEFAULT ('N')
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPMBC] ON [dbo].[bPMBC] ([Co], [Project], [Mth], [BatchTable], [BatchId], [SLSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
ALTER TABLE [dbo].[bPMBC] ADD CONSTRAINT [CK_bPMBC_ChangeOrderHeaderBatch] CHECK (([ChangeOrderHeaderBatch]='N' OR [ChangeOrderHeaderBatch]='Y'))
GO
