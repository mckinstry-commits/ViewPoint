SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   CREATE view [dbo].[brvDistinctEMCD] as
   Select distinct EMCo, EMGroup, Equipment, WorkOrder, WOItem from EMCD
   
  
 



GO
GRANT SELECT ON  [dbo].[brvDistinctEMCD] TO [public]
GRANT INSERT ON  [dbo].[brvDistinctEMCD] TO [public]
GRANT DELETE ON  [dbo].[brvDistinctEMCD] TO [public]
GRANT UPDATE ON  [dbo].[brvDistinctEMCD] TO [public]
GO
