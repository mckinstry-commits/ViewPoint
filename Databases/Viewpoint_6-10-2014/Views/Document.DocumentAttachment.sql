SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [Document].[DocumentAttachment]

AS 

SELECT a.* FROM [Document].[vDocumentAttachment] AS a
GO
GRANT SELECT ON  [Document].[DocumentAttachment] TO [public]
GRANT INSERT ON  [Document].[DocumentAttachment] TO [public]
GRANT DELETE ON  [Document].[DocumentAttachment] TO [public]
GRANT UPDATE ON  [Document].[DocumentAttachment] TO [public]
GO
