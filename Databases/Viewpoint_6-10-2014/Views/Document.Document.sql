SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [Document].[Document]
AS 

SELECT * FROM [Document].[vDocument]
GO
GRANT SELECT ON  [Document].[Document] TO [public]
GRANT INSERT ON  [Document].[Document] TO [public]
GRANT DELETE ON  [Document].[Document] TO [public]
GRANT UPDATE ON  [Document].[Document] TO [public]
GO
