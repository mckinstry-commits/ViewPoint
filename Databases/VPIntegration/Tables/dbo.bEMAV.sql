CREATE TABLE [dbo].[bEMAV]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[AllocCode] [tinyint] NOT NULL,
[RevCode] [dbo].[bRevCode] NOT NULL,
[EMGroup] [dbo].[bGroup] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biEMAV] ON [dbo].[bEMAV] ([EMCo], [AllocCode], [RevCode], [EMGroup]) ON [PRIMARY]
GO