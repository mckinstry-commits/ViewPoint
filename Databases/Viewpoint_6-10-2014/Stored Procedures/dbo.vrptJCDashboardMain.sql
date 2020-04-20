SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE        proc [dbo].[vrptJCDashboardMain]

(@Company bCompany, @Dept bDept=null, @Dept2 bDept=null, @Dept3 bDept=null, @Dept4 bDept=null, @Dept5 bDept=null,
 @LaborCostType bJCCType, @SubCostType bJCCType, @ContStatus char, @BegCont bContract, @EndCont bContract)

as
/*
  Stored Procedure for the Dashboard report main page
   Created 9/21/06 CR
   Modified 10/1/07 Added the Contract Status and Beg/End Contract Parameters CR Issue 125026         

   Reports that use: JCDashboard.rpt
*/



create table #Dept
(JCCo tinyint null,
Dept varchar(10) null)

--if  @Dept is not null or @Dept2 is not null or @Dept3 is not null or @Dept4 is not null or @Dept5 is not null 
if  @Dept <>' 'or @Dept2 <>' ' or @Dept3 <>' ' or @Dept4 <>' ' or @Dept5 <>' '
begin
insert into #Dept 
select JCCo, Department
from JCDM
where JCCo=@Company and 
Department in (@Dept, @Dept2, @Dept3, @Dept4, @Dept5)

end


--if @Dept is  null and @Dept2 is  null and @Dept3 is  null and @Dept4 is  null and @Dept5 is  null 
if @Dept =' ' and @Dept2 =' ' and @Dept3 =' ' and @Dept4 =' ' and @Dept5 =' ' 
insert into #Dept 
select JCCo, Department
from JCDM
where JCCo=@Company 




select JCCI.JCCo, Section=1, JCCI.Department, JCDM.Description, JCCM.ContractStatus, JCCI.Contract, JCCI.Item, Bill.ContractAmt, Bill.ProjDollars,
Cost.ProjCost, Cost.CurrEstCost, Bill.BilledAmt, Cost.ActualCost, Cost.RemainCmtdCost,
Cost.SelfPerfEstCost,Cost.SubEstCost, Unpaid=0 , CashPaid=0,
Bill.Retainage, Bill.ReceivedAmt, PendingContractAmt=0, HQCO.HQCo, HQCO.Name

from JCCI
join JCDM with (nolock) on JCCI.JCCo=JCDM.JCCo and JCCI.Department=JCDM.Department
join #Dept with (nolock) on JCCI.JCCo=#Dept.JCCo and JCCI.Department = #Dept.Dept
join JCCM with (nolock) on JCCI.JCCo=JCCM.JCCo and JCCI.Contract=JCCM.Contract 
Join HQCO with (nolock) on JCCI.JCCo=HQCO.HQCo

left join (select JCIP.JCCo, JCIP.Contract, JCIP.Item, ContractAmt=sum(JCIP.ContractAmt), ProjDollars=sum(JCIP.ProjDollars), BilledAmt=sum(JCIP.BilledAmt),
     Retainage=sum(JCIP.CurrentRetainAmt), ReceivedAmt=sum(JCIP.ReceivedAmt) from JCIP 
     join JCCM with (nolock) on JCIP.JCCo=JCCM.JCCo and JCIP.Contract=JCCM.Contract
     where JCIP.JCCo=@Company and JCIP.Contract>=@BegCont and JCIP.Contract<=@EndCont
     group by JCIP.JCCo, JCIP.Contract, JCIP.Item)  as Bill on 
     JCCI.JCCo=Bill.JCCo and JCCI.Contract=Bill.Contract and JCCI.Item=Bill.Item
     

left join (select JCJP.JCCo, JCJP.Contract, JCJP.Item, ProjCost=sum(JCCP.ProjCost),
     CurrEstCost=sum(JCCP.CurrEstCost), ActualCost=sum(JCCP.ActualCost), RemainCmtdCost=sum(JCCP.RemainCmtdCost),
     SelfPerfEstCost = sum(case when JCCP.CostType=@LaborCostType then JCCP.CurrEstCost end),
     SubEstCost = sum(case when JCCP.CostType = @SubCostType then JCCP.CurrEstCost end) from JCCP
     join JCJP with (nolock) on JCCP.JCCo=JCJP.JCCo and JCCP.Job=JCJP.Job and JCCP.PhaseGroup=JCJP.PhaseGroup and 
     JCCP.Phase=JCJP.Phase  
     join JCCM with (nolock) on JCJP.JCCo=JCCM.JCCo and JCJP.Contract=JCCM.Contract
     where JCJP.JCCo=@Company and JCJP.Contract>=@BegCont and JCJP.Contract<=@EndCont
     group by JCJP.JCCo, JCJP.Contract, JCJP.Item) as Cost on
     JCCI.JCCo=Cost.JCCo and JCCI.Contract=Cost.Contract and JCCI.Item=Cost.Item
     
where JCCI.JCCo = @Company and JCCI.Contract>=@BegCont and JCCI.Contract<=@EndCont
and ((case when @ContStatus='C' then JCCM.ContractStatus end= 2
    or
      case when @ContStatus='C' then JCCM.ContractStatus end = 3)
OR
JCCM.ContractStatus=case when @ContStatus = 'O' then 1 
                    when @ContStatus = 'A' then  JCCM.ContractStatus  end)

