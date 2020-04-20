USE [Viewpoint]
GO

/****** Object:  Table [mers].[ProphecyLog]    Script Date: 8/11/2016 10:53:50 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [mers].[ProphecyLog](
	[KeyID] [bigint] IDENTITY(1,1) NOT NULL,
	[VPUserName] [dbo].[bVPUserName] NULL,
	[DateTime] [datetime] NULL,
	[Version] [varchar](6) NULL,
	[JCCo] [dbo].[bCompany] NULL,
	[Contract] [dbo].[bContract] NULL,
	[Job] [dbo].[bJob] NULL,
	[Mth] [dbo].[bMonth] NULL,
	[BatchId] [dbo].[bBatchID] NULL,
	[Action] [varchar](20) NULL,
	[Details] [varchar](50) NULL,
	[ErrorText] [varchar](255) NULL,
 CONSTRAINT [PK_ProphecyLog] PRIMARY KEY CLUSTERED 
(
	[KeyID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


