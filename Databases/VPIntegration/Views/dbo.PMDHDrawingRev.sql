SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************
 * Created By:	GP 4/17/2008
 * Modfied By:	
 *
 * Provides a view of PM Document History for the Drawing logs History tab
 *
 *****************************************/
 
CREATE  view [dbo].[PMDHDrawingRev] as
select a.DocType as [DrawingType], a.Document as [Drawing], a.PMCo, a.Project, a.DocType, Document, 
a.Seq, a.ActionDateTime, a.Action, a.UniqueAttchID, a.DocCategory, a.FieldType, a.FieldName, 
a.OldValue, a.NewValue, a.UserName, a.AssignToDoc, a.Item, a.PCOItem, a.RFQPCO, a.ACOItem, 
a.DrawingRev as [Rev]
From dbo.PMDH a where a.DocCategory = 'DRAWING'

GO
GRANT SELECT ON  [dbo].[PMDHDrawingRev] TO [public]
GRANT INSERT ON  [dbo].[PMDHDrawingRev] TO [public]
GRANT DELETE ON  [dbo].[PMDHDrawingRev] TO [public]
GRANT UPDATE ON  [dbo].[PMDHDrawingRev] TO [public]
GO
