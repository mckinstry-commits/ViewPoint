SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.SLInExclusionsBatch
AS
SELECT     dbo.vSLInExclusionsBatch.*
FROM         dbo.vSLInExclusionsBatch

GO
GRANT SELECT ON  [dbo].[SLInExclusionsBatch] TO [public]
GRANT INSERT ON  [dbo].[SLInExclusionsBatch] TO [public]
GRANT DELETE ON  [dbo].[SLInExclusionsBatch] TO [public]
GRANT UPDATE ON  [dbo].[SLInExclusionsBatch] TO [public]
GO
