SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  view [dbo].[brvSLChangeOrders] as
 
 select SLCD.SLCo, SLCD.SL, SLCD.SLItem, SLIT2.OrigCost, SLCD.SLChangeOrder, SLCD.AppChangeOrder,
 SLCD.ActDate, SLCD.Description, SLCD.UM, SLCD.ChangeCurUnits, SLCD.ChangeCurUnitCost, SLCD.Notes,
 SLCD.ChangeCurCost, SLIT.JCCo, SLIT.Job, SLIT.PhaseGroup, SLIT.Phase, SLIT.CurUnits, SLIT.CurUnitCost,
 PrevCost = (select sum(ChangeCurCost) 
             from SLCD PrevSLCD 
             where PrevSLCD.SLCo = SLCD.SLCo and PrevSLCD.SL= SLCD.SL and PrevSLCD.SLChangeOrder < SLCD.SLChangeOrder)
 from SLCD
 join (select SLIT.SLCo, SLIT.SL, sum(SLIT.OrigCost) as 'OrigCost'
         from SLIT where SLIT.ItemType <> 3 group by SLIT.SLCo, SLIT.SL) as SLIT2
         on SLCD.SLCo= SLIT2.SLCo and SLCD.SL = SLIT2.SL 
 left outer join SLIT on SLCD.SLCo = SLIT.SLCo and SLCD.SL = SLIT.SL and SLIT.SLItem = SLCD.SLItem
 
 

GO
GRANT SELECT ON  [dbo].[brvSLChangeOrders] TO [public]
GRANT INSERT ON  [dbo].[brvSLChangeOrders] TO [public]
GRANT DELETE ON  [dbo].[brvSLChangeOrders] TO [public]
GRANT UPDATE ON  [dbo].[brvSLChangeOrders] TO [public]
GO
