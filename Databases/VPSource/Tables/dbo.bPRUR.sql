CREATE TABLE [dbo].[bPRUR]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[PRGroup] [dbo].[bGroup] NOT NULL,
[PREndDate] [dbo].[bDate] NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[PaySeq] [tinyint] NOT NULL,
[PostSeq] [smallint] NOT NULL,
[Seq] [int] NOT NULL,
[ErrorText] [varchar] (255) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRUR] ON [dbo].[bPRUR] ([PRCo], [PRGroup], [PREndDate], [Employee], [PaySeq], [PostSeq], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
