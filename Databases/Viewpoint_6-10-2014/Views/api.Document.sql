SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [api].[Document]
	AS SELECT [DocumentId], [Title], [SenderId], [DocumentTypeId], [DueDate], [SentDate], [DocumentDisplay], [CompanyId], [State], [CreatedByUser], [DBCreatedDate], [UpdatedByUser], [DBUpdatedDate], [Version]
		FROM Document.Document
GO
