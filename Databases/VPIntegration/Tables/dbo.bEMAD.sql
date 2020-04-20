CREATE TABLE [dbo].[bEMAD]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[AllocCode] [tinyint] NOT NULL,
[Department] [dbo].[bDept] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biEMAD] ON [dbo].[bEMAD] ([EMCo], [AllocCode], [Department]) ON [PRIMARY]
GO
