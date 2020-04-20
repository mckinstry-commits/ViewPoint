CREATE TABLE [dbo].[vAuditFlagTables]
(
[AuditFlagID] [smallint] NOT NULL,
[AuditTableID] [smallint] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vAuditFlagTables] ADD CONSTRAINT [PK_vAuditFlagTables] PRIMARY KEY CLUSTERED  ([AuditFlagID], [AuditTableID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vAuditFlagTables] WITH NOCHECK ADD CONSTRAINT [FK_vAuditFlagTables_vAuditFlags] FOREIGN KEY ([AuditFlagID]) REFERENCES [dbo].[vAuditFlags] ([KeyID])
GO
ALTER TABLE [dbo].[vAuditFlagTables] WITH NOCHECK ADD CONSTRAINT [FK_vAuditFlagTables_vAuditTables] FOREIGN KEY ([AuditTableID]) REFERENCES [dbo].[vAuditTables] ([KeyID])
GO
