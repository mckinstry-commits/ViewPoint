SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [Document].DocumentType
AS

SELECT * FROM [Document].[vDocumentType]
GO
GRANT SELECT ON  [Document].[DocumentType] TO [public]
GRANT INSERT ON  [Document].[DocumentType] TO [public]
GRANT DELETE ON  [Document].[DocumentType] TO [public]
GRANT UPDATE ON  [Document].[DocumentType] TO [public]
GO
