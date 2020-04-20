CREATE TABLE [dbo].[bDDDX]
(
[Package] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Description] [varchar] (30) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biDDDX] ON [dbo].[bDDDX] ([Package]) ON [PRIMARY]
GO
