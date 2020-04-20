SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [Document].[DocumentSlideShow]

AS 


SELECT a.* 
FROM [Document].[vDocumentSlideShow] AS a
GO
GRANT SELECT ON  [Document].[DocumentSlideShow] TO [public]
GRANT INSERT ON  [Document].[DocumentSlideShow] TO [public]
GRANT DELETE ON  [Document].[DocumentSlideShow] TO [public]
GRANT UPDATE ON  [Document].[DocumentSlideShow] TO [public]
GO
