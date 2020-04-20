CREATE TABLE [dbo].[OpenRetg]
(
[APCo] [tinyint] NULL,
[APTrans] [int] NULL,
[Vendor] [int] NULL,
[SL] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[SLItem] [int] NULL,
[PO] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[POItem] [int] NULL,
[Job] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Phase] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[JCCType] [tinyint] NULL,
[Remaining] [decimal] (12, 2) NULL,
[udSource] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
