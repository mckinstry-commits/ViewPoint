SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.Companies
AS
SELECT     HQCo
FROM         dbo.bHQCO
UNION
SELECT     - 1 AS HQCo

GO
GRANT SELECT ON  [dbo].[Companies] TO [public]
GRANT INSERT ON  [dbo].[Companies] TO [public]
GRANT DELETE ON  [dbo].[Companies] TO [public]
GRANT UPDATE ON  [dbo].[Companies] TO [public]
GO
