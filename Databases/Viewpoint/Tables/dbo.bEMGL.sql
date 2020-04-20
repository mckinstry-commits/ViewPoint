CREATE TABLE [dbo].[bEMGL]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[BatchSeq] [int] NOT NULL,
[OldNew] [tinyint] NOT NULL,
[EMTrans] [dbo].[bTrans] NULL,
[Equipment] [dbo].[bEquip] NULL,
[ActualDate] [dbo].[bDate] NOT NULL,
[TransDesc] [dbo].[bItemDesc] NULL,
[Source] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[EMTransType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[JCCo] [dbo].[bCompany] NULL,
[Job] [dbo].[bJob] NULL,
[EMGroup] [dbo].[bGroup] NULL,
[CostCode] [dbo].[bCostCode] NULL,
[EMCostType] [dbo].[bEMCType] NULL,
[RevCode] [dbo].[bRevCode] NULL,
[RevBdownCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[INCo] [dbo].[bCompany] NULL,
[INLocation] [dbo].[bLoc] NULL,
[MatlGroup] [dbo].[bGroup] NULL,
[Material] [dbo].[bMatl] NULL,
[WorkOrder] [dbo].[bWO] NULL,
[WOItem] [dbo].[bItem] NULL,
[Amount] [dbo].[bDollar] NOT NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biEMGL] ON [dbo].[bEMGL] ([EMCo], [Mth], [BatchId], [GLCo], [GLAcct], [BatchSeq], [OldNew]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
