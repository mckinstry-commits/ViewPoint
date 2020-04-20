SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [Document].[Comment]
AS

SELECT a.* FROM [Document].[vComment] AS a
GO
GRANT SELECT ON  [Document].[Comment] TO [public]
GRANT INSERT ON  [Document].[Comment] TO [public]
GRANT DELETE ON  [Document].[Comment] TO [public]
GRANT UPDATE ON  [Document].[Comment] TO [public]
GO
