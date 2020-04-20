CREATE TABLE [dbo].[bMSIL]
(
[MSCo] [dbo].[bCompany] NOT NULL,
[MSInv] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[MSTrans] [dbo].[bTrans] NOT NULL,
[CustJob] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[CustPO] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[SaleDate] [dbo].[bDate] NULL,
[FromLoc] [dbo].[bLoc] NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[UnitPrice] [dbo].[bUnitCost] NOT NULL,
[Ticket] [dbo].[bTic] NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biMSIL] ON [dbo].[bMSIL] ([MSCo], [MSInv], [MSTrans]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
