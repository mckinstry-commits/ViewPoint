CREATE TABLE [dbo].[bDDDX]
(
[Package] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Description] [varchar] (30) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biDDDX] ON [dbo].[bDDDX] ([Package]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
