SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************
   * Created By: DANF
   * Modfied By:
   *
   * Provides a view of JC Progress link Cost Types
   *
   *****************************************/
   
	CREATE view [dbo].[JCPPCostTypesDtl] 
	as
select a.* From dbo.bJCPPCostTypes a

GO
GRANT SELECT ON  [dbo].[JCPPCostTypesDtl] TO [public]
GRANT INSERT ON  [dbo].[JCPPCostTypesDtl] TO [public]
GRANT DELETE ON  [dbo].[JCPPCostTypesDtl] TO [public]
GRANT UPDATE ON  [dbo].[JCPPCostTypesDtl] TO [public]
GO
