USE [MCK_INTEGRATION]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[CompanyMoveMetrics](
	[CompanyMoveMetricsID] [int] IDENTITY(1,1) NOT NULL,
	[ApplicationKey] [varchar](100) NULL,
	[LastNotifyDate] [datetime] NULL,
	[LastNotifyLogFileName] [varchar](200) NULL,
	[Created] [datetime] NULL,
	[Modified] [datetime] NULL,
 CONSTRAINT [PK_CompanyMoveMetrics] PRIMARY KEY CLUSTERED 
(
	[CompanyMoveMetricsID] ASC
)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_ApplicationKey] UNIQUE NONCLUSTERED 
(
	[ApplicationKey] ASC
)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
)

ON [PRIMARY]
GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[CompanyMoveMetrics] ADD  CONSTRAINT [DF_CompanyMoveMetrics_ApplicationKey]  DEFAULT (NULL) FOR [ApplicationKey]
GO

ALTER TABLE [dbo].[CompanyMoveMetrics] ADD  CONSTRAINT [DF_CompanyMoveMetrics_LastNotifyDate]  DEFAULT (NULL) FOR [LastNotifyDate]
GO

ALTER TABLE [dbo].[CompanyMoveMetrics] ADD  CONSTRAINT [DF_CompanyMoveMetrics_LastNotifyLogFileName]  DEFAULT (NULL) FOR [LastNotifyLogFileName]
GO

ALTER TABLE [dbo].[CompanyMoveMetrics] ADD  CONSTRAINT [DF_CompanyMoveMetrics_Created]  DEFAULT (getdate()) FOR [Created]
GO

ALTER TABLE [dbo].[CompanyMoveMetrics] ADD  CONSTRAINT [DF_CompanyMoveMetrics_Modified]  DEFAULT (getdate()) FOR [Modified]
GO