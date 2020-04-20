SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [Document].[DocumentResponse]
	AS SELECT * FROM [Document].[vDocumentResponse]
GO
GRANT SELECT ON  [Document].[DocumentResponse] TO [public]
GRANT INSERT ON  [Document].[DocumentResponse] TO [public]
GRANT DELETE ON  [Document].[DocumentResponse] TO [public]
GRANT UPDATE ON  [Document].[DocumentResponse] TO [public]
GO
