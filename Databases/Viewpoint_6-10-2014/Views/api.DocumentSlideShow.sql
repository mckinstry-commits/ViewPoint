SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [api].[DocumentSlideShow]
	AS SELECT [DocumentSlideShowId], [DocumentId], [Ordinal], [SlideShowImage], [Caption], [CreatedByUser], [DBCreatedDate], [UpdatedByUser], [DBUpdatedDate], [Version] FROM Document.vDocumentSlideShow
GO
