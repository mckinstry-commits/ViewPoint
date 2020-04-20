SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [api].[RelatedDocument]
	AS SELECT [RelatedDocumentId], [DocumentId], [AssociatedDocumentId], [KeyId], [CreatedByUser], [DBCreateDate], [UpdatedByUser], [DBUpdatedDate], [Version] FROM Document.RelatedDocument
GO
