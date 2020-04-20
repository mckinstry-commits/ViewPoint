CREATE TABLE [dbo].[vAuditFlagCompany]
(
[KeyID] [int] NOT NULL IDENTITY(1, 1),
[AuditCo] [tinyint] NOT NULL,
[AuditFlagID] [smallint] NOT NULL
) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [IX_vAuditFlagCompany_AuditCoAuditFlagID] ON [dbo].[vAuditFlagCompany] ([AuditCo], [AuditFlagID]) WITH (FILLFACTOR=80) ON [PRIMARY]

ALTER TABLE [dbo].[vAuditFlagCompany] WITH NOCHECK ADD
CONSTRAINT [FK_vAuditFlagCompany_bHQCO] FOREIGN KEY ([AuditCo]) REFERENCES [dbo].[bHQCO] ([HQCo]) ON DELETE CASCADE
ALTER TABLE [dbo].[vAuditFlagCompany] WITH NOCHECK ADD
CONSTRAINT [FK_vAuditFlagCompany_vAuditFlags] FOREIGN KEY ([AuditFlagID]) REFERENCES [dbo].[vAuditFlags] ([KeyID])
GO
ALTER TABLE [dbo].[vAuditFlagCompany] ADD CONSTRAINT [PK_vAuditFlagCompany] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
