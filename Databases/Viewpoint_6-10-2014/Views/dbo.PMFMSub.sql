SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************
 * Created By:
 * Modfied By:
 *
 * Provides a view of PM Subcontractor Firms
 * Used in document tracking
 *
 *****************************************/
   
CREATE view [dbo].[PMFMSub] as select a.* From PMFM a

GO
GRANT SELECT ON  [dbo].[PMFMSub] TO [public]
GRANT INSERT ON  [dbo].[PMFMSub] TO [public]
GRANT DELETE ON  [dbo].[PMFMSub] TO [public]
GRANT UPDATE ON  [dbo].[PMFMSub] TO [public]
GRANT SELECT ON  [dbo].[PMFMSub] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMFMSub] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMFMSub] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMFMSub] TO [Viewpoint]
GO
