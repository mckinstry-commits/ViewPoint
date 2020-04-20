CREATE TABLE [dbo].[vDDFormButtonParametersCustom]
(
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[ButtonID] [int] NOT NULL,
[ParameterID] [int] NOT NULL,
[Name] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[DefaultType] [varchar] (2) COLLATE Latin1_General_BIN NOT NULL,
[DefaultValue] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[KeyID] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [bivDDFormButtonParametersCustom] ON [dbo].[vDDFormButtonParametersCustom] ([Form], [ButtonID], [ParameterID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biKeyID] ON [dbo].[vDDFormButtonParametersCustom] ([KeyID]) ON [PRIMARY]
GO
