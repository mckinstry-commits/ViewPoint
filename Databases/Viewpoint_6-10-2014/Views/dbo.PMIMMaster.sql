SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




/*****************************************
 * Created By:	GF 04/30/2008
 * Modfied By:
 *
 * Provides a view of PM Issue Master with the master
 * issue description for display in PM Project Issues
 *
 *****************************************/

CREATE view [dbo].[PMIMMaster] as
select a.PMCo, a.Project, a.Issue, a.MasterIssue, b.Description
from PMIM a with (nolock)
left join PMIM b with (nolock) ON b.PMCo = a.PMCo and b.Project = a.Project and b.Issue = a.MasterIssue





GO
GRANT SELECT ON  [dbo].[PMIMMaster] TO [public]
GRANT INSERT ON  [dbo].[PMIMMaster] TO [public]
GRANT DELETE ON  [dbo].[PMIMMaster] TO [public]
GRANT UPDATE ON  [dbo].[PMIMMaster] TO [public]
GRANT SELECT ON  [dbo].[PMIMMaster] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMIMMaster] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMIMMaster] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMIMMaster] TO [Viewpoint]
GO
