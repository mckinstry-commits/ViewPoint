SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*****************************************
* Created By:	GF 12/10/2006 6.x only
* Modfied By:
*
* Provides a view of PM Document History for ACO's in 6.x
* Need to alias Document as [ACO]
* so that PM ACO Document History can be on a related tab in 
* PM ACO Change Order form.
*
*****************************************/

CREATE view [dbo].[PMDHACO] as
select a.Document as [ACO], a.*
from dbo.PMDH a where a.DocCategory = 'ACO'


GO
GRANT SELECT ON  [dbo].[PMDHACO] TO [public]
GRANT INSERT ON  [dbo].[PMDHACO] TO [public]
GRANT DELETE ON  [dbo].[PMDHACO] TO [public]
GRANT UPDATE ON  [dbo].[PMDHACO] TO [public]
GRANT SELECT ON  [dbo].[PMDHACO] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMDHACO] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMDHACO] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMDHACO] TO [Viewpoint]
GO
