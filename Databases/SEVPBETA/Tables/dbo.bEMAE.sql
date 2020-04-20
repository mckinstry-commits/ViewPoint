CREATE TABLE [dbo].[bEMAE]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[AllocCode] [tinyint] NOT NULL,
[Equipment] [dbo].[bEquip] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biEMAE] ON [dbo].[bEMAE] ([EMCo], [AllocCode], [Equipment]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
