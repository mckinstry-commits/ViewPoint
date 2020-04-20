CREATE TABLE [dbo].[vDDCustomConstraintErrorMsg]
(
[KeyID] [int] NOT NULL IDENTITY(1, 1),
[ConstraintName] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[ErrorMessage] [varchar] (256) COLLATE Latin1_General_BIN NOT NULL,
[Country] [char] (2) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vDDCustomConstraintErrorMsg] ADD CONSTRAINT [PK_vDDCustomConstraintErrorMsg] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vDDCustomConstraintErrorMsg_ConstraintName] ON [dbo].[vDDCustomConstraintErrorMsg] ([ConstraintName]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
