SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*****************************************
   * Created By:
   * Modfied By:
   *
   * Provides a view of JC contract items
   * used in JCCI form for grid display
   *
   *****************************************/
   
   CREATE view [dbo].[JCCIGrid] as 
   select JCCo, Contract, Item, SICode, Description, UM, OrigContractUnits, OrigUnitPrice, OrigContractAmt
   from dbo.JCCI


GO
GRANT SELECT ON  [dbo].[JCCIGrid] TO [public]
GRANT INSERT ON  [dbo].[JCCIGrid] TO [public]
GRANT DELETE ON  [dbo].[JCCIGrid] TO [public]
GRANT UPDATE ON  [dbo].[JCCIGrid] TO [public]
GRANT SELECT ON  [dbo].[JCCIGrid] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCCIGrid] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCCIGrid] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCCIGrid] TO [Viewpoint]
GO
