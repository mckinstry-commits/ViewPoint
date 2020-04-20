SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************
 * Created By:
 * Modfied By:
 *
 * Provides a view of PM Document History for other documents
 *
 *****************************************/

CREATE  view [dbo].[PMDHOther] as
select a.*
from dbo.PMDH a where a.DocCategory = 'OTHER'

GO
GRANT SELECT ON  [dbo].[PMDHOther] TO [public]
GRANT INSERT ON  [dbo].[PMDHOther] TO [public]
GRANT DELETE ON  [dbo].[PMDHOther] TO [public]
GRANT UPDATE ON  [dbo].[PMDHOther] TO [public]
GO
