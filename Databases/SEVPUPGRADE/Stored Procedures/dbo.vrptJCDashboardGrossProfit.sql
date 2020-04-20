SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE       proc [dbo].[vrptJCDashboardGrossProfit] 
(@JCCo tinyint,  @Department varchar(10), @ContStatus char, @BegCont bContract, @EndCont bContract )

as
/*
  Stored Procedure for the Dashboard Gross Profit subreport 
   Created 9/21/06 CR
   Modified 10/1/07 Added the Contract Status and Beg/End Contract Parameters CR Issue 125026         
      
   Reports that use: GrossProfit.rpt

*/
declare @i tinyint

create table #Mth

(Mth smalldatetime null)

create table #ItemMth
(JCCo tinyint null,
 Contract varchar(10) null,
 Item varchar(16) null,
 Mth smalldatetime null)

select @i=1

While @i <=12

begin

  Insert into #Mth
  (Mth)
  select dateadd(Month, @i-12, DATEADD(d,DATEDIFF(d,0,GETDATE()),0) - (Day(DATEADD(d,DATEDIFF(d,0,GETDATE()),0))-1)
)
  Select @i = @i+1

end

insert into #ItemMth
(JCCo, Contract, Item, Mth)

Select JCCI.JCCo, JCCI.Contract, JCCI.Item, #Mth.Mth
 From JCCI WITH (NOLOCK)
 Cross Join #Mth
 Where JCCI.JCCo=@JCCo and JCCI.Department=@Department


