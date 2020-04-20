SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************
 * Created By:
 * Modfied By:
 *
 * Provides a view of PM Architect/Engineer Firms
 * Used in document tracking
 *
 *****************************************/
   
CREATE view [dbo].[PMFMArch] as select a.* From PMFM a

GO
GRANT SELECT ON  [dbo].[PMFMArch] TO [public]
GRANT INSERT ON  [dbo].[PMFMArch] TO [public]
GRANT DELETE ON  [dbo].[PMFMArch] TO [public]
GRANT UPDATE ON  [dbo].[PMFMArch] TO [public]
GRANT SELECT ON  [dbo].[PMFMArch] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMFMArch] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMFMArch] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMFMArch] TO [Viewpoint]
GO
