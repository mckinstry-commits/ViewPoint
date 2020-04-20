CREATE TABLE [dbo].[bGLRA]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[Jrnl] [dbo].[bJrnl] NOT NULL,
[GLRef] [dbo].[bGLRef] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[BatchSeq] [int] NOT NULL,
[OldNew] [tinyint] NOT NULL,
[OrigMonth] [dbo].[bMonth] NOT NULL,
[OrigGLTrans] [dbo].[bTrans] NOT NULL,
[Description] [dbo].[bTransDesc] NULL,
[Amount] [dbo].[bDollar] NOT NULL,
[ActDate] [dbo].[bDate] NOT NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biGLRA] ON [dbo].[bGLRA] ([Co], [Mth], [BatchId], [Jrnl], [GLRef], [GLAcct], [BatchSeq], [OldNew]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
