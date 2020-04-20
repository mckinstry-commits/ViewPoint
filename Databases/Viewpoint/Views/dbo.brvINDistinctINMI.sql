SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   CREATE view [dbo].[brvINDistinctINMI] as
   select distinct INCo, MO, MOItem, Loc, MatlGroup, Material from INMI
   
   
  
 



GO
GRANT SELECT ON  [dbo].[brvINDistinctINMI] TO [public]
GRANT INSERT ON  [dbo].[brvINDistinctINMI] TO [public]
GRANT DELETE ON  [dbo].[brvINDistinctINMI] TO [public]
GRANT UPDATE ON  [dbo].[brvINDistinctINMI] TO [public]
GO
