CREATE TABLE [Batch].[vDocument]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[DocumentId] [uniqueidentifier] NOT NULL,
[Title] [nvarchar] (256) COLLATE Latin1_General_BIN NOT NULL,
[SenderId] [uniqueidentifier] NOT NULL,
[DocumentTypeId] [uniqueidentifier] NOT NULL,
[DueDate] [datetime] NULL,
[SentDate] [datetime] NOT NULL,
[DocumentDisplay] [nvarchar] (256) COLLATE Latin1_General_BIN NULL,
[CompanyId] [uniqueidentifier] NOT NULL,
[State] [nvarchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[CreatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[DBCreatedDate] [datetime] NOT NULL,
[UpdatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NULL,
[DBUpdatedDate] [datetime] NULL,
[Version] [int] NOT NULL CONSTRAINT [DF__vDocument__Versi__1CEB2752] DEFAULT ((1)),
[Co] [dbo].[bCompany] NULL,
[Mth] [dbo].[bMonth] NULL,
[BatchId] [dbo].[bBatchID] NULL,
[BatchSeq] [int] NULL,
[ProcessingStatus] [varchar] (25) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [Batch].[vDocument] ADD CONSTRAINT [PK_vDocument] PRIMARY KEY CLUSTERED  ([DocumentId]) ON [PRIMARY]
GO
ALTER TABLE [Batch].[vDocument] WITH NOCHECK ADD CONSTRAINT [FK_Document_CompanyId] FOREIGN KEY ([CompanyId]) REFERENCES [Document].[vCompany] ([CompanyId])
GO
ALTER TABLE [Batch].[vDocument] WITH NOCHECK ADD CONSTRAINT [FK_Batch_Document_Document_DocumentType] FOREIGN KEY ([DocumentTypeId]) REFERENCES [Document].[vDocumentType] ([DocumentTypeId])
GO
ALTER TABLE [Batch].[vDocument] WITH NOCHECK ADD CONSTRAINT [FK_Document_Sender] FOREIGN KEY ([SenderId]) REFERENCES [Document].[vSender] ([SenderId])
GO
ALTER TABLE [Batch].[vDocument] NOCHECK CONSTRAINT [FK_Document_CompanyId]
GO
ALTER TABLE [Batch].[vDocument] NOCHECK CONSTRAINT [FK_Batch_Document_Document_DocumentType]
GO
ALTER TABLE [Batch].[vDocument] NOCHECK CONSTRAINT [FK_Document_Sender]
GO
