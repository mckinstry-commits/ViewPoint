SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [Document].[DocumentTypeSecondaryIdentifierType]
	AS SELECT * FROM Document.[vDocumentTypeSecondaryIdentifierType]
GO
GRANT SELECT ON  [Document].[DocumentTypeSecondaryIdentifierType] TO [public]
GRANT INSERT ON  [Document].[DocumentTypeSecondaryIdentifierType] TO [public]
GRANT DELETE ON  [Document].[DocumentTypeSecondaryIdentifierType] TO [public]
GRANT UPDATE ON  [Document].[DocumentTypeSecondaryIdentifierType] TO [public]
GO
