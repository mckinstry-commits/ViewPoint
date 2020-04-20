CREATE TABLE [dbo].[vRPRQc]
(
[ReportID] [int] NOT NULL,
[DataSetName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[QueryText] [varchar] (max) COLLATE Latin1_General_BIN NOT NULL,
[KeyID] [int] NOT NULL IDENTITY(2, 2)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
