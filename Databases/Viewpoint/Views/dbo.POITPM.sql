SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*****************************************
* Created By:	GF 09/08/2006 6.x only
* Modfied By:	GF 02/23/2009 - issue #132115
*				GF 04/15/2010 - issue #138434
*				GF 06/27/2011 - TK-06437
*
*
* Provides a view of PO Items for 6.x
* only to be used in PMPOHeader Interfaced items tab.
* Alias POIT.JCCo as [PMCo] for joins.
* Added a in-line table valued function that
* is used with a CROSS APPLY to return PMMF
* information.
*
*****************************************/

CREATE view [dbo].[POITPM] as

---- OLD
----select a.*,
----	'PMCo' = a.PostToCo,
----	'InterfaceDate' = (select max(b.InterfaceDate) from dbo.bPMMF b with (nolock) where b.POCo=a.POCo
----					and b.PO=a.PO and b.POItem=a.POItem and b.InterfaceDate is not null),
----	'ACO' = (select max(c.ACO) from dbo.bPMMF c with (nolock) where c.POCo=a.POCo
----					and c.PO=a.PO and c.POItem=a.POItem and c.InterfaceDate is not null),
----	'ACOItem' = (select max(d.ACOItem) from dbo.bPMMF d with (nolock) where d.POCo=a.POCo
----					and d.PO=a.PO and d.POItem=a.POItem and d.InterfaceDate is not null)
----from dbo.POIT a

---- NEW 138434
select a.*,
		a.PostToCo as [PMCo],
		m.InterfaceDate as [InterfaceDate],
		m.ACO as [ACO],
		m.ACOItem as [ACOItem],
		m.PCOType as [PCOType],
		m.PCO as [PCO],
		m.PCOItem as [PCOItem],
		----TK-06437
		m.POCONum as [POCONum]
from dbo.POIT a
OUTER
APPLY 
dbo.vfPOITWithPMMFInfo (a.POCo, a.PO, a.POItem) m
	








GO
GRANT SELECT ON  [dbo].[POITPM] TO [public]
GRANT INSERT ON  [dbo].[POITPM] TO [public]
GRANT DELETE ON  [dbo].[POITPM] TO [public]
GRANT UPDATE ON  [dbo].[POITPM] TO [public]
GO
