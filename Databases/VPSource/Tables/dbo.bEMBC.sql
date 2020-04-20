CREATE TABLE [dbo].[bEMBC]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[OldNew] [tinyint] NOT NULL,
[EMTrans] [dbo].[bTrans] NULL,
[EMGroup] [dbo].[bGroup] NOT NULL,
[Equipment] [dbo].[bEquip] NOT NULL,
[RevBdownCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[RevCode] [dbo].[bRevCode] NOT NULL,
[GLCo] [dbo].[bCompany] NULL,
[Account] [dbo].[bGLAcct] NULL,
[BdownRate] [dbo].[bDollar] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
ALTER TABLE [dbo].[bEMBC] ADD
CONSTRAINT [FK_bEMBC_bEMEM_Equipment] FOREIGN KEY ([EMCo], [Equipment]) REFERENCES [dbo].[bEMEM] ([EMCo], [Equipment])
ALTER TABLE [dbo].[bEMBC] ADD
CONSTRAINT [FK_bEMBC_bHQGP_EMGroup] FOREIGN KEY ([EMGroup]) REFERENCES [dbo].[bHQGP] ([Grp])
ALTER TABLE [dbo].[bEMBC] ADD
CONSTRAINT [FK_bEMBC_bEMRT_RevBdownCode] FOREIGN KEY ([EMGroup], [RevBdownCode]) REFERENCES [dbo].[bEMRT] ([EMGroup], [RevBdownCode])
ALTER TABLE [dbo].[bEMBC] ADD
CONSTRAINT [FK_bEMBC_bEMRC_RevCode] FOREIGN KEY ([EMGroup], [RevCode]) REFERENCES [dbo].[bEMRC] ([EMGroup], [RevCode])
GO
CREATE UNIQUE CLUSTERED INDEX [biEMBC] ON [dbo].[bEMBC] ([EMCo], [Mth], [BatchId], [BatchSeq], [OldNew], [RevCode], [RevBdownCode]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMBC] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
