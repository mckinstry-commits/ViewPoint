CREATE TABLE [dbo].[vRPRF]
(
[ReportID] [int] NOT NULL,
[Seq] [smallint] NOT NULL,
[FieldType] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Name] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Description] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ReportText] [varchar] (4000) COLLATE Latin1_General_BIN NULL,
[ReportType] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vRPRF_ReportType] DEFAULT ('Main Report')
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [viRPRF] ON [dbo].[vRPRF] ([ReportID], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
