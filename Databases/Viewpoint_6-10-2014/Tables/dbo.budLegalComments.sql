CREATE TABLE [dbo].[budLegalComments]
(
[Co] [dbo].[bCompany] NOT NULL,
[Comment] [varchar] (8000) COLLATE Latin1_General_BIN NULL,
[Contract] [dbo].[bContract] NOT NULL,
[Date] [dbo].[bDate] NULL,
[LegDoc] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[LegIss] [dbo].[bDesc] NOT NULL,
[Project] [dbo].[bProject] NOT NULL,
[Seq] [int] NOT NULL,
[VPUserName] [dbo].[bVPUserName] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biudLegalComments] ON [dbo].[budLegalComments] ([Co], [Contract], [Project], [LegDoc], [LegIss], [Seq]) ON [PRIMARY]
GO
