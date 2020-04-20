CREATE TABLE [dbo].[bINCG]
(
[INCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[BatchSeq] [int] NOT NULL,
[OldNew] [tinyint] NOT NULL,
[INTrans] [dbo].[bTrans] NULL,
[MO] [dbo].[bMO] NOT NULL,
[MOItem] [dbo].[bItem] NOT NULL,
[Loc] [dbo].[bLoc] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[ConfirmDate] [dbo].[bDate] NOT NULL,
[Amt] [dbo].[bDollar] NOT NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biINCG] ON [dbo].[bINCG] ([INCo], [Mth], [BatchId], [GLCo], [GLAcct], [BatchSeq], [OldNew]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
