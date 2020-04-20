CREATE TABLE [dbo].[vDDCustomActionParameters]
(
[ActionId] [int] NOT NULL,
[ParameterID] [int] NOT NULL,
[Name] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[DefaultType] [varchar] (2) COLLATE Latin1_General_BIN NULL,
[DefaultValue] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[KeyID] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [PK_vDDCustomActionParameters] ON [dbo].[vDDCustomActionParameters] ([ActionId], [ParameterID]) ON [PRIMARY]
GO
