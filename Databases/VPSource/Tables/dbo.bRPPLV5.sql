CREATE TABLE [dbo].[bRPPLV5]
(
[Title] [char] (40) COLLATE Latin1_General_BIN NOT NULL,
[ParameterName] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[LookupSeq] [smallint] NOT NULL,
[Lookup] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[LookupDesc] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Custom] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Active] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[ReportParams] [varchar] (255) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
