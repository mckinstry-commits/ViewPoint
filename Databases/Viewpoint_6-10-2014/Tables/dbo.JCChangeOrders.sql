CREATE TABLE [dbo].[JCChangeOrders]
(
[JCCo] [int] NOT NULL,
[Job] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[ACO] [varchar] (8000) COLLATE Latin1_General_BIN NULL,
[ACOItem] [varchar] (8000) COLLATE Latin1_General_BIN NULL,
[ApprovalDate] [nvarchar] (max) COLLATE Latin1_General_BIN NULL,
[REVISIONAMT] [decimal] (29, 4) NULL,
[HeaderDesc1] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[DetailDesc] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[CHGORDERTYPE] [int] NOT NULL,
[Phase] [int] NULL,
[CostType] [int] NULL,
[RECORDTYPE] [int] NOT NULL,
[CONTRACTNO] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Item] [varchar] (8000) COLLATE Latin1_General_BIN NULL,
[DESCRIPTION1] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[REVISIONHRS] [int] NOT NULL,
[ESTQTY] [decimal] (29, 4) NULL,
[CHGORDERQTY] [int] NOT NULL,
[RevenueCOAmt] [decimal] (29, 4) NULL,
[RevenueCOUnits] [int] NOT NULL,
[UM] [varchar] (2) COLLATE Latin1_General_BIN NOT NULL,
[udCGCTable] [varchar] (6) COLLATE Latin1_General_BIN NOT NULL,
[udCGCTableID] [bigint] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
