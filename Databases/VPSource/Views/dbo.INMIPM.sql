SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*****************************************
* Created By:	GF 09/13/2006 6.x only
* Modfied By:	GF 02/23/2009 - issue #132115
*				GF 04/15/2010 - issue #138434
*
*
* Provides a view of IN MO Items for 6.x
* only to be used in PMMOHeader Interfaced items tab.
* Alias INMI.JCCo as [PMCo] and INMI.Job as [Project] for joins.
* Added a in-line table valued function that
* is used with a CROSS APPLY to return PMMF
* information.
*
*****************************************/

CREATE view [dbo].[INMIPM] as

---- OLD
----select a.*,
----	'PMCo' = a.JCCo, 'Project' = a.Job,
----	'InterfaceDate' = (select max(PMMF.InterfaceDate) from PMMF with (nolock) where PMMF.INCo=a.INCo
----					and PMMF.MO=a.MO and PMMF.MOItem=a.MOItem),
----	'ACO' = (select max(PMMF.ACO) from PMMF with (nolock) where PMMF.INCo=a.INCo
----					and PMMF.MO=a.MO and PMMF.MOItem=a.MOItem),
----	'ACOItem' = (select max(PMMF.ACOItem) from PMMF with (nolock) where PMMF.INCo=a.INCo
----					and PMMF.MO=a.MO and PMMF.MOItem=a.MOItem)

----from dbo.INMI a

---- NEW 138434
select a.*,
		a.JCCo as [PMCo],
		a.Job as [Project],
		m.InterfaceDate as [InterfaceDate],
		m.ACO as [ACO],
		m.ACOItem as [ACOItem],
		m.PCOType as [PCOType],
		m.PCO as [PCO],
		m.PCOItem as [PCOItem]
from dbo.INMI a
OUTER
APPLY 
dbo.vfINMIWithPMMFInfo (a.INCo, a.MO, a.MOItem) m




GO
GRANT SELECT ON  [dbo].[INMIPM] TO [public]
GRANT INSERT ON  [dbo].[INMIPM] TO [public]
GRANT DELETE ON  [dbo].[INMIPM] TO [public]
GRANT UPDATE ON  [dbo].[INMIPM] TO [public]
GO
