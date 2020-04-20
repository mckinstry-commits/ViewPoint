CREATE TABLE [dbo].[bMSIG]
(
[MSCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[BatchSeq] [int] NOT NULL,
[MSInv] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[CustGroup] [dbo].[bGroup] NOT NULL,
[Customer] [dbo].[bCustomer] NOT NULL,
[CustJob] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[CustPO] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[Description] [dbo].[bDesc] NULL,
[InvDate] [dbo].[bDate] NOT NULL,
[Amount] [dbo].[bDollar] NOT NULL,
[GLTrans] [dbo].[bTrans] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biMSIG] ON [dbo].[bMSIG] ([MSCo], [Mth], [BatchId], [GLCo], [GLAcct], [BatchSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
