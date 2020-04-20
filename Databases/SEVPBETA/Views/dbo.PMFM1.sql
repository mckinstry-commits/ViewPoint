SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************
   * Created By:
   * Modfied By:
   *
   * Provides a view of PM Responsible Firms
   * Used in document tracking and document tools
   *
   *****************************************/
   
   CREATE view [dbo].[PMFM1] as select a.* From PMFM a

GO
GRANT SELECT ON  [dbo].[PMFM1] TO [public]
GRANT INSERT ON  [dbo].[PMFM1] TO [public]
GRANT DELETE ON  [dbo].[PMFM1] TO [public]
GRANT UPDATE ON  [dbo].[PMFM1] TO [public]
GO
