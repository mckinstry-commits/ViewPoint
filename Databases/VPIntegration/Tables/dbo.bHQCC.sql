CREATE TABLE [dbo].[bHQCC]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biHQCC] ON [dbo].[bHQCC] ([Co], [Mth], [BatchId], [GLCo]) ON [PRIMARY]
GO
