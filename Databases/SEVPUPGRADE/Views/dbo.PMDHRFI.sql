SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************
 * Created By:
 * Modfied By:
 *
 * Provides a view of PM Document History for RFI's
 *
 *****************************************/

CREATE  view [dbo].[PMDHRFI] as
select a.DocType as [RFIType], a.Document as [RFI], a.*
from dbo.PMDH a where a.DocCategory = 'RFI'

GO
GRANT SELECT ON  [dbo].[PMDHRFI] TO [public]
GRANT INSERT ON  [dbo].[PMDHRFI] TO [public]
GRANT DELETE ON  [dbo].[PMDHRFI] TO [public]
GRANT UPDATE ON  [dbo].[PMDHRFI] TO [public]
GO
