USE [Viewpoint]
GO

/****** Object:  Table [dbo].[mckJCPBETC]    Script Date: 1/31/2017 12:32:52 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[mckJCPBETC](
	[JCCo] [dbo].[bCompany] NOT NULL,
	[Mth] [dbo].[bMonth] NOT NULL,
	[BatchId] [dbo].[bBatchID] NOT NULL,
	[Job] [dbo].[bJob] NOT NULL,
	[DateTime] [dbo].[bDate] NOT NULL,
	[Phase] [dbo].[bPhase] NOT NULL,
	[CostType] [dbo].[bJCCType] NOT NULL,
	[Hours] [dbo].[bHrs] NULL,
	[Rate] [dbo].[bUnitCost] NULL,
	[Amount] [dbo].[bDollar] NULL,
 CONSTRAINT [PK_mckJCPBETC] PRIMARY KEY CLUSTERED 
(
	[JCCo] ASC,
	[Mth] ASC,
	[BatchId] ASC,
	[Job] ASC,
	[Phase] ASC,
	[CostType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


