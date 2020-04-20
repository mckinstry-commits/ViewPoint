SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************
 * Created By:	GF 11/11/2006
 * Modfied By:
 *
 * Provides a view of PM Document History for inspection logs
 *
 *****************************************/
 
CREATE  view [dbo].[PMDHInspect] as
select a.DocType as [InspectionType], a.Document as [InspectionCode], a.*
From dbo.PMDH a where a.DocCategory = 'INSPECT'

GO
GRANT SELECT ON  [dbo].[PMDHInspect] TO [public]
GRANT INSERT ON  [dbo].[PMDHInspect] TO [public]
GRANT DELETE ON  [dbo].[PMDHInspect] TO [public]
GRANT UPDATE ON  [dbo].[PMDHInspect] TO [public]
GO
