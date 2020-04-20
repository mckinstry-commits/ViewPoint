CREATE TABLE [dbo].[budEntityType]
(
[EntityAbbr] [varchar] (1) COLLATE Latin1_General_BIN NOT NULL,
[EntityDescription] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biudEntityType] ON [dbo].[budEntityType] ([EntityAbbr]) ON [PRIMARY]
GO
