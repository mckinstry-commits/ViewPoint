SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[SLInExclusions]
AS
SELECT     dbo.vSLInExclusions.*
FROM         dbo.vSLInExclusions




GO
GRANT SELECT ON  [dbo].[SLInExclusions] TO [public]
GRANT INSERT ON  [dbo].[SLInExclusions] TO [public]
GRANT DELETE ON  [dbo].[SLInExclusions] TO [public]
GRANT UPDATE ON  [dbo].[SLInExclusions] TO [public]
GRANT SELECT ON  [dbo].[SLInExclusions] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SLInExclusions] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SLInExclusions] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SLInExclusions] TO [Viewpoint]
GO
