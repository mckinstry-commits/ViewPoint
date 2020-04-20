CREATE TABLE [Document].[vDocumentSlideShow]
(
[DocumentSlideShowId] [bigint] NOT NULL IDENTITY(1, 1),
[DocumentId] [uniqueidentifier] NOT NULL,
[Ordinal] [int] NOT NULL,
[SlideShowImage] [varbinary] (max) NOT NULL,
[Caption] [nvarchar] (256) COLLATE Latin1_General_BIN NULL,
[CreatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vDocumentSlideShow_CreatedByUser] DEFAULT (suser_name()),
[DBCreatedDate] [datetime] NOT NULL CONSTRAINT [DF_vDocumentSlideShow_DBCreatedDate] DEFAULT (getdate()),
[UpdatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NULL,
[DBUpdatedDate] [datetime] NULL,
[Version] [int] NOT NULL CONSTRAINT [DF_vDocumentSlideShow_Version] DEFAULT ((1))
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [Document].[vDocumentSlideShow] ADD CONSTRAINT [PK_vDocumentSlideShow] PRIMARY KEY CLUSTERED  ([DocumentSlideShowId]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vDocumentSlideShow_DocumentId] ON [Document].[vDocumentSlideShow] ([DocumentId]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
ALTER TABLE [Document].[vDocumentSlideShow] WITH NOCHECK ADD CONSTRAINT [FK_vDocumentSlideShow_vDocument] FOREIGN KEY ([DocumentId]) REFERENCES [Document].[vDocument] ([DocumentId])
GO
ALTER TABLE [Document].[vDocumentSlideShow] NOCHECK CONSTRAINT [FK_vDocumentSlideShow_vDocument]
GO
