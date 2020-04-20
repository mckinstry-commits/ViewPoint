CREATE TABLE [dbo].[vDDHD]
(
[HeaderTable] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[DetailTable] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[JoinClause] [varchar] (128) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [viDDHD] ON [dbo].[vDDHD] ([HeaderTable], [DetailTable]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
