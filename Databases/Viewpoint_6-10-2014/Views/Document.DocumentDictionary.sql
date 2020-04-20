SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [Document].[DocumentDictionary]
	AS SELECT * FROM Document.vDocumentDictionary
GO
GRANT SELECT ON  [Document].[DocumentDictionary] TO [public]
GRANT INSERT ON  [Document].[DocumentDictionary] TO [public]
GRANT DELETE ON  [Document].[DocumentDictionary] TO [public]
GRANT UPDATE ON  [Document].[DocumentDictionary] TO [public]
GO
