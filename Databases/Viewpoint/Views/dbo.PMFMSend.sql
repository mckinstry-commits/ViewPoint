SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************
 * Created By:
 * Modfied By:
 *
 * Provides a view of PM Send to Firms
 * Used in document tracking
 *
 *****************************************/
   
CREATE view [dbo].[PMFMSend] as select a.* From PMFM a

GO
GRANT SELECT ON  [dbo].[PMFMSend] TO [public]
GRANT INSERT ON  [dbo].[PMFMSend] TO [public]
GRANT DELETE ON  [dbo].[PMFMSend] TO [public]
GRANT UPDATE ON  [dbo].[PMFMSend] TO [public]
GO
