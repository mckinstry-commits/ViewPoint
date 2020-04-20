CREATE TABLE [dbo].[bPRTS]
(
[UserId] [dbo].[bVPUserName] NOT NULL,
[SendSeq] [int] NOT NULL,
[PRCo] [dbo].[bCompany] NOT NULL,
[BatchMth] [dbo].[bMonth] NOT NULL,
[PRGroup] [dbo].[bCompany] NOT NULL,
[EndDate] [dbo].[bDate] NOT NULL,
[PaySeq] [tinyint] NOT NULL,
[JCCo] [dbo].[bCompany] NULL,
[Job] [dbo].[bJob] NULL,
[ThroughDate] [dbo].[bDate] NULL,
[PRRestrict] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRTS_PRRestrict] DEFAULT ('N'),
[JCRestrict] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRTS_JCRestrict] DEFAULT ('N'),
[EMRestrict] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRTS_EMRestrict] DEFAULT ('N'),
[AbortError] [varchar] (255) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPRTS] WITH NOCHECK ADD CONSTRAINT [CK_bPRTS_EMRestrict] CHECK (([EMRestrict]='Y' OR [EMRestrict]='N'))
GO
ALTER TABLE [dbo].[bPRTS] WITH NOCHECK ADD CONSTRAINT [CK_bPRTS_JCRestrict] CHECK (([JCRestrict]='Y' OR [JCRestrict]='N'))
GO
ALTER TABLE [dbo].[bPRTS] WITH NOCHECK ADD CONSTRAINT [CK_bPRTS_PRRestrict] CHECK (([PRRestrict]='Y' OR [PRRestrict]='N'))
GO
CREATE UNIQUE CLUSTERED INDEX [biPRTS] ON [dbo].[bPRTS] ([UserId], [SendSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