select #ItemMth.JCCo, Section=1, JCCI.Department, JCDM.Description, JCCI.Contract, ContDesc=JCCM.Description, Status=JCCM.ContractStatus, JCCI.Item, Mth=#ItemMth.Mth,
       ProjMth=(select isnull(min(i.Mth),'12/1/2050') from JCIP i with (nolock)
              where JCCI.JCCo=i.JCCo and JCCI.Contract=i.Contract and JCCI.Item=i.Item and (i.ProjDollars <>0 or i.ProjPlug='Y')),
       PrevContractAmt=(select sum(i.ContractAmt) from JCIP i with (nolock)
              where JCCI.JCCo=i.JCCo and JCCI.Contract=i.Contract and JCCI.Item=i.Item and i.Mth<#ItemMth.Mth),
       ContractAmt=isnull(BegContract,0)+isnull(JCIP.ContractAmt,0),
       ContractAmtRT=isnull(JCIP.ContractAmt,0),
       PrevProjDollars=(select sum(i.ProjDollars) from JCIP i with (nolock)
              where JCCI.JCCo=i.JCCo and JCCI.Contract=i.Contract and JCCI.Item=i.Item and i.Mth<#ItemMth.Mth),
       ProjDollars=isnull(BegProjDollars,0)+isnull(JCIP.ProjDollars,0),
       PrevProjCost=(select sum(p.ProjCost) From JCCP p With (NoLock)
                              Join JCJP j With (NoLock) on j.JCCo=p.JCCo and j.Job=p.Job and j.PhaseGroup=p.PhaseGroup and j.Phase=p.Phase
                              Where j.JCCo=JCCI.JCCo and j.Contract=JCCI.Contract and j.Item=JCCI.Item and p.Mth<#ItemMth.Mth),
       ProjCostRT=isnull(JCCP.ProjCost,0),
       ProjCost=isnull(BegProjCost,0)+isnull(JCCP.ProjCost,0),
       CurrEstCost=isnull(BegCurrEstCost,0)+isnull(JCCP.CurrEstCost,0),
       BilledAmt=isnull(BegBilled,0)+isnull(JCIP.BilledAmt,0),
       ActualCost=isnull(BegActualCost,0)+isnull(JCCP.ActualCost,0),
       RemainCtdCost=isnull(BegRemainCtdCost,0)+isnull(JCCP.RemainCtdCost,0),
       Retainage=isnull(BegRetainage,0)+isnull(JCIP.Retainage,0),
       ReceivedAmt=isnull(BegReceivedAmt,0)+isnull(JCIP.ReceivedAmt,0),
       CompDate=JCCM.ProjCloseDate,
       JCCM.ContractStatus

From #ItemMth
 Join JCCI WITH (NOLOCK) on JCCI.JCCo=#ItemMth.JCCo and JCCI.Contract=#ItemMth.Contract and JCCI.Item=#ItemMth.Item
 Join JCDM on JCDM.JCCo=JCCI.JCCo and JCDM.Department=JCCI.Department
 Join JCCM on JCCM.JCCo=JCCI.JCCo and JCCM.Contract=JCCI.Contract

  -- Revenue   	
       left join (select JCIP.JCCo, JCIP.Contract, JCIP.Item, JCIP.Mth,
                    ContractAmt=sum(JCIP.ContractAmt),
                    ProjDollars=sum(JCIP.ProjDollars),
                    BilledAmt=sum(JCIP.BilledAmt),
                    Retainage=sum(JCIP.CurrentRetainAmt),
                    ReceivedAmt=sum(JCIP.ReceivedAmt)
                    from JCIP WITH (NOLOCK)
                    join JCCI WITH (NOLOCK) on JCCI.JCCo=JCIP.JCCo and JCCI.Contract=JCIP.Contract and JCCI.Item=JCIP.Item
                    
                    where JCIP.JCCo=@JCCo and JCIP.Mth>dateadd(Month, -12,
                       DATEADD(d,DATEDIFF(d,0,GETDATE()),0) - (Day(DATEADD(d,DATEDIFF(d,0,GETDATE()),0))-1)) 
                      and JCIP.Mth<= DATEADD(d,DATEDIFF(d,0,GETDATE()),0) - (Day(DATEADD(d,DATEDIFF(d,0,GETDATE()),0))-1) and JCCI.Department=@Department
                      
                    group by JCIP.JCCo, JCIP.Contract, JCIP.Item, JCIP.Mth, JCIP.ProjDollars) 
           as JCIP on JCIP.JCCo=#ItemMth.JCCo and JCIP.Contract=#ItemMth.Contract and JCIP.Item=#ItemMth.Item and JCIP.Mth=#ItemMth.Mth
   
   -- Cost
        left join (select JCJP.JCCo, JCJP.Contract, JCJP.Item, JCCP.Mth,
                     CurrEstCost=sum(JCCP.CurrEstCost),
                     ProjCost=sum(JCCP.ProjCost),
                     RemainCtdCost=sum(JCCP.RemainCmtdCost),
                     ActualCost=sum(JCCP.ActualCost)
                     from JCCP WITH (NOLOCK)
                     join JCJP WITH (NOLOCK) on JCJP.JCCo=JCCP.JCCo and JCJP.Job=JCCP.Job and JCJP.PhaseGroup=JCCP.PhaseGroup
                                                              and JCJP.Phase=JCCP.Phase
                     join JCCI WITH (NOLOCK) on JCCI.JCCo=JCJP.JCCo and JCCI.Contract=JCJP.Contract and JCCI.Item=JCJP.Item
                     
                     where JCJP.JCCo=@JCCo and JCCP.Mth > dateadd(Month, -12,  DATEADD(d,DATEDIFF(d,0,GETDATE()),0) - (Day(DATEADD(d,DATEDIFF(d,0,GETDATE()),0))-1)) 
                     and JCCP.Mth<= DATEADD(d,DATEDIFF(d,0,GETDATE()),0) - (Day(DATEADD(d,DATEDIFF(d,0,GETDATE()),0))-1) and JCCI.Department=@Department

                     group by JCJP.JCCo, JCJP.Contract, JCJP.Item, JCCP.Mth) 
           as JCCP on JCCP.JCCo=#ItemMth.JCCo and JCCP.Contract=#ItemMth.Contract and JCCP.Item=#ItemMth.Item and JCCP.Mth=#ItemMth.Mth

 --Beg Balances for Contract Item Amounts
        left join (select JCIP.JCCo, JCIP.Contract, JCIP.Item, Mth=dateadd(Month, -11,  DATEADD(d,DATEDIFF(d,0,GETDATE()),0) - (Day(DATEADD(d,DATEDIFF(d,0,GETDATE()),0))-1)),
                      BegContract=sum(JCIP.ContractAmt),
                      BegProjDollars=0,/*sum(JCIP.ProjDollars),*/
                      BegBilled=sum(JCIP.BilledAmt),
                      BegRetainage=sum(JCIP.CurrentRetainAmt),
                      BegReceivedAmt=sum(JCIP.ReceivedAmt)
                      from JCIP WITH (NOLOCK)
                       join JCCI WITH (NOLOCK) on JCCI.JCCo=JCIP.JCCo and JCCI.Contract=JCIP.Contract and JCCI.Item=JCIP.Item
                       
                      where JCIP.Mth<=dateadd(Month, -12, DATEADD(d,DATEDIFF(d,0,GETDATE()),0) - (Day(DATEADD(d,DATEDIFF(d,0,GETDATE()),0))-1)) and JCCI.Department=@Department
                        
                      group by JCIP.JCCo, JCIP.Contract, JCIP.Item) 
          as BegItem on BegItem.JCCo=#ItemMth.JCCo and BegItem.Contract=#ItemMth.Contract and BegItem.Item=#ItemMth.Item and BegItem.Mth=#ItemMth.Mth

--Beg Balances for Costs
        left join (select JCJP.JCCo, JCJP.Contract, JCJP.Item, Mth=dateadd(Month, -11, DATEADD(d,DATEDIFF(d,0,GETDATE()),0) - (Day(DATEADD(d,DATEDIFF(d,0,GETDATE()),0))-1)),
                     BegCurrEstCost=sum(JCCP.CurrEstCost),
                     BegProjCost=sum(JCCP.ProjCost),
                     BegRemainCtdCost=sum(JCCP.RemainCmtdCost),
                     BegActualCost=sum(JCCP.ActualCost)
                     from JCCP WITH (NOLOCK)
                     join JCJP WITH (NOLOCK) on JCJP.JCCo=JCCP.JCCo and JCJP.Job=JCCP.Job and JCJP.PhaseGroup=JCCP.PhaseGroup
                            and JCJP.Phase=JCCP.Phase 

                      join JCCI WITH (NOLOCK) on JCCI.JCCo=JCJP.JCCo and JCCI.Contract=JCJP.Contract and JCCI.Item=JCJP.Item
                     where JCCP.Mth<=dateadd(Month, -12,  DATEADD(d,DATEDIFF(d,0,GETDATE()),0) - (Day(DATEADD(d,DATEDIFF(d,0,GETDATE()),0))-1)) and JCCI.Department=@Department

                     group by JCJP.JCCo, JCJP.Contract, JCJP.Item) 
          as BegCost on BegCost.JCCo=#ItemMth.JCCo and BegCost.Contract=#ItemMth.Contract and BegCost.Item=#ItemMth.Item and BegCost.Mth=#ItemMth.Mth

Where #ItemMth.JCCo=@JCCo and JCCI.JCCo=@JCCo and JCCI.Department=@Department and  
         #ItemMth.Contract >= @BegCont and #ItemMth.Contract<=@EndCont
and ((case when @ContStatus='C' then JCCM.ContractStatus end= 2
    or
      case when @ContStatus='C' then JCCM.ContractStatus end = 3)
OR
JCCM.ContractStatus=case when @ContStatus = 'O' then 1 
                    when @ContStatus = 'A' then  JCCM.ContractStatus  end)

GO
GRANT EXECUTE ON  [dbo].[vrptJCDashboardGrossProfit] TO [public]
GO
