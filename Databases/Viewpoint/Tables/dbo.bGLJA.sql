CREATE TABLE [dbo].[bGLJA]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[Jrnl] [dbo].[bJrnl] NOT NULL,
[GLRef] [dbo].[bGLRef] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[BatchSeq] [int] NOT NULL,
[OldNew] [tinyint] NOT NULL,
[EntryId] [smallint] NOT NULL,
[Seq] [tinyint] NOT NULL,
[Description] [dbo].[bTransDesc] NULL,
[Amount] [dbo].[bDollar] NOT NULL,
[ActDate] [dbo].[bDate] NOT NULL,
[InterCo] [dbo].[bCompany] NULL,
[Source] [dbo].[bSource] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biGLJA] ON [dbo].[bGLJA] ([Co], [Mth], [BatchId], [Jrnl], [GLRef], [GLAcct], [BatchSeq], [OldNew], [InterCo]) ON [PRIMARY]
GO
