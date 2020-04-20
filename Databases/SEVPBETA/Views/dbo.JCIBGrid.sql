SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************
   * Created By:
   * Modfied By:
   *
   * Provides a view of JC Contract item batch
   *
   *****************************************/
   
   CREATE  view [dbo].[JCIBGrid] as select * from dbo.JCIB with (nolock)

GO
GRANT SELECT ON  [dbo].[JCIBGrid] TO [public]
GRANT INSERT ON  [dbo].[JCIBGrid] TO [public]
GRANT DELETE ON  [dbo].[JCIBGrid] TO [public]
GRANT UPDATE ON  [dbo].[JCIBGrid] TO [public]
GO