union all

select JCCI.JCCo, Section=2, JCCI.Department, JCDM.Description, JCCM.ContractStatus, JCCI.Contract, JCCI.Item, Bill.ContractAmt, Bill.ProjDollars,
Cost.ProjCost, Cost.CurrEstCost, Bill.BilledAmt, Cost.ActualCost, Cost.RemainCmtdCost, 
0, 0, AP.Unpaid, CashPaid = (isnull(Cost.ActualCost,0) - isnull(AP.Unpaid,0)), 
Bill.Retainage, Bill.ReceivedAmt, Pend.PendingContractAmt, HQCO.HQCo, HQCO.Name

from JCCI
join JCDM with (nolock) on JCCI.JCCo=JCDM.JCCo and JCCI.Department=JCDM.Department
join #Dept with (nolock) on JCCI.JCCo=#Dept.JCCo and JCCI.Department = #Dept.Dept
join JCCM with (nolock) on JCCI.JCCo=JCCM.JCCo and JCCI.Contract=JCCM.Contract
Join HQCO with (nolock) on JCCI.JCCo=HQCO.HQCo

left join (select JCCI.JCCo, JCCI.Contract, JCCI.Item, PendingContractAmt=sum(case when JCCM.ContractStatus = 0 then JCCI.ContractAmt end)
      from JCCI
      join JCCM with (nolock) on JCCI.JCCo=JCCM.JCCo and JCCI.Contract=JCCM.Contract
      where JCCI.JCCo=@Company
      group by JCCI.JCCo, JCCI.Contract,JCCI.Item ) as Pend on
      JCCI.JCCo=Pend.JCCo and JCCI.Contract=Pend.Contract and JCCI.Item=Pend.Item

left join (select JCIP.JCCo, JCIP.Contract, JCIP.Item, ContractAmt=sum(JCIP.ContractAmt), ProjDollars=sum(JCIP.ProjDollars), BilledAmt=sum(JCIP.BilledAmt),
      Retainage=sum(JCIP.CurrentRetainAmt), ReceivedAmt=sum(JCIP.ReceivedAmt)--,
      from JCIP 
      join JCCM with (nolock) on JCIP.JCCo=JCCM.JCCo and JCIP.Contract=JCCM.Contract
      where JCIP.JCCo=@Company and JCIP.Contract>=@BegCont and JCIP.Contract<=@EndCont
      group by JCIP.JCCo, JCIP.Contract, JCIP.Item) as Bill on 
      JCCI.JCCo=Bill.JCCo and JCCI.Contract=Bill.Contract and JCCI.Item=Bill.Item
      

left join (select JCJP.JCCo, JCJP.Contract, JCJP.Item, ProjCost=sum(JCCP.ProjCost), 
     CurrEstCost=sum(JCCP.CurrEstCost), ActualCost=sum(JCCP.ActualCost), RemainCmtdCost=sum(JCCP.RemainCmtdCost) from JCCP
     join JCJP with (nolock) on JCCP.JCCo=JCJP.JCCo and JCCP.Job=JCJP.Job and JCCP.PhaseGroup=JCJP.PhaseGroup and 
     JCCP.Phase=JCJP.Phase 
     join JCCM with (nolock) on JCCP.JCCo=JCCM.JCCo and JCJP.Contract=JCCM.Contract
     where JCCP.JCCo=@Company and JCJP.Contract>=@BegCont and JCJP.Contract<=@EndCont
     group by JCJP.JCCo, JCJP.Contract, JCJP.Item) as Cost on
     JCCI.JCCo=Cost.JCCo and JCCI.Contract=Cost.Contract and JCCI.Item=Cost.Item
     

left join (select JCJP.JCCo, JCJP.Contract, JCJP.Item, Unpaid=sum(APTD.Amount) from APTD
     join APTL with (nolock) on APTD.APCo=APTL.APCo and APTD.Mth=APTL.Mth and APTD.APTrans=APTL.APTrans and APTD.APLine=APTL.APLine
     join JCJP with (nolock) on APTL.JCCo=JCJP.JCCo and APTL.Job=JCJP.Job and APTL.PhaseGroup=JCJP.PhaseGroup and APTL.Phase=JCJP.Phase 
     join JCCM with (nolock) on JCJP.JCCo=JCCM.JCCo and JCJP.Contract=JCCM.Contract
     where  JCJP.JCCo= @Company and JCJP.Contract>=@BegCont and JCJP.Contract<=@EndCont and APTD.PaidMth is null 
     group by  JCJP.JCCo, JCJP.Contract, JCJP.Item) as AP on
     JCCI.JCCo=AP.JCCo and JCCI.Contract=AP.Contract and JCCI.Item=AP.Item

where JCCI.JCCo = @Company and  JCCI.Contract>=@BegCont and JCCI.Contract<=@EndCont 
and ((case when @ContStatus='C' then JCCM.ContractStatus end= 2
    or
      case when @ContStatus='C' then JCCM.ContractStatus end = 3)
OR
JCCM.ContractStatus=case when @ContStatus = 'O' then 1 
                    when @ContStatus = 'A' then  JCCM.ContractStatus  end)







GO
GRANT EXECUTE ON  [dbo].[vrptJCDashboardMain] TO [public]
GO
