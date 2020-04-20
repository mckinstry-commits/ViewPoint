CREATE TABLE [dbo].[vHQBatchLine]
(
[HQBatchLineID] [bigint] NOT NULL IDENTITY(1, 1),
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[Seq] [int] NULL,
[Line] [smallint] NULL,
[BatchTransType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[HQDetailID] [bigint] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vHQBatchLine] ADD CONSTRAINT [PK_vHQBatchLine] PRIMARY KEY CLUSTERED  ([HQBatchLineID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vHQBatchLine] WITH NOCHECK ADD CONSTRAINT [FK_vHQBatchLine_vHQDetail] FOREIGN KEY ([HQDetailID]) REFERENCES [dbo].[vHQDetail] ([HQDetailID]) ON DELETE SET NULL
GO
