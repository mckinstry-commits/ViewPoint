CREATE TABLE [dbo].[bCMDA]
(
[CMCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[BatchSeq] [int] NOT NULL,
[OldNew] [tinyint] NOT NULL,
[CMTrans] [dbo].[bTrans] NULL,
[CMAcct] [dbo].[bCMAcct] NOT NULL,
[CMTransType] [dbo].[bCMTransType] NOT NULL,
[ActDate] [dbo].[bDate] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Amount] [dbo].[bDollar] NOT NULL,
[CMRef] [dbo].[bCMRef] NULL,
[Payee] [varchar] (20) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bCMDA] ADD CONSTRAINT [PK_bCMDA_CMCo] PRIMARY KEY CLUSTERED  ([CMCo], [Mth], [BatchId], [GLCo], [GLAcct], [BatchSeq], [OldNew]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brCMAcct]', N'[dbo].[bCMDA].[CMAcct]'
GO
