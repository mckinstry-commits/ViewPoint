SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE  VIEW dbo.DDCS
  AS  SELECT a.*  FROM dbo.vDDCS a
  
  




GO
GRANT SELECT ON  [dbo].[DDCS] TO [public]
GRANT INSERT ON  [dbo].[DDCS] TO [public]
GRANT DELETE ON  [dbo].[DDCS] TO [public]
GRANT UPDATE ON  [dbo].[DDCS] TO [public]
GRANT SELECT ON  [dbo].[DDCS] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDCS] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDCS] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDCS] TO [Viewpoint]
GO
