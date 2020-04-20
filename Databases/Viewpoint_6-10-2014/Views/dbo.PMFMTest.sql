SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************
 * Created By:
 * Modfied By:
 *
 * Provides a view of PM Test Firms
 * Used in document tracking
 *
 *****************************************/
   
CREATE view [dbo].[PMFMTest] as select a.* From PMFM a

GO
GRANT SELECT ON  [dbo].[PMFMTest] TO [public]
GRANT INSERT ON  [dbo].[PMFMTest] TO [public]
GRANT DELETE ON  [dbo].[PMFMTest] TO [public]
GRANT UPDATE ON  [dbo].[PMFMTest] TO [public]
GRANT SELECT ON  [dbo].[PMFMTest] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMFMTest] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMFMTest] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMFMTest] TO [Viewpoint]
GO
