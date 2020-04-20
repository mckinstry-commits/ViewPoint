SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [api].[DocumentDictionary]
	AS SELECT [DocumentDictionaryId], [DocumentId], [SecondaryIdentifierTypeId], [DictionaryValue], [Ordinal], [CreatedByUser], [DBCreatedDate], [UpdatedByUser], [DBUpdatedDate], [Version] FROM Document.DocumentDictionary
GO
