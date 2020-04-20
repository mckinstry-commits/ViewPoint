SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************
* Created By:	GF 09/27/2006 6.x only
* Modfied By:
*
* Provides a view of MS Quote Detail for 6.x
* only to be used in PMMSQuote Interfaced detail tab.
* Need to join to MSQH to alias MSQH.JCCo as [PMCo]
* and MSQH.Job as [Project] for joins.
* Also alias column to get max(InterfaceDate)
* from PMMF to display in grid.
*
*****************************************/

CREATE view [dbo].[MSQDPM] as
select a.*,
	'PMCo' = (select JCCo from MSQH with (nolock) where MSQH.MSCo=a.MSCo and MSQH.Quote=a.Quote),
	'Project' = (select Job from MSQH with (nolock) where MSQH.MSCo=a.MSCo and MSQH.Quote=a.Quote),
	'InterfaceDate' = (select max(PMMF.InterfaceDate) from PMMF with (nolock) where PMMF.MSCo=a.MSCo
					and PMMF.Quote=a.Quote and PMMF.Location=a.FromLoc and PMMF.MaterialCode=a.Material
					and PMMF.UM=a.UM and PMMF.Phase=isnull(a.Phase,PMMF.Phase))
from dbo.MSQD a

GO
GRANT SELECT ON  [dbo].[MSQDPM] TO [public]
GRANT INSERT ON  [dbo].[MSQDPM] TO [public]
GRANT DELETE ON  [dbo].[MSQDPM] TO [public]
GRANT UPDATE ON  [dbo].[MSQDPM] TO [public]
GO
