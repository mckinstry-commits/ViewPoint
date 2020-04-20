CREATE TABLE [dbo].[bEMAD]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[AllocCode] [tinyint] NOT NULL,
[Department] [dbo].[bDept] NOT NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biEMAD] ON [dbo].[bEMAD] ([EMCo], [AllocCode], [Department]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
