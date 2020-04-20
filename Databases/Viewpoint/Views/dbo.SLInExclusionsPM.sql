SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE VIEW [dbo].[SLInExclusionsPM] AS

select a.*, a.Co as [PMCo], a.Co AS [SLCo]
from dbo.vSLInExclusions a





GO
GRANT SELECT ON  [dbo].[SLInExclusionsPM] TO [public]
GRANT INSERT ON  [dbo].[SLInExclusionsPM] TO [public]
GRANT DELETE ON  [dbo].[SLInExclusionsPM] TO [public]
GRANT UPDATE ON  [dbo].[SLInExclusionsPM] TO [public]
GO
