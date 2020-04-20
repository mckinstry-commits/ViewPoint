CREATE TABLE [dbo].[bARAA]
(
[VPUserName] [dbo].[bVPUserName] NOT NULL,
[TransDate] [dbo].[bMonth] NULL,
[Invoice] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[ARCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[ARTrans] [dbo].[bTrans] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biARAA] ON [dbo].[bARAA] ([VPUserName], [ARCo], [Mth], [ARTrans]) ON [PRIMARY]
GO
