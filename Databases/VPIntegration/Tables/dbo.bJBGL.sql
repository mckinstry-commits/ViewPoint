CREATE TABLE [dbo].[bJBGL]
(
[JBCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[BatchSeq] [int] NOT NULL,
[Item] [dbo].[bContractItem] NULL,
[OldNew] [tinyint] NOT NULL,
[ARTrans] [dbo].[bTrans] NULL,
[ARLine] [smallint] NULL,
[CustGroup] [dbo].[bGroup] NULL,
[Customer] [dbo].[bCustomer] NULL,
[SortName] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[Invoice] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Contract] [dbo].[bContract] NULL,
[ActDate] [dbo].[bDate] NULL,
[Description] [dbo].[bDesc] NULL,
[Amount] [dbo].[bDollar] NULL,
[JBTransType] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bJBGL_JBTransType] DEFAULT ('J')
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biJBGL] ON [dbo].[bJBGL] ([JBCo], [Mth], [BatchId], [GLCo], [GLAcct], [BatchSeq], [Item], [OldNew], [JBTransType]) ON [PRIMARY]
GO
