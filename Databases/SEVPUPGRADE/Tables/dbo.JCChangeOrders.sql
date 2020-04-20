CREATE TABLE [dbo].[JCChangeOrders]
(
[JCCo] [smallint] NULL,
[Job] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[ACO] [varchar] (8000) COLLATE Latin1_General_BIN NULL,
[ACOItem] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[ApprovalDate] [nvarchar] (max) COLLATE Latin1_General_BIN NULL,
[REVISIONAMT] [decimal] (29, 2) NULL,
[HeaderDesc1] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[DetailDesc] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[CHGORDERTYPE] [varchar] (2) COLLATE Latin1_General_BIN NULL,
[Phase] [dbo].[bPhase] NULL,
[CostType] [tinyint] NULL,
[RECORDTYPE] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[CONTRACTNO] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[Item] [varchar] (16) COLLATE Latin1_General_BIN NULL,
[DESCRIPTION1] [varchar] (40) COLLATE Latin1_General_BIN NULL,
[REVISIONHRS] [decimal] (18, 0) NULL,
[ESTQTY] [decimal] (29, 4) NULL,
[CHGORDERQTY] [decimal] (29, 4) NULL,
[RevenueCOAmt] [decimal] (29, 2) NULL,
[RevenueCOUnits] [decimal] (29, 4) NULL,
[UM] [varchar] (3) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (6) COLLATE Latin1_General_BIN NOT NULL,
[udCGCTableID] [bigint] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
