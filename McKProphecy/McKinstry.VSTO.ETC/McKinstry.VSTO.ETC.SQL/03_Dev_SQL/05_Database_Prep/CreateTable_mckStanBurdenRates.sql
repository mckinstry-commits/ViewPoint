USE [Viewpoint]
GO

/****** Object:  Table [dbo].[mckStanBurdenRates]    Script Date: 5/18/2017 3:59:29 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[mckStanBurdenRates](
	[EffectiveDate] [datetime] NOT NULL,
	[StaffLabor] [decimal](10, 5) NULL,
	[UnionLabor] [decimal](10, 5) NULL,
	[ShopLabor] [decimal](10, 5) NULL,
	[Notes] [varchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


USE [Viewpoint]
GO

/****** Object:  Index [IX_mckStanBurdenRates]    Script Date: 5/18/2017 3:59:44 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_mckStanBurdenRates] ON [dbo].[mckStanBurdenRates]
(
	[EffectiveDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO


INSERT INTO  mckStanBurdenRates VALUES (SYSDATETIME(),.015,.0145,.01445,'Baseline Testing');