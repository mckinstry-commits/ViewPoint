CREATE TABLE [Document].[vDocumentAttachment]
(
[AttachmentId] [uniqueidentifier] NOT NULL,
[FullName] [varchar] (256) COLLATE Latin1_General_BIN NOT NULL,
[AttachmentData] [varbinary] (max) NOT NULL,
[AttachmentSize] [int] NOT NULL,
[ContentType] [varchar] (256) COLLATE Latin1_General_BIN NOT NULL,
[DocumentId] [uniqueidentifier] NOT NULL,
[DocumentImage] [bit] NOT NULL,
[ParticipantId] [uniqueidentifier] NOT NULL,
[CreatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vDocumentAttachment_CreatedByUser] DEFAULT (suser_name()),
[DBCreatedDate] [datetime] NOT NULL CONSTRAINT [DF_vDocumentAttachment_DBCreatedDate] DEFAULT (getdate()),
[UpdatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NULL,
[DBUpdatedDate] [datetime] NULL,
[Version] [int] NOT NULL CONSTRAINT [DF_vDocumentAttachment_Version] DEFAULT ((1))
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [Document].[vDocumentAttachment] ADD CONSTRAINT [PK_vDocumentAttachment] PRIMARY KEY CLUSTERED  ([AttachmentId]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vDocumentAttachment_Document] ON [Document].[vDocumentAttachment] ([DocumentId]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vDocumentAttachment_Participant] ON [Document].[vDocumentAttachment] ([ParticipantId]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
ALTER TABLE [Document].[vDocumentAttachment] WITH NOCHECK ADD CONSTRAINT [FK_DocumentAttachment_Document] FOREIGN KEY ([DocumentId]) REFERENCES [Document].[vDocument] ([DocumentId])
GO
ALTER TABLE [Document].[vDocumentAttachment] WITH NOCHECK ADD CONSTRAINT [FK_DocumentAttachment_Participant] FOREIGN KEY ([ParticipantId]) REFERENCES [Document].[vParticipant] ([ParticipantId])
GO
ALTER TABLE [Document].[vDocumentAttachment] NOCHECK CONSTRAINT [FK_DocumentAttachment_Document]
GO
ALTER TABLE [Document].[vDocumentAttachment] NOCHECK CONSTRAINT [FK_DocumentAttachment_Participant]
GO
