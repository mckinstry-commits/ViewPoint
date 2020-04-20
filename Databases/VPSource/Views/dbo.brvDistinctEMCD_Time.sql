SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   CREATE view [dbo].[brvDistinctEMCD_Time] as
   Select distinct EMCo, EMGroup, Equipment, WorkOrder, WOItem from EMCD
   where Source in ( 'EMTime','PR')
   
  
 



GO
GRANT SELECT ON  [dbo].[brvDistinctEMCD_Time] TO [public]
GRANT INSERT ON  [dbo].[brvDistinctEMCD_Time] TO [public]
GRANT DELETE ON  [dbo].[brvDistinctEMCD_Time] TO [public]
GRANT UPDATE ON  [dbo].[brvDistinctEMCD_Time] TO [public]
GO
