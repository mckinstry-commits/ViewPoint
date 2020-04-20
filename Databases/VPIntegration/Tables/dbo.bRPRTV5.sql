CREATE TABLE [dbo].[bRPRTV5]
(
[Title] [char] (40) COLLATE Latin1_General_BIN NOT NULL,
[FileName] [varchar] (60) COLLATE Latin1_General_BIN NOT NULL,
[Location] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[ReportType] [char] (10) COLLATE Latin1_General_BIN NULL,
[ReportOwner] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[ShowOnMenu] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Custom] [tinyint] NULL,
[Orientation] [tinyint] NOT NULL,
[ReportMemo] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[LeftMargin] [numeric] (4, 2) NULL,
[TopMargin] [numeric] (4, 2) NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[BottomMargin] [numeric] (5, 4) NULL,
[RightMargin] [numeric] (5, 4) NULL,
[ReportDescr] [varchar] (3000) COLLATE Latin1_General_BIN NULL,
[UserNotes] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[Application] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
