SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   CREATE  view [dbo].[brvPOChgOrderSummary] as
   
   select POCD.POCo, POCD.PO, POCD.POItem, POIT2.OrigCost, POCD.ChangeOrder, 
   POCD.ActDate, POCD.Description, POCD.UM, POCD.ChangeCurUnits, POCD.CurUnitCost, POCD.ECM, POCD.Notes,
   POCD.ChgTotCost, 
   PrevCost = (select sum(ChgTotCost) 
               from POCD PrevPOCD 
               where PrevPOCD.POCo = POCD.POCo and PrevPOCD.PO= POCD.PO and PrevPOCD.ChangeOrder < POCD.ChangeOrder)
   from POCD
   join (select POIT.POCo, POIT.PO, sum(POIT.OrigCost) as 'OrigCost'
           from POIT group by POIT.POCo, POIT.PO) as POIT2
           on POCD.POCo= POIT2.POCo and POCD.PO = POIT2.PO 
   
   
   
  
 



GO
GRANT SELECT ON  [dbo].[brvPOChgOrderSummary] TO [public]
GRANT INSERT ON  [dbo].[brvPOChgOrderSummary] TO [public]
GRANT DELETE ON  [dbo].[brvPOChgOrderSummary] TO [public]
GRANT UPDATE ON  [dbo].[brvPOChgOrderSummary] TO [public]
GO
