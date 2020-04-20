SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      VIEW dbo.DDAL
AS SELECT  * FROM  dbo.vDDAL



GO
GRANT SELECT ON  [dbo].[DDAL] TO [public]
GRANT INSERT ON  [dbo].[DDAL] TO [public]
GRANT DELETE ON  [dbo].[DDAL] TO [public]
GRANT UPDATE ON  [dbo].[DDAL] TO [public]
GRANT SELECT ON  [dbo].[DDAL] TO [VCSPortal]
GRANT SELECT ON  [dbo].[DDAL] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDAL] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDAL] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDAL] TO [Viewpoint]
GO
