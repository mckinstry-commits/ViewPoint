CREATE TABLE [dbo].[vHQSA]
(
[AttributeID] [bigint] NOT NULL IDENTITY(1, 1),
[AuditID] [bigint] NULL,
[Datatype] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Qualifier] [tinyint] NULL,
[Instance] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[TableName] [varchar] (128) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vHQSA_TableName] ON [dbo].[vHQSA] ([TableName], [Datatype], [Instance]) ON [PRIMARY]
GO
CREATE STATISTICS [STAT_vHQSA_DT2] ON [dbo].[vHQSA] ([AuditID], [Datatype], [Qualifier], [Instance])
GO
CREATE STATISTICS [STAT_vHQSA_DT] ON [dbo].[vHQSA] ([AuditID], [Datatype], [TableName])
GO
