CREATE TABLE [dbo].[vRPPL]
(
[ReportID] [int] NOT NULL,
[ParameterName] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Lookup] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[LookupParams] [varchar] (256) COLLATE Latin1_General_BIN NULL,
[LoadSeq] [tinyint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [viRPPL] ON [dbo].[vRPPL] ([ReportID], [ParameterName], [Lookup]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
