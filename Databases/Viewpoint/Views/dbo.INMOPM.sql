SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************
* Created By:	GF 09/13/2006 6.x only
* Modfied By:
*
* Provides a view of MO Header for 6.x
* Since PMMOHeader form uses PMCo and Project, need to
* alias JCCO as [PMCo] and Job as [Project] so that
* INMO Material Orders can be referenced in PM MO Header.
*
*
*****************************************/

CREATE view [dbo].[INMOPM] as
select a.JCCo as [PMCo], a.Job as [Project], a.*
from dbo.INMO a

GO
GRANT SELECT ON  [dbo].[INMOPM] TO [public]
GRANT INSERT ON  [dbo].[INMOPM] TO [public]
GRANT DELETE ON  [dbo].[INMOPM] TO [public]
GRANT UPDATE ON  [dbo].[INMOPM] TO [public]
GO
