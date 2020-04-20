CREATE TABLE [dbo].[vAuditColumns]
(
[KeyID] [int] NOT NULL IDENTITY(1, 1),
[AuditTablesID] [smallint] NOT NULL,
[ColumnName] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[ColumnDesc] [varchar] (128) COLLATE Latin1_General_BIN NULL,
[IsKey] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vAuditColumns_IsKey] DEFAULT ('N'),
[IsInsertAudit] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vAuditColumns_IsInsertAudit] DEFAULT ('N'),
[IsUpdateAudit] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vAuditColumns_IsUpdateAudit] DEFAULT ('N'),
[IsDeleteAudit] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vAuditColumns_IsDeleteAudit] DEFAULT ('N'),
[IsUD] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vAuditColumns_IsUD] DEFAULT ('N'),
[IsCo] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vAuditColumns_IsCo] DEFAULT ('N'),
[IsGroup] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vAuditColumns_IsGroup] DEFAULT ('N')
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vAuditColumns] ADD CONSTRAINT [PK_vAuditColumns] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vAuditColumns_AuditTablesColumns] ON [dbo].[vAuditColumns] ([AuditTablesID], [ColumnName]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vAuditColumns] WITH NOCHECK ADD CONSTRAINT [FK_vAuditColumns_vAuditTables] FOREIGN KEY ([AuditTablesID]) REFERENCES [dbo].[vAuditTables] ([KeyID])
GO
ALTER TABLE [dbo].[vAuditColumns] NOCHECK CONSTRAINT [FK_vAuditColumns_vAuditTables]
GO
