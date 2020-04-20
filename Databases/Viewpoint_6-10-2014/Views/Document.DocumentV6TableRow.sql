SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [Document].[DocumentV6TableRow]

AS 

SELECT a.* FROM [Document].[vDocumentV6TableRow] AS a
GO
GRANT SELECT ON  [Document].[DocumentV6TableRow] TO [public]
GRANT INSERT ON  [Document].[DocumentV6TableRow] TO [public]
GRANT DELETE ON  [Document].[DocumentV6TableRow] TO [public]
GRANT UPDATE ON  [Document].[DocumentV6TableRow] TO [public]
GO
