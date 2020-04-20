SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************
* Created By:	GF 10/25/2006 6.x only
* Modfied By:
*
* Provides a view of PM Document History for Submittals
*
*****************************************/

CREATE view [dbo].[PMDHSubmittal] as
select a.DocType as [SubmittalType], a.Document as [Submittal], a.*
from dbo.PMDH a where a.DocCategory = 'SUBMIT'

GO
GRANT SELECT ON  [dbo].[PMDHSubmittal] TO [public]
GRANT INSERT ON  [dbo].[PMDHSubmittal] TO [public]
GRANT DELETE ON  [dbo].[PMDHSubmittal] TO [public]
GRANT UPDATE ON  [dbo].[PMDHSubmittal] TO [public]
GO
