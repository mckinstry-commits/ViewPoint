SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************
 * Created By:
 * Modfied By:
 *
 * Provides a view of PM Inspection Firms
 * Used in document tracking
 *
 *****************************************/
   
CREATE view [dbo].[PMFMInsp] as select a.* From PMFM a

GO
GRANT SELECT ON  [dbo].[PMFMInsp] TO [public]
GRANT INSERT ON  [dbo].[PMFMInsp] TO [public]
GRANT DELETE ON  [dbo].[PMFMInsp] TO [public]
GRANT UPDATE ON  [dbo].[PMFMInsp] TO [public]
GO
