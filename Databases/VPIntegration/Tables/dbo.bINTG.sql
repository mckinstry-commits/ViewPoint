CREATE TABLE [dbo].[bINTG]
(
[INCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[BatchSeq] [int] NOT NULL,
[Loc] [dbo].[bLoc] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[ActDate] [dbo].[bDate] NOT NULL,
[Cost] [dbo].[bDollar] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biINTG] ON [dbo].[bINTG] ([INCo], [Mth], [BatchId], [GLCo], [GLAcct], [BatchSeq], [Loc]) ON [PRIMARY]
GO
