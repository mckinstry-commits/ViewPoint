SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************
 * Created By:
 * Modfied By:
 *
 * Provides a view of PM Requesting Firms
 * Used in document tracking
 *
 *****************************************/
   
CREATE view [dbo].[PMFMReq] as select a.* From PMFM a

GO
GRANT SELECT ON  [dbo].[PMFMReq] TO [public]
GRANT INSERT ON  [dbo].[PMFMReq] TO [public]
GRANT DELETE ON  [dbo].[PMFMReq] TO [public]
GRANT UPDATE ON  [dbo].[PMFMReq] TO [public]
GO
