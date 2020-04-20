SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [api].[DocumentTypeSecondaryIdentifierType]
	AS SELECT [DocumentSecondaryIdentifierTypeId], [DocumentTypeId], [SecondaryIdentifierTypeId], [CreatedByUser], [DBCreatedDate], [UpdatedByUser], [DBUpdatedDate], [Version] FROM Document.[DocumentTypeSecondaryIdentifierType]
GO
