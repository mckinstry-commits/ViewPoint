CREATE TABLE [dbo].[bARBA]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[BatchSeq] [int] NOT NULL,
[ARLine] [smallint] NOT NULL,
[OldNew] [tinyint] NOT NULL,
[ARTrans] [dbo].[bTrans] NULL,
[ARTransType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[CustGroup] [dbo].[bGroup] NULL,
[Customer] [dbo].[bCustomer] NULL,
[SortName] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[Invoice] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[CheckNo] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Contract] [dbo].[bContract] NULL,
[ContractItem] [dbo].[bContractItem] NULL,
[ActDate] [dbo].[bDate] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Amount] [dbo].[bDollar] NOT NULL,
[Job] [dbo].[bJob] NULL,
[Equipment] [dbo].[bEquip] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biARBA] ON [dbo].[bARBA] ([Co], [Mth], [BatchId], [GLCo], [GLAcct], [BatchSeq], [ARLine], [OldNew]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bARBA].[Amount]'
GO
