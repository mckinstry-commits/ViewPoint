CREATE TABLE [dbo].[bHQCC]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biHQCC] ON [dbo].[bHQCC] ([Co], [Mth], [BatchId], [GLCo]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
