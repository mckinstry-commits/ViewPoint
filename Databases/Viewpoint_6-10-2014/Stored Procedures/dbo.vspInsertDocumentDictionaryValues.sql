SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspInsertDocumentDictionaryValues]
	@DocumentId UNIQUEIDENTIFIER,
	@Name varchar(30),
	@Value varchar(256),
	@Order tinyint,
	@DocType varchar(30),
	@User varchar(128)
AS
BEGIN
	SET NOCOUNT ON;
	INSERT INTO Document.DocumentDictionary ( DocumentDictionaryId, DocumentId, SecondaryIdentifierTypeId, DictionaryValue, Ordinal, CreatedByUser, DBCreatedDate, Version )
	SELECT	NEWID(),
			@DocumentId,
			Document.DocumentTypeSecondaryIdentifierType.SecondaryIdentifierTypeId,
			@Value,
			@Order,
			@User,
			GETUTCDATE(),
			1
	FROM Document.DocumentTypeSecondaryIdentifierType
	INNER JOIN Document.DocumentType ON DocumentTypeSecondaryIdentifierType.DocumentTypeId = DocumentType.DocumentTypeId
	INNER JOIN Document.SecondaryIdentifierType ON DocumentTypeSecondaryIdentifierType.SecondaryIdentifierTypeId = SecondaryIdentifierType.SecondaryIdentifierTypeId
	WHERE DocumentType.DocumentTypeName = @DocType AND SecondaryIdentifierType.IdentifierName = @Name;
END
GO
GRANT EXECUTE ON  [dbo].[vspInsertDocumentDictionaryValues] TO [public]
GO
