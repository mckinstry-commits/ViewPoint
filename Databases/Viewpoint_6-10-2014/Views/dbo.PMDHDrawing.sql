SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************
 * Created By:	GF 11/10/2006
 * Modfied By:	GP 4/16/2008
 *
 * Provides a view of PM Document History for Drawing logs
 *
 *****************************************/
 
CREATE  view [dbo].[PMDHDrawing] as
select a.DocType as [DrawingType], a.Document as [Drawing], a.*
From dbo.PMDH a where a.DocCategory = 'DRAWING'

GO
GRANT SELECT ON  [dbo].[PMDHDrawing] TO [public]
GRANT INSERT ON  [dbo].[PMDHDrawing] TO [public]
GRANT DELETE ON  [dbo].[PMDHDrawing] TO [public]
GRANT UPDATE ON  [dbo].[PMDHDrawing] TO [public]
GRANT SELECT ON  [dbo].[PMDHDrawing] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMDHDrawing] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMDHDrawing] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMDHDrawing] TO [Viewpoint]
GO
