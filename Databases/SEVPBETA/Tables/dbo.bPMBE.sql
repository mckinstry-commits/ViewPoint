CREATE TABLE [dbo].[bPMBE]
(
[Co] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[Seq] [int] NOT NULL,
[ErrorText] [varchar] (255) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPMBE] ON [dbo].[bPMBE] ([Co], [Project], [Mth], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
