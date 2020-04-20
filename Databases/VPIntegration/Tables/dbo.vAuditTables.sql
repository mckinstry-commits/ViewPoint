CREATE TABLE [dbo].[vAuditTables]
(
[KeyID] [smallint] NOT NULL IDENTITY(1, 1),
[TableName] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vAuditTables] ADD CONSTRAINT [PK_vAuditTables] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vAuditTables_TableName] ON [dbo].[vAuditTables] ([TableName]) ON [PRIMARY]
GO
