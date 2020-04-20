SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************
* Created By:	GF 07/15/2005 6.x only
* Modfied By:
*
* Provides a view of JC Job Reviewere for 6.x
* Since PMProjects form uses PMCo and Project, need to
* alias JCCO as [PMCo] and Job as [Project] so that
* JC Job Reviewers can be on a related tab in 
* PM Projects form.
*
*****************************************/

CREATE view [dbo].[JCJR1] as 
select a.JCCo as [PMCo], a.Job as [Project], a.*
from dbo.JCJR a

GO
GRANT SELECT ON  [dbo].[JCJR1] TO [public]
GRANT INSERT ON  [dbo].[JCJR1] TO [public]
GRANT DELETE ON  [dbo].[JCJR1] TO [public]
GRANT UPDATE ON  [dbo].[JCJR1] TO [public]
GO
