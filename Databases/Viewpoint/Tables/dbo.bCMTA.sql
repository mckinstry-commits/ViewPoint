CREATE TABLE [dbo].[bCMTA]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[BatchSeq] [int] NOT NULL,
[OldNew] [tinyint] NOT NULL,
[CMTransferTrans] [dbo].[bTrans] NULL,
[FromCMCo] [dbo].[bCompany] NOT NULL,
[FromCMAcct] [dbo].[bCMAcct] NOT NULL,
[FromCMTrans] [dbo].[bTrans] NULL,
[ToCMCo] [dbo].[bCompany] NOT NULL,
[ToCMAcct] [dbo].[bCMAcct] NOT NULL,
[ToCMTrans] [dbo].[bTrans] NULL,
[ActDate] [dbo].[bDate] NOT NULL,
[CMRef] [dbo].[bCMRef] NULL,
[Amount] [dbo].[bDollar] NOT NULL,
[Description] [dbo].[bDesc] NULL
) ON [PRIMARY]
ALTER TABLE [dbo].[bCMTA] ADD 
CONSTRAINT [PK_bCMTA] PRIMARY KEY CLUSTERED  ([Co], [Mth], [BatchId], [GLCo], [GLAcct], [BatchSeq], [OldNew]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO

EXEC sp_bindrule N'[dbo].[brCMAcct]', N'[dbo].[bCMTA].[FromCMAcct]'
GO
EXEC sp_bindrule N'[dbo].[brCMAcct]', N'[dbo].[bCMTA].[ToCMAcct]'
GO
