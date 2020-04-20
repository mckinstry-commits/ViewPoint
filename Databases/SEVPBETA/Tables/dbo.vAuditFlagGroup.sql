CREATE TABLE [dbo].[vAuditFlagGroup]
(
[KeyID] [int] NOT NULL IDENTITY(1, 1),
[AuditGroup] [tinyint] NOT NULL,
[AuditFlagID] [smallint] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vAuditFlagGroup] ADD CONSTRAINT [PK_vAuditFlagGroup] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vAuditFlagGroup_AuditGroupAuditFlag] ON [dbo].[vAuditFlagGroup] ([AuditGroup], [AuditFlagID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vAuditFlagGroup] WITH NOCHECK ADD CONSTRAINT [FK_vAuditFlagGroup_vAuditFlags] FOREIGN KEY ([AuditFlagID]) REFERENCES [dbo].[vAuditFlags] ([KeyID])
GO
ALTER TABLE [dbo].[vAuditFlagGroup] WITH NOCHECK ADD CONSTRAINT [FK_vAuditFlagGroup_bHQGP] FOREIGN KEY ([AuditGroup]) REFERENCES [dbo].[bHQGP] ([Grp]) ON DELETE CASCADE
GO
