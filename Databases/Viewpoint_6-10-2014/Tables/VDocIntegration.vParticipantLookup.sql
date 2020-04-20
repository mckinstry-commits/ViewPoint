CREATE TABLE [VDocIntegration].[vParticipantLookup]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[LookupID] [int] NOT NULL,
[LookupDescription] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[QueryName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[DocumentRoleTypeId] [uniqueidentifier] NOT NULL,
[RoleName] [nvarchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[EmailQueryColumn] [nvarchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[FirstNameQueryColumn] [nvarchar] (128) COLLATE Latin1_General_BIN NULL,
[LastNameQueryColumn] [nvarchar] (128) COLLATE Latin1_General_BIN NULL,
[DisplayNameQueryColumn] [nvarchar] (128) COLLATE Latin1_General_BIN NULL,
[TitleQueryColumn] [nvarchar] (128) COLLATE Latin1_General_BIN NULL,
[CompanyNumberColumn] [nvarchar] (128) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [VDocIntegration].[vParticipantLookup] ADD CONSTRAINT [PK_vParticipantLookup] PRIMARY KEY CLUSTERED  ([LookupID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vParticipantLookup_KeyId] ON [VDocIntegration].[vParticipantLookup] ([KeyID]) ON [PRIMARY]
GO
ALTER TABLE [VDocIntegration].[vParticipantLookup] WITH NOCHECK ADD CONSTRAINT [FK_vParticipantLookup_vDocumentRoleType] FOREIGN KEY ([RoleName], [DocumentRoleTypeId]) REFERENCES [Document].[vDocumentRoleType] ([RoleName], [DocumentRoleTypeId])
GO
ALTER TABLE [VDocIntegration].[vParticipantLookup] NOCHECK CONSTRAINT [FK_vParticipantLookup_vDocumentRoleType]
GO
