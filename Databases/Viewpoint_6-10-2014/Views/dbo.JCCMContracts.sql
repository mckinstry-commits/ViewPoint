SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************
   * Created By:
   * Modfied By:
   *
   * Provides a view of JC contract master not pending
   *
   *****************************************/
   
   CREATE  view [dbo].[JCCMContracts] as select a.* From dbo.JCCM a where a.ContractStatus > 0

GO
GRANT SELECT ON  [dbo].[JCCMContracts] TO [public]
GRANT INSERT ON  [dbo].[JCCMContracts] TO [public]
GRANT DELETE ON  [dbo].[JCCMContracts] TO [public]
GRANT UPDATE ON  [dbo].[JCCMContracts] TO [public]
GRANT SELECT ON  [dbo].[JCCMContracts] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCCMContracts] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCCMContracts] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCCMContracts] TO [Viewpoint]
GO
