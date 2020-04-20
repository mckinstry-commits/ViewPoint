CREATE TABLE [dbo].[vRPTP]
(
[ReportID] [int] NOT NULL,
[ViewName] [varchar] (60) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [viRPTP] ON [dbo].[vRPTP] ([ReportID], [ViewName]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
