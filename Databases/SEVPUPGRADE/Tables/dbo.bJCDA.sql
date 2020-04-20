CREATE TABLE [dbo].[bJCDA]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[GLType] [varchar] (3) COLLATE Latin1_General_BIN NULL CONSTRAINT [DF_bJCDA_GLType] DEFAULT ('CST'),
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[BatchSeq] [int] NOT NULL,
[OldNew] [tinyint] NOT NULL,
[CostTrans] [dbo].[bTrans] NULL,
[Job] [dbo].[bJob] NULL,
[Phase] [dbo].[bPhase] NULL,
[CostType] [dbo].[bJCCType] NULL,
[JCTransType] [varchar] (2) COLLATE Latin1_General_BIN NULL,
[ActDate] [dbo].[bDate] NOT NULL,
[Description] [dbo].[bTransDesc] NULL,
[Amount] [dbo].[bDollar] NOT NULL,
[Payee] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[INCo] [dbo].[bCompany] NULL,
[Loc] [dbo].[bLoc] NULL,
[Material] [dbo].[bMatl] NULL,
[Qty] [dbo].[bUnits] NULL,
[Hours] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bJCDA_Hours] DEFAULT ((0)),
[OldHours] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bJCDA_OldHours] DEFAULT ((0))
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biJCDA] ON [dbo].[bJCDA] ([JCCo], [Mth], [BatchId], [GLType], [GLCo], [GLAcct], [BatchSeq], [OldNew], [CostTrans]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
