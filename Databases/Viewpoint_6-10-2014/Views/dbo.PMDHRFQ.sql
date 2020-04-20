SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************
 * Created By:
 * Modfied By:
 *
 * Provides a view of PM Document History for RFQ's
 *
 *****************************************/

CREATE  view [dbo].[PMDHRFQ] as
select a.DocType as [PCOType], a.RFQPCO as [PCO], a.Document as [RFQ], a.*
from dbo.PMDH a where a.DocCategory = 'RFQ'

GO
GRANT SELECT ON  [dbo].[PMDHRFQ] TO [public]
GRANT INSERT ON  [dbo].[PMDHRFQ] TO [public]
GRANT DELETE ON  [dbo].[PMDHRFQ] TO [public]
GRANT UPDATE ON  [dbo].[PMDHRFQ] TO [public]
GRANT SELECT ON  [dbo].[PMDHRFQ] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMDHRFQ] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMDHRFQ] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMDHRFQ] TO [Viewpoint]
GO
