SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
 
 
 CREATE  view [dbo].[brvINAllocInventory] as
  select INCo, MO, MOItem, Loc, MatlGroup, Material, 
         JCCo, Job, PhaseGroup, Phase, 
         ReqDate, UM, isnull(dbo.bfINUMConv(INMI.MatlGroup,INMI.Material, INMI.INCo, INMI.Loc, 
            INMI.UM),0) as 'UM_Conv',
         OrderedUnits, ConfirmedUnits, RemainUnits,
         MSCo=NULL, MSQuote = NULL,MSQD_OrderUnits=0, MSQD_SoldUnits=0,Record='INMI'
  from INMI 
  
  
  UNION ALL
  
  select MSQH.MSCo, NULL, NULL, MSQD.FromLoc, MSQD.MatlGroup, MSQD.Material,
         MSQH.JCCo, MSQH.Job, MSQD.PhaseGroup, MSQD.Phase,
         MSQD.ReqDate, MSQD.UM,
         isnull(dbo.bfINUMConv(MSQD.MatlGroup,MSQD.Material, MSQH.INCo, MSQD.FromLoc, MSQD.UM),0) as 'UM_Conv',
         0,0, 0,
         MSQD.MSCo,MSQD.Quote,MSQD.OrderUnits, MSQD.SoldUnits,Record='MSQD'
  from MSQD
        join MSQH on MSQD.MSCo=MSQH.MSCo and MSQD.Quote= MSQH.Quote
  where MSQD.Status = 1
  
  
 
 



GO
GRANT SELECT ON  [dbo].[brvINAllocInventory] TO [public]
GRANT INSERT ON  [dbo].[brvINAllocInventory] TO [public]
GRANT DELETE ON  [dbo].[brvINAllocInventory] TO [public]
GRANT UPDATE ON  [dbo].[brvINAllocInventory] TO [public]
GO
