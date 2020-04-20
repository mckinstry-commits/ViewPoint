CREATE TABLE [dbo].[bIMPR]
(
[ImportId] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Co] [dbo].[bCompany] NOT NULL,
[PRGroup] [dbo].[bGroup] NULL,
[PREndDate] [dbo].[bDate] NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [IX_bIMPR_ImportIDCoPRGroupPREndDate] ON [dbo].[bIMPR] ([ImportId], [Co], [PRGroup], [PREndDate]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
