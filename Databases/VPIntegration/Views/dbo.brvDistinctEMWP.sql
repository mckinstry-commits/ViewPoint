SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   CREATE view [dbo].[brvDistinctEMWP] as
   Select distinct EMCo, EMGroup, Equipment, WorkOrder, WOItem from EMWP
   
  
 



GO
GRANT SELECT ON  [dbo].[brvDistinctEMWP] TO [public]
GRANT INSERT ON  [dbo].[brvDistinctEMWP] TO [public]
GRANT DELETE ON  [dbo].[brvDistinctEMWP] TO [public]
GRANT UPDATE ON  [dbo].[brvDistinctEMWP] TO [public]
GO
