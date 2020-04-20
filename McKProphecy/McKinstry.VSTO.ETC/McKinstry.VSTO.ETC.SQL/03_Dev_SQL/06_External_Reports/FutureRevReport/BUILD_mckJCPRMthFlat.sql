USE [Viewpoint]
GO

/****** Object:  Table [dbo].[mckJCPRMthFlat]    Script Date: 6/21/2017 3:52:03 PM ******/
DROP TABLE [dbo].[mckJCPRMthFlat]
GO



USE [Viewpoint]
GO

/****** Object:  Table [dbo].[mckJCPRMthFlat]    Script Date: 6/21/2017 3:59:22 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[mckJCPRMthFlat](
	[JCCo] [dbo].[bCompany] NOT NULL,
	[Contract] [dbo].[bContract] NOT NULL,
	[Department] [dbo].[bDept] NULL,
	[udPRGNumber] [dbo].[bJob] NULL,
	[udPRGDescription] [varchar](250) NULL,
	[EffectMth] [dbo].[bMonth] NULL,
	[PostedMonth] [dbo].[bMonth] NULL,
	[Mth] [dbo].[bMonth] NULL,
	[ProjGMP] [float] NULL,
	[TotalRev] [dbo].[bDollar] NULL,
	[TotalCost] [dbo].[bDollar] NULL,
	[TotalHours] [dbo].[bHrs] NULL,
	[LabCost] [dbo].[bDollar] NULL,
	[MatCost] [dbo].[bDollar] NULL,
	[SubCost] [dbo].[bDollar] NULL,
	[OthCost] [dbo].[bDollar] NULL,
	[EqpCost] [dbo].[bDollar] NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

SET ANSI_PADDING ON
GO


USE [Viewpoint]
GO

/****** Object:  Index [IX_mckJCPRMthFlat]    Script Date: 4/14/2017 1:08:28 PM ******/
CREATE NONCLUSTERED INDEX [IX_mckJCPRMthFlat] ON [dbo].[mckJCPRMthFlat]
(
	[JCCo] ASC,
	[Department] ASC,
	[Contract] ASC,
	[udPRGNumber] ASC,
	[EffectMth] ASC,
	[Mth] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
GO


Grant SELECT ON dbo.mckJCPRMthFlat TO [MCKINSTRY\Viewpoint Users]