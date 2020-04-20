SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************
* Created By:	GF 07/13/2005 6.x only
* Modfied By:
*
* Provides a view of PM Project Locations for 6.x
* Since PMProjects form uses JCCo and Job, need to
* alias PMCO as [JCCo] and Project as [Job] so that
* PM Project Locations can be on a related tab in 
* PM Projects form.
*
*****************************************/

CREATE view [dbo].[PMPL1] as 
select a.PMCo as [JCCo], a.Project as [Job], a.*
from dbo.PMPL a

GO
GRANT SELECT ON  [dbo].[PMPL1] TO [public]
GRANT INSERT ON  [dbo].[PMPL1] TO [public]
GRANT DELETE ON  [dbo].[PMPL1] TO [public]
GRANT UPDATE ON  [dbo].[PMPL1] TO [public]
GO
