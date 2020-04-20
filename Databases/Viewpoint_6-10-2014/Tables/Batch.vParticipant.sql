CREATE TABLE [Batch].[vParticipant]
(
[ParticipantId] [uniqueidentifier] NOT NULL,
[FirstName] [nvarchar] (32) COLLATE Latin1_General_BIN NOT NULL,
[LastName] [nvarchar] (32) COLLATE Latin1_General_BIN NOT NULL,
[Email] [nvarchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[DisplayName] [nvarchar] (64) COLLATE Latin1_General_BIN NOT NULL,
[Title] [nvarchar] (128) COLLATE Latin1_General_BIN NULL,
[CompanyName] [nvarchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[CompanyNumber] [tinyint] NOT NULL,
[DocumentId] [uniqueidentifier] NOT NULL,
[Status] [nvarchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[DocumentRoleTypeId] [uniqueidentifier] NOT NULL,
[CreatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[DBCreatedDate] [datetime] NOT NULL,
[UpdatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NULL,
[DBUpdatedDate] [datetime] NULL,
[Version] [int] NOT NULL CONSTRAINT [DF__vParticip__Versi__20BBB836] DEFAULT ((1)),
[Co] [dbo].[bCompany] NULL,
[Mth] [dbo].[bMonth] NULL,
[BatchId] [dbo].[bBatchID] NULL,
[BatchSeq] [int] NULL,
[Seq] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [Batch].[vParticipant] ADD CONSTRAINT [PK_vParticipant] PRIMARY KEY CLUSTERED  ([ParticipantId]) ON [PRIMARY]
GO
ALTER TABLE [Batch].[vParticipant] WITH NOCHECK ADD CONSTRAINT [FK_Participant_Document] FOREIGN KEY ([DocumentId]) REFERENCES [Batch].[vDocument] ([DocumentId])
GO
ALTER TABLE [Batch].[vParticipant] WITH NOCHECK ADD CONSTRAINT [FK_Participant_DocumentRoleType] FOREIGN KEY ([DocumentRoleTypeId]) REFERENCES [Document].[vDocumentRoleType] ([DocumentRoleTypeId])
GO
ALTER TABLE [Batch].[vParticipant] NOCHECK CONSTRAINT [FK_Participant_Document]
GO
ALTER TABLE [Batch].[vParticipant] NOCHECK CONSTRAINT [FK_Participant_DocumentRoleType]
GO
