
USE [Viewpoint]
GO

/****** Object:  Table [dbo].[mckJCPRRevFlat]    Script Date: 6/21/2017 3:31:20 PM ******/
DROP TABLE [dbo].[mckJCPRRevFlat]
GO


USE [Viewpoint]
GO

/****** Object:  Table [dbo].[mckJCPRRevFlat]    Script Date: 6/21/2017 3:29:04 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[mckJCPRRevFlat](
	[JCCo] [dbo].[bCompany] NOT NULL,
	[Department] [dbo].[bDept] NOT NULL,
	[Description] [dbo].[bItemDesc] NULL,
	[JCDept] [dbo].[bDept] NULL,
	[RevType] [varchar](20) NULL,
	[Contract] [dbo].[bContract] NOT NULL,
	[ContractDesc] [dbo].[bItemDesc] NULL,
	[udPRGNumber] [dbo].[bJob] NOT NULL,
	[udPRGDescription] [varchar](250) NULL,
	[EffectMth] [dbo].[bMonth] NOT NULL,
	[POC] [int] NULL,
	[POCName] [varchar](60) NULL,
	[ProjMgr] [int] NULL,
	[ProjMgrName] [varchar](60) NULL,
	[FutureCostTotal] [decimal](18, 2) NULL,
	[RevTotal] [decimal](18, 2) NULL,
	[CostTotal] [decimal](18, 2) NULL,
	[ProjGMP] [float] NULL,
	[FutureRevTotal] [decimal](18, 2) NULL,
	[JTDEarnedRev] [numeric](38, 8) NULL,
	[RemainRev] [numeric](38, 8) NULL,
	[UnburnRev] [decimal](18, 2) NULL,
	[AbsFutureCost] [decimal](18, 2) NULL,
	[AbsFutureRev] [decimal](18, 2) NULL,
	[MarginChange] [float] NULL,
	[MarginChgImpact] [numeric](38, 8) NULL,
	[AdjCurrentMth] [numeric](38, 8) NULL,
	[ConRemRevenue] [numeric](38, 8) NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


SET ANSI_PADDING ON
GO


USE [Viewpoint]
GO

/****** Object:  Index [IX_mckJCPRRevFlat]    Script Date: 4/10/2017 3:25:45 PM ******/
CREATE NONCLUSTERED INDEX [IX_mckJCPRRevFlat] ON [dbo].[mckJCPRRevFlat]
(
	[JCCo] ASC,
	[Department] ASC,
	[Contract] ASC,
	[udPRGNumber] ASC,
	[EffectMth] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
GO


GRANT SELECT ON mckJCPRRevFlat  TO [MCKINSTRY\Viewpoint Users]

