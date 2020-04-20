CREATE TABLE [dbo].[bEMJC]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[JCCo] [dbo].[bCompany] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[PhaseGroup] [dbo].[bGroup] NOT NULL,
[Phase] [dbo].[bPhase] NOT NULL,
[JCCType] [dbo].[bJCCType] NOT NULL,
[BatchSeq] [int] NOT NULL,
[OldNew] [tinyint] NOT NULL,
[EMTrans] [dbo].[bTrans] NULL,
[Equipment] [dbo].[bEquip] NULL,
[TransDesc] [dbo].[bItemDesc] NULL,
[ActualDate] [dbo].[bDate] NOT NULL,
[EMGroup] [dbo].[bGroup] NULL,
[RevCode] [dbo].[bRevCode] NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[PRCo] [dbo].[bCompany] NULL,
[PREmployee] [dbo].[bEmployee] NULL,
[WorkUM] [dbo].[bUM] NULL,
[WorkUnits] [numeric] (12, 3) NULL,
[TimeUM] [dbo].[bUM] NOT NULL,
[TimeUnits] [numeric] (12, 3) NULL,
[UnitCost] [numeric] (16, 5) NOT NULL CONSTRAINT [DF_bEMJC_UnitCost] DEFAULT ((0)),
[TotalCost] [numeric] (12, 2) NOT NULL CONSTRAINT [DF_bEMJC_TotalCost] DEFAULT ((0)),
[PRCrew] [varchar] (10) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biEMJC] ON [dbo].[bEMJC] ([EMCo], [Mth], [BatchId], [JCCo], [Job], [PhaseGroup], [Phase], [JCCType], [BatchSeq], [OldNew]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bEMJC] WITH NOCHECK ADD CONSTRAINT [FK_bEMJC_bEMCO_EMCo] FOREIGN KEY ([EMCo]) REFERENCES [dbo].[bEMCO] ([EMCo])
GO
ALTER TABLE [dbo].[bEMJC] WITH NOCHECK ADD CONSTRAINT [FK_bEMJC_bEMEM_Equipment] FOREIGN KEY ([EMCo], [Equipment]) REFERENCES [dbo].[bEMEM] ([EMCo], [Equipment]) ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[bEMJC] WITH NOCHECK ADD CONSTRAINT [FK_bEMJC_bHQGP_EMGroup] FOREIGN KEY ([EMGroup]) REFERENCES [dbo].[bHQGP] ([Grp])
GO
ALTER TABLE [dbo].[bEMJC] WITH NOCHECK ADD CONSTRAINT [FK_bEMJC_bEMRC_RevCode] FOREIGN KEY ([EMGroup], [RevCode]) REFERENCES [dbo].[bEMRC] ([EMGroup], [RevCode])
GO
ALTER TABLE [dbo].[bEMJC] NOCHECK CONSTRAINT [FK_bEMJC_bEMCO_EMCo]
GO
ALTER TABLE [dbo].[bEMJC] NOCHECK CONSTRAINT [FK_bEMJC_bEMEM_Equipment]
GO
ALTER TABLE [dbo].[bEMJC] NOCHECK CONSTRAINT [FK_bEMJC_bHQGP_EMGroup]
GO
ALTER TABLE [dbo].[bEMJC] NOCHECK CONSTRAINT [FK_bEMJC_bEMRC_RevCode]
GO
