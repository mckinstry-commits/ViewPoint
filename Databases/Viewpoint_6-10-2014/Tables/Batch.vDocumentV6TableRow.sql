CREATE TABLE [Batch].[vDocumentV6TableRow]
(
[DocumentV6TableRowId] [bigint] NOT NULL IDENTITY(1, 1),
[DocumentId] [uniqueidentifier] NOT NULL,
[TableName] [nvarchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[TableKeyId] [bigint] NOT NULL,
[CreatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[DBCreatedDate] [datetime] NOT NULL,
[UpdatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NULL,
[DBUpdatedDate] [datetime] NULL,
[Version] [int] NOT NULL CONSTRAINT [DF__vDocument__Versi__1FC793FD] DEFAULT ((1))
) ON [PRIMARY]
GO
ALTER TABLE [Batch].[vDocumentV6TableRow] ADD CONSTRAINT [PK_vDocumentV6TableRow] PRIMARY KEY CLUSTERED  ([DocumentV6TableRowId]) ON [PRIMARY]
GO
ALTER TABLE [Batch].[vDocumentV6TableRow] WITH NOCHECK ADD CONSTRAINT [FK_vDocumentV6TableRow_vDocument] FOREIGN KEY ([DocumentId]) REFERENCES [Batch].[vDocument] ([DocumentId])
GO
ALTER TABLE [Batch].[vDocumentV6TableRow] NOCHECK CONSTRAINT [FK_vDocumentV6TableRow_vDocument]
GO
