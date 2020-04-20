CREATE TABLE [dbo].[bEMAT]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[AllocCode] [tinyint] NOT NULL,
[CostType] [dbo].[bEMCType] NOT NULL,
[EMGroup] [dbo].[bGroup] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biEMAT] ON [dbo].[bEMAT] ([EMCo], [AllocCode], [CostType], [EMGroup]) ON [PRIMARY]
GO
