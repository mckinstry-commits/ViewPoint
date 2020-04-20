CREATE TABLE [dbo].[vReportSettings]
(
[CompanyID] [tinyint] NOT NULL,
[ReportSection] [varchar] (250) COLLATE Latin1_General_BIN NULL,
[FontStyle] [varchar] (250) COLLATE Latin1_General_BIN NULL,
[FontSize] [int] NULL,
[FontColor] [varchar] (250) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vReportSettings] WITH NOCHECK ADD CONSTRAINT [FK_vReportSettings_bHQCO_HQCo] FOREIGN KEY ([CompanyID]) REFERENCES [dbo].[bHQCO] ([HQCo])
GO
ALTER TABLE [dbo].[vReportSettings] NOCHECK CONSTRAINT [FK_vReportSettings_bHQCO_HQCo]
GO
