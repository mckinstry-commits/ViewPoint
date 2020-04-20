CREATE TABLE [dbo].[bHQTC]
(
[TableName] [char] (20) COLLATE Latin1_General_BIN NOT NULL,
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[LastTrans] [dbo].[bTrans] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biHQTC] ON [dbo].[bHQTC] ([TableName], [Co], [Mth]) ON [PRIMARY]
GO
