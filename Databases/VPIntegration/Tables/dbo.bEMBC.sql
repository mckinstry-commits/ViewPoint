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
GO
CREATE UNIQUE CLUSTERED INDEX [biEMBC] ON [dbo].[bEMBC] ([EMCo], [Mth], [BatchId], [BatchSeq], [OldNew], [RevCode], [RevBdownCode]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMBC] ([KeyID]) ON [PRIMARY]
GO
