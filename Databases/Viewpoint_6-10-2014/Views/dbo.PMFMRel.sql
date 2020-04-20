SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************
 * Created By:
 * Modfied By:
 *
 * Provides a view of PM Related Firms
 * Used in document tracking
 *
 *****************************************/
   
CREATE view [dbo].[PMFMRel] as select a.* From PMFM a

GO
GRANT SELECT ON  [dbo].[PMFMRel] TO [public]
GRANT INSERT ON  [dbo].[PMFMRel] TO [public]
GRANT DELETE ON  [dbo].[PMFMRel] TO [public]
GRANT UPDATE ON  [dbo].[PMFMRel] TO [public]
GRANT SELECT ON  [dbo].[PMFMRel] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMFMRel] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMFMRel] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMFMRel] TO [Viewpoint]
GO
