CREATE TABLE [dbo].[bJCXA]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[Department] [dbo].[bDept] NULL,
[Contract] [dbo].[bContract] NULL,
[ActDate] [dbo].[bDate] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Amount] [dbo].[bDollar] NOT NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biJCXA] ON [dbo].[bJCXA] ([Co], [Mth], [BatchId], [GLCo], [GLAcct], [Department], [Contract]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
