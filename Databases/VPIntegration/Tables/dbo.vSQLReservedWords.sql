CREATE TABLE [dbo].[vSQLReservedWords]
(
[ReservedWord] [nvarchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSQLReservedWords] ADD CONSTRAINT [PK_vSQLReservedWords] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vSQLReservedWords_ReservedWord] ON [dbo].[vSQLReservedWords] ([ReservedWord]) ON [PRIMARY]
GO
