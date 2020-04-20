SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   VIEW dbo.DDCI
AS
SELECT     *
FROM         dbo.vDDCI





GO
GRANT SELECT ON  [dbo].[DDCI] TO [public]
GRANT INSERT ON  [dbo].[DDCI] TO [public]
GRANT DELETE ON  [dbo].[DDCI] TO [public]
GRANT UPDATE ON  [dbo].[DDCI] TO [public]
GRANT SELECT ON  [dbo].[DDCI] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDCI] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDCI] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDCI] TO [Viewpoint]
GO
