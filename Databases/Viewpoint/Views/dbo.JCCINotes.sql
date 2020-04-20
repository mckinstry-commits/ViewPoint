SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*****************************************
   * Created By:
   * Modfied By:
   *
   * Provides a view of JC contract item notes
   *
   *****************************************/
   
   CREATE view [dbo].[JCCINotes] as select JCCI.JCCo, JCCI.Contract, JCCI.Item, JCCI.Notes from dbo.JCCI


GO
GRANT SELECT ON  [dbo].[JCCINotes] TO [public]
GRANT INSERT ON  [dbo].[JCCINotes] TO [public]
GRANT DELETE ON  [dbo].[JCCINotes] TO [public]
GRANT UPDATE ON  [dbo].[JCCINotes] TO [public]
GO
