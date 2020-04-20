SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*****************************************
 * Created By:	GF 03/22/2007 6.x issue #28847
 * Modfied By:
 *
 * Provides a view of PM Drawing Logs with a
 * implied column for revisions from PM Drawing Log Revisions.
 * This column will be a YN flag for use in PM Document Tracking
 *
 *****************************************/

CREATE view [dbo].[PMDGGrid] as
select a.PMCo, a.Project, a.DrawingType, a.Drawing,
   	'Revisions' = case when (select count(*) from dbo.PMDR b with (nolock) where b.PMCo=a.PMCo and b.Project=a.Project
						and b.DrawingType=a.DrawingType and b.Drawing=a.Drawing) > 0 then 'Y' else 'N' end
from dbo.PMDG a


GO
GRANT SELECT ON  [dbo].[PMDGGrid] TO [public]
GRANT INSERT ON  [dbo].[PMDGGrid] TO [public]
GRANT DELETE ON  [dbo].[PMDGGrid] TO [public]
GRANT UPDATE ON  [dbo].[PMDGGrid] TO [public]
GO
