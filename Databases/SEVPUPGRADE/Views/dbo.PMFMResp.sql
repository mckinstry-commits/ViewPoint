SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************
 * Created By:
 * Modfied By:
 *
 * Provides a view of PM Responsible Firms
 * Used in document tracking
 *
 *****************************************/
   
CREATE view [dbo].[PMFMResp] as select a.* From PMFM a

GO
GRANT SELECT ON  [dbo].[PMFMResp] TO [public]
GRANT INSERT ON  [dbo].[PMFMResp] TO [public]
GRANT DELETE ON  [dbo].[PMFMResp] TO [public]
GRANT UPDATE ON  [dbo].[PMFMResp] TO [public]
GO
