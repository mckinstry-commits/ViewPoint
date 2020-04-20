SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [Document].[Activity]
AS 

SELECT a.* FROM [Document].[vActivity] AS a
GO
GRANT SELECT ON  [Document].[Activity] TO [public]
GRANT INSERT ON  [Document].[Activity] TO [public]
GRANT DELETE ON  [Document].[Activity] TO [public]
GRANT UPDATE ON  [Document].[Activity] TO [public]
GO
