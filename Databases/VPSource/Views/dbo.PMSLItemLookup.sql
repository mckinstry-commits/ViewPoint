SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*****************************************
* Created By:	GF 09/30/2008
* Modfied By:
*
* Provides a view of PM Subcontract Detail used
* in PM SL Items form for lookup on SL items
*
*****************************************/

CREATE view [dbo].[PMSLItemLookup] as 
select a.SLCo, a.SL, a.SLItem, MIN(a.Description) AS [Description]
from dbo.SLIT a
Group by a.SLCo, a.SL, a.SLItem ----, a.Description
union
select b.SLCo, b.SL, b.SLItem, MIN(b.SLItemDescription) AS [Description]
from dbo.PMSL b
where not exists(select * from SLIT c where c.SLCo=b.SLCo and c.SL=b.SL and c.SLItem=b.SLItem)
Group by b.SLCo, b.SL, b.SLItem ----, b.SLItemDescription


GO
GRANT SELECT ON  [dbo].[PMSLItemLookup] TO [public]
GRANT INSERT ON  [dbo].[PMSLItemLookup] TO [public]
GRANT DELETE ON  [dbo].[PMSLItemLookup] TO [public]
GRANT UPDATE ON  [dbo].[PMSLItemLookup] TO [public]
GO
