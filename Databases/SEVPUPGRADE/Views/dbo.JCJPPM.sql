SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*****************************************
* Created By:	GF 07/19/2005 6.x only
* Modfied By:
*
* Provides a view of JC Job Phases for 6.x
* Since PMProjects form uses PMCo and Project, need to
* alias JCCO as [PMCo] and Job as [Project] so that
* JC Job Phases can be on a related tab in 
* PM Projects form.
*
*****************************************/

CREATE   view [dbo].[JCJPPM] as 
select a.JCCo as [PMCo], a.Job as [Project], a.*
from dbo.JCJP a



GO
GRANT SELECT ON  [dbo].[JCJPPM] TO [public]
GRANT INSERT ON  [dbo].[JCJPPM] TO [public]
GRANT DELETE ON  [dbo].[JCJPPM] TO [public]
GRANT UPDATE ON  [dbo].[JCJPPM] TO [public]
GO
