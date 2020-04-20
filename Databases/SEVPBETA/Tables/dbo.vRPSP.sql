CREATE TABLE [dbo].[vRPSP]
(
[VPUserName] [dbo].[bVPUserName] NOT NULL,
[ReportID] [int] NOT NULL,
[ParameterName] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[Value] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[LastAccessed] [datetime] NULL
) ON [PRIMARY]
GO
