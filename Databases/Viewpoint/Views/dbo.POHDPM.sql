SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************
* Created By:	GF 09/07/2006 6.x only
* Modfied By:
*
* Provides a view of PO Header for 6.x
* Since PMPOHeader form uses PMCo and Project, need to
* alias JCCO as [PMCo] and Job as [Project] so that
* POHD purchase orders can be referenced in PM PO Header.
* Alias column for ShipToJob flag which is 'Y' when
* POHD.ShipAddress equals JCJM.ShipAddress.
*
*****************************************/

CREATE view [dbo].[POHDPM] as
select a.JCCo as [PMCo], a.Job as [Project], a.*
from dbo.POHD a

GO
GRANT SELECT ON  [dbo].[POHDPM] TO [public]
GRANT INSERT ON  [dbo].[POHDPM] TO [public]
GRANT DELETE ON  [dbo].[POHDPM] TO [public]
GRANT UPDATE ON  [dbo].[POHDPM] TO [public]
GO
