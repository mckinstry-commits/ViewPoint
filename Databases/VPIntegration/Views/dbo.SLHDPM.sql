SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




/*****************************************
* Created By:	GF 10/13/2005 6.x only
* Modfied By:
*
* Provides a view of SL Subcontract Header for 6.x
* Since PMSLHeader form uses PMCo and Project, need to
* alias JCCO as [PMCo] and Job as [Project] so that
* SLHD subcontracts can be referenced in PM SL Header.
*
*****************************************/

CREATE view [dbo].[SLHDPM] as
select a.JCCo as [PMCo], a.Job as [Project], a.*
from dbo.SLHD a





GO
GRANT SELECT ON  [dbo].[SLHDPM] TO [public]
GRANT INSERT ON  [dbo].[SLHDPM] TO [public]
GRANT DELETE ON  [dbo].[SLHDPM] TO [public]
GRANT UPDATE ON  [dbo].[SLHDPM] TO [public]
GO
