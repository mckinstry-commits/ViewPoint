SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************
* Created By:	GF 11/10/2006 6.x only
* Modfied By:
*
* Provides a view of PM Document History for PCO's in 6.x
* Need to alias DocType as [PCOType] and Document as [PCO]
* so that PM PCO Document History can be on a related tab in 
* PM Change Order form.
*
*****************************************/

CREATE view [dbo].[PMDHPCO] as
select a.DocType as [PCOType], a.Document as [PCO], a.*
from dbo.PMDH a where a.DocCategory = 'PCO'

GO
GRANT SELECT ON  [dbo].[PMDHPCO] TO [public]
GRANT INSERT ON  [dbo].[PMDHPCO] TO [public]
GRANT DELETE ON  [dbo].[PMDHPCO] TO [public]
GRANT UPDATE ON  [dbo].[PMDHPCO] TO [public]
GO
