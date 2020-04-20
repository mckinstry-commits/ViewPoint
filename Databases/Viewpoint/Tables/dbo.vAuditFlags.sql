CREATE TABLE [dbo].[vAuditFlags]
(
[KeyID] [smallint] NOT NULL IDENTITY(1, 1),
[FlagName] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[Module] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[AuditByCompany] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vAuditFlags_AuditByCompany] DEFAULT ('Y'),
[AuditByGroup] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vAuditFlags_AuditByVendorGroup] DEFAULT ('N')
) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [IX_vAuditFlags_FlagNameModule] ON [dbo].[vAuditFlags] ([FlagName], [Module]) WITH (FILLFACTOR=80) ON [PRIMARY]

GO
ALTER TABLE [dbo].[vAuditFlags] ADD CONSTRAINT [PK_vAuditFlags] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
