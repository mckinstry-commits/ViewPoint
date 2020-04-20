CREATE TABLE [dbo].[bIMBC]
(
[ImportId] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[RecordCount] [numeric] (18, 0) NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biIMBC] ON [dbo].[bIMBC] ([ImportId], [Co], [Mth], [BatchId]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
