CREATE TABLE [Batch].[vDocumentSlideShow]
(
[DocumentSlideShowId] [bigint] NOT NULL IDENTITY(1, 1),
[DocumentId] [uniqueidentifier] NOT NULL,
[Ordinal] [int] NOT NULL,
[SlideShowImage] [varbinary] (max) NOT NULL,
[Caption] [nvarchar] (256) COLLATE Latin1_General_BIN NULL,
[CreatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[DBCreatedDate] [datetime] NOT NULL,
[UpdatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NULL,
[DBUpdatedDate] [datetime] NULL,
[Version] [int] NOT NULL CONSTRAINT [DF__vDocument__Versi__1ED36FC4] DEFAULT ((1))
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [Batch].[vDocumentSlideShow] ADD CONSTRAINT [PK_vDocumentSlideShow] PRIMARY KEY CLUSTERED  ([DocumentSlideShowId]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vDocumentSlideShow_DocumentId] ON [Batch].[vDocumentSlideShow] ([DocumentId]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
ALTER TABLE [Batch].[vDocumentSlideShow] WITH NOCHECK ADD CONSTRAINT [FK_vDocumentSlideShow_vDocument] FOREIGN KEY ([DocumentId]) REFERENCES [Batch].[vDocument] ([DocumentId])
GO
ALTER TABLE [Batch].[vDocumentSlideShow] NOCHECK CONSTRAINT [FK_vDocumentSlideShow_vDocument]
GO
