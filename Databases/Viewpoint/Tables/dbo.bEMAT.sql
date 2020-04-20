CREATE TABLE [dbo].[bEMAT]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[AllocCode] [tinyint] NOT NULL,
[CostType] [dbo].[bEMCType] NOT NULL,
[EMGroup] [dbo].[bGroup] NOT NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biEMAT] ON [dbo].[bEMAT] ([EMCo], [AllocCode], [CostType], [EMGroup]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
