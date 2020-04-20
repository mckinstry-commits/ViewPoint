CREATE TABLE [dbo].[bGLDA]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[Jrnl] [dbo].[bJrnl] NOT NULL,
[GLRef] [dbo].[bGLRef] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[BatchSeq] [int] NOT NULL,
[OldNew] [tinyint] NOT NULL,
[GLTrans] [dbo].[bTrans] NULL,
[Source] [dbo].[bSource] NOT NULL,
[ActDate] [dbo].[bDate] NOT NULL,
[Description] [dbo].[bTransDesc] NULL,
[Amount] [dbo].[bDollar] NOT NULL,
[InterCo] [dbo].[bCompany] NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biGLDA] ON [dbo].[bGLDA] ([Co], [Mth], [BatchId], [Jrnl], [GLRef], [GLAcct], [BatchSeq], [OldNew], [InterCo]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO

EXEC sp_bindrule N'[dbo].[brTrueFalse]', N'[dbo].[bGLDA].[OldNew]'
GO
