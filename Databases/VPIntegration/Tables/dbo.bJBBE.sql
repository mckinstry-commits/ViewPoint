CREATE TABLE [dbo].[bJBBE]
(
[JBCo] [dbo].[bCompany] NOT NULL,
[BillMonth] [dbo].[bMonth] NOT NULL,
[BillNumber] [int] NOT NULL,
[BillError] [int] NOT NULL,
[ErrorDesc] [varchar] (255) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biJBBE] ON [dbo].[bJBBE] ([JBCo], [BillMonth], [BillNumber], [BillError]) ON [PRIMARY]
GO
