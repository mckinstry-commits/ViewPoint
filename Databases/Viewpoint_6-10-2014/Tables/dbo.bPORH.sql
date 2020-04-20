CREATE TABLE [dbo].[bPORH]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[ReceiptUpdate] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPORH_ReceiptUpdate] DEFAULT ('N'),
[GLAccrualAcct] [dbo].[bGLAcct] NULL,
[GLRecExpInterfacelvl] [tinyint] NOT NULL CONSTRAINT [DF_bPORH_GLRecExpInterfacelvl] DEFAULT ((0)),
[GLRecExpSummaryDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[GLRecExpDetailDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[RecJCInterfacelvl] [tinyint] NOT NULL CONSTRAINT [DF_bPORH_RecJCInterfacelvl] DEFAULT ((0)),
[RecEMInterfacelvl] [tinyint] NOT NULL CONSTRAINT [DF_bPORH_RecEMInterfacelvl] DEFAULT ((0)),
[RecINInterfacelvl] [tinyint] NOT NULL CONSTRAINT [DF_bPORH_RecINInterfacelvl] DEFAULT ((0)),
[OldReceiptUpdate] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPORH_OldReceiptUpdate] DEFAULT ('N'),
[OldGLAccrualAcct] [dbo].[bGLAcct] NULL,
[OldGLRecExpInterfacelvl] [tinyint] NOT NULL CONSTRAINT [DF_bPORH_OldGLRecExpInterfacelvl] DEFAULT ((0)),
[OldGLRecExpSummaryDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[OldGLRecExpDetailDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[OldRecJCInterfacelvl] [tinyint] NOT NULL CONSTRAINT [DF_bPORH_OldRecJCInterfacelvl] DEFAULT ((0)),
[OldRecEMInterfacelvl] [tinyint] NOT NULL CONSTRAINT [DF_bPORH_OldRecEMInterfacelvl] DEFAULT ((0)),
[OldRecINInterfacelvl] [tinyint] NOT NULL CONSTRAINT [DF_bPORH_OldRecINInterfacelvl] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPORH] WITH NOCHECK ADD CONSTRAINT [CK_bPORH_OldReceiptUpdate] CHECK (([OldReceiptUpdate]='Y' OR [OldReceiptUpdate]='N'))
GO
ALTER TABLE [dbo].[bPORH] WITH NOCHECK ADD CONSTRAINT [CK_bPORH_ReceiptUpdate] CHECK (([ReceiptUpdate]='Y' OR [ReceiptUpdate]='N'))
GO
CREATE UNIQUE CLUSTERED INDEX [biPORH] ON [dbo].[bPORH] ([Co], [Mth], [BatchId]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
