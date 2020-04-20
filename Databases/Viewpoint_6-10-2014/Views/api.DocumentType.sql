SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [api].[DocumentType]
	AS SELECT	[DocumentTypeId], [DocumentTypeName], [DocumentTypeDescription], [CreatedByUser], [DBCreatedDate], [UpdatedByUser], [DBUpdatedDate], [Version]
		FROM Document.DocumentType
GO
