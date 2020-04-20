CREATE TABLE [Batch].[vDocumentDictionary]
(
[KeyId] [bigint] NOT NULL IDENTITY(1, 1),
[DocumentDictionaryId] [uniqueidentifier] NOT NULL,
[DocumentId] [uniqueidentifier] NOT NULL,
[SecondaryIdentifierTypeId] [uniqueidentifier] NOT NULL,
[DictionaryValue] [nvarchar] (256) COLLATE Latin1_General_BIN NULL,
[Ordinal] [tinyint] NOT NULL,
[CreatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[DBCreatedDate] [datetime] NOT NULL,
[UpdatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NULL,
[DBUpdatedDate] [datetime] NULL,
[Version] [int] NOT NULL CONSTRAINT [DF__vDocument__Versi__1DDF4B8B] DEFAULT ((1))
) ON [PRIMARY]
GO
ALTER TABLE [Batch].[vDocumentDictionary] ADD CONSTRAINT [PK_DocumentDictionary] PRIMARY KEY CLUSTERED  ([KeyId]) ON [PRIMARY]
GO
ALTER TABLE [Batch].[vDocumentDictionary] WITH NOCHECK ADD CONSTRAINT [FK_DocumentDictionary_Document] FOREIGN KEY ([DocumentId]) REFERENCES [Batch].[vDocument] ([DocumentId])
GO
ALTER TABLE [Batch].[vDocumentDictionary] WITH NOCHECK ADD CONSTRAINT [FK_DocumentDictionary_SecondaryIdentifierType] FOREIGN KEY ([SecondaryIdentifierTypeId]) REFERENCES [Document].[vSecondaryIdentifierType] ([SecondaryIdentifierTypeId])
GO
ALTER TABLE [Batch].[vDocumentDictionary] NOCHECK CONSTRAINT [FK_DocumentDictionary_Document]
GO
ALTER TABLE [Batch].[vDocumentDictionary] NOCHECK CONSTRAINT [FK_DocumentDictionary_SecondaryIdentifierType]
GO
