SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







/*****************************************
* Created By:	GF 10/13/2005 6.x only
* Modfied By:	GF 02/23/2009 - issue #132115
*				GF 04/15/2010 - issue #138434
*
*
* Provides a view of SL Subcontract Items for 6.x
* only to be used in PMSLHeader Interfaced items tab.
* Four alias columns to get max(InterfaceDate), max(SubCO), max(ACO), and max(ACOItem)
* from PMSL to display in grid.
*
*****************************************/

CREATE view [dbo].[SLITPM] as

---- OLD
----select a.*,
----	'PMCo' = a.JCCo,
----	'InterfaceDate' = (select max(PMSL.InterfaceDate) from PMSL with (nolock) where PMSL.SLCo=a.SLCo
----					and PMSL.SL=a.SL and PMSL.SLItem=a.SLItem and PMSL.InterfaceDate is not null),
----	'SubCO' = (select max(PMSL.SubCO) from PMSL with (nolock) where PMSL.SLCo=a.SLCo
----					and PMSL.SL=a.SL and PMSL.SLItem=a.SLItem and PMSL.InterfaceDate is not null),
----	'ACO' = (select max(PMSL.ACO) from PMSL with (nolock) where PMSL.SLCo=a.SLCo
----					and PMSL.SL=a.SL and PMSL.SLItem=a.SLItem and PMSL.InterfaceDate is not null),
----	'ACOItem' = (select max(PMSL.ACOItem) from PMSL with (nolock) where PMSL.SLCo=a.SLCo
----					and PMSL.SL=a.SL and PMSL.SLItem=a.SLItem and PMSL.InterfaceDate is not null)
----from dbo.SLIT a

---- NEW 138434
select a.*,
		a.JCCo as [PMCo],
		m.InterfaceDate as [InterfaceDate],
		m.ACO as [ACO],
		m.ACOItem as [ACOItem],
		m.PCOType as [PCOType],
		m.PCO as [PCO],
		m.PCOItem as [PCOItem],
		m.SubCO as [SubCO]
from dbo.SLIT a
OUTER
APPLY 
dbo.vfSLITWithPMSLInfo (a.SLCo, a.SL, a.SLItem) m










GO
GRANT SELECT ON  [dbo].[SLITPM] TO [public]
GRANT INSERT ON  [dbo].[SLITPM] TO [public]
GRANT DELETE ON  [dbo].[SLITPM] TO [public]
GRANT UPDATE ON  [dbo].[SLITPM] TO [public]
GO
