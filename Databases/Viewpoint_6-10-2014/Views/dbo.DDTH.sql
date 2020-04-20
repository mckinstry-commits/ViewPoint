SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE  VIEW dbo.DDTH
  AS
  SELECT     a.*
  FROM         dbo.vDDTH a
  
 



GO
GRANT SELECT ON  [dbo].[DDTH] TO [public]
GRANT INSERT ON  [dbo].[DDTH] TO [public]
GRANT DELETE ON  [dbo].[DDTH] TO [public]
GRANT UPDATE ON  [dbo].[DDTH] TO [public]
GRANT SELECT ON  [dbo].[DDTH] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDTH] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDTH] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDTH] TO [Viewpoint]
GO
