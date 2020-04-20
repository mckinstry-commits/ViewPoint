SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/*****************************************
* Created By:	GF 09/25/2006 6.x only
* Modfied By:
*
* Provides a view of MS Quote Header for 6.x
* Since PMMSHeader form uses PMCo and Project, need to
* alias JCCO as [PMCo] and Job as [Project] so that
* MSQH Quotes can be referenced in PM MS Header.
*
*
*****************************************/

CREATE view [dbo].[MSQHPM] as
select a.JCCo as [PMCo], a.Job as [Project], a.*
from dbo.MSQH a




GO
GRANT SELECT ON  [dbo].[MSQHPM] TO [public]
GRANT INSERT ON  [dbo].[MSQHPM] TO [public]
GRANT DELETE ON  [dbo].[MSQHPM] TO [public]
GRANT UPDATE ON  [dbo].[MSQHPM] TO [public]
GRANT SELECT ON  [dbo].[MSQHPM] TO [Viewpoint]
GRANT INSERT ON  [dbo].[MSQHPM] TO [Viewpoint]
GRANT DELETE ON  [dbo].[MSQHPM] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[MSQHPM] TO [Viewpoint]
GO
