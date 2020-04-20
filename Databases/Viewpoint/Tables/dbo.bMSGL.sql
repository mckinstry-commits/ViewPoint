CREATE TABLE [dbo].[bMSGL]
(
[MSCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[BatchSeq] [int] NOT NULL,
[HaulLine] [smallint] NOT NULL,
[OldNew] [tinyint] NOT NULL,
[MSTrans] [int] NULL,
[Ticket] [dbo].[bTic] NULL,
[SaleDate] [dbo].[bDate] NOT NULL,
[FromLoc] [dbo].[bLoc] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[SaleType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[CustGroup] [dbo].[bGroup] NULL,
[Customer] [dbo].[bCustomer] NULL,
[CustJob] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[JCCo] [dbo].[bCompany] NULL,
[Job] [dbo].[bJob] NULL,
[INCo] [dbo].[bCompany] NULL,
[ToLoc] [dbo].[bLoc] NULL,
[Amount] [dbo].[bDollar] NOT NULL,
[GLTrans] [dbo].[bTrans] NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biMSGL] ON [dbo].[bMSGL] ([MSCo], [Mth], [BatchId], [GLCo], [GLAcct], [BatchSeq], [HaulLine], [OldNew]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
