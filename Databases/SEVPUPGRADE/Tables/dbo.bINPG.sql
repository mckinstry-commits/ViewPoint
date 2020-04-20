CREATE TABLE [dbo].[bINPG]
(
[INCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[BatchSeq] [int] NOT NULL,
[ProdSeq] [int] NOT NULL,
[Loc] [dbo].[bLoc] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Amount] [dbo].[bDollar] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biINPG] ON [dbo].[bINPG] ([INCo], [Mth], [BatchId], [GLCo], [GLAcct], [BatchSeq], [ProdSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
