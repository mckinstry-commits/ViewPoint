SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************
 * Created By:	GF 04/17/2006 6.x only
 * Modfied By:
 *
 * Provides a view of PM Notes Review for a
 * Distinct Reviewer. 6.x only, needed for
 * PMNotesReview header one record per reviewer. 
 *
 *****************************************/
 
CREATE view [dbo].[PMNRReviewer] as
select Distinct PMCo, Reviewer
from PMNR

GO
GRANT SELECT ON  [dbo].[PMNRReviewer] TO [public]
GRANT INSERT ON  [dbo].[PMNRReviewer] TO [public]
GRANT DELETE ON  [dbo].[PMNRReviewer] TO [public]
GRANT UPDATE ON  [dbo].[PMNRReviewer] TO [public]
GO
