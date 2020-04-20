SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.INCWGRID
AS
SELECT DISTINCT TOP (100) PERCENT dbo.bINLM.INCo, dbo.bINLM.Loc, dbo.bINCW.UserName, dbo.bINLM.Description
FROM         dbo.bINLM LEFT OUTER JOIN
                      dbo.bINCW ON dbo.bINLM.INCo = dbo.bINCW.INCo AND dbo.bINLM.Loc = dbo.bINCW.Loc
ORDER BY dbo.bINLM.INCo, dbo.bINLM.Loc, dbo.bINCW.UserName

GO
GRANT SELECT ON  [dbo].[INCWGRID] TO [public]
GRANT INSERT ON  [dbo].[INCWGRID] TO [public]
GRANT DELETE ON  [dbo].[INCWGRID] TO [public]
GRANT UPDATE ON  [dbo].[INCWGRID] TO [public]
GO
