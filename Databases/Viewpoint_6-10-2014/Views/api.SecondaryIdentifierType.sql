SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [api].[SecondaryIdentifierType]
	AS SELECT [SecondaryIdentifierTypeId], [IdentifierName], [CreatedByUser], [DBCreatedDate], [UpdatedByUser], [DBUpdatedDate], [Version] FROM Document.SecondaryIdentifierType
GO
