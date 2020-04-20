CREATE TABLE [dbo].[cvLog]
(
[ProcDate] [smalldatetime] NULL,
[ProcName] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[FromCo] [smallint] NULL,
[ToCo] [smallint] NULL,
[RowsConvert] [int] NULL,
[ErrMsg] [varchar] (1000) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
