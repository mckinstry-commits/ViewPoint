SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE         proc [dbo].[vrptJCDashboardNCF]
(@Company bCompany=1, @ContStatus char, @BegCont bContract, @EndCont bContract)
as
/*
  Stored Procedure for the Dashboard NetCashFlow subreport 
   Created 9/21/06 CR
   Modified 10/1/07 Added the Contract Status and Beg/End Contract Parameters CR Issue 125026         
      
   Reports that use: NetCashFlow.rpt

*/
select JCCI.JCCo, Section=1, JCCI.Department, JCCM.ContractStatus, JCDM.Description, JCCI.Contract, JCCI.Item, 
Bill.BilledAmt, Cost.ActualCost, ARplusRet=(Bill.BilledAmt-Bill.ReceivedAmt),
Bill.Retainage, Bill.ReceivedAmt,
AP.Unpaid, CashPaid = (isnull(Cost.ActualCost,0)-isnull(AP.Unpaid,0))



from JCCI
join JCDM with (nolock) on JCCI.JCCo=JCDM.JCCo and JCCI.Department=JCDM.Department
Join JCCM with (Nolock) on JCCI.JCCo=JCCM.JCCo and JCCI.Contract=JCCM.Contract
 

left join (select JCIP.JCCo, JCIP.Contract, JCIP.Item, BilledAmt=sum(JCIP.BilledAmt), 
     Retainage=sum(JCIP.CurrentRetainAmt),ReceivedAmt=sum(JCIP.ReceivedAmt) from JCIP
     join JCCM with (nolock) on JCIP.JCCo=JCCM.JCCo and JCIP.Contract=JCCM.Contract 
     where JCIP.JCCo=@Company and  JCIP.Contract>=@BegCont and JCIP.Contract<=@EndCont 
     group by JCIP.JCCo, JCIP.Contract, JCIP.Item)  as Bill on 
     JCCI.JCCo=Bill.JCCo and JCCI.Contract=Bill.Contract and JCCI.Item=Bill.Item
     

left join (select JCJP.JCCo, JCJP.Contract, JCJP.Item, 
     ActualCost=sum(ActualCost) from JCCP
     join JCJP with (nolock) on JCCP.JCCo=JCJP.JCCo and JCCP.Job=JCJP.Job and JCCP.PhaseGroup=JCJP.PhaseGroup and 
     JCCP.Phase=JCJP.Phase
     join JCCM with (nolock) on JCJP.JCCo=JCCM.JCCo and JCJP.Contract=JCCM.Contract  
     where JCJP.JCCo=@Company and  JCJP.Contract>=@BegCont and JCJP.Contract<=@EndCont 
     group by JCJP.JCCo, JCJP.Contract, JCJP.Item) as Cost on
     JCCI.JCCo=Cost.JCCo and JCCI.Contract=Cost.Contract and JCCI.Item=Cost.Item
     
left join (select JCJP.JCCo, JCJP.Contract, JCJP.Item, Unpaid=sum(APTD.Amount) from APTD
     join APTL with (nolock) on APTD.APCo=APTL.APCo and APTD.Mth=APTL.Mth and APTD.APTrans=APTL.APTrans and APTD.APLine=APTL.APLine
     join JCJP with (nolock) on APTL.JCCo=JCJP.JCCo and APTL.Job=JCJP.Job and APTL.PhaseGroup=JCJP.PhaseGroup and APTL.Phase=JCJP.Phase 
     join JCCM with (nolock) on JCJP.JCCo=JCCM.JCCo and JCJP.Contract=JCCM.Contract
     where  JCJP.JCCo= @Company  and JCJP.Contract>=@BegCont and JCJP.Contract<=@EndCont and APTD.PaidMth is null 

     group by  JCJP.JCCo, JCJP.Contract, JCJP.Item) as AP on
     JCCI.JCCo=AP.JCCo and JCCI.Contract=AP.Contract and JCCI.Item=AP.Item

where JCCI.JCCo=@Company and JCCI.Contract >= @BegCont and JCCI.Contract<=@EndCont
and ((case when @ContStatus='C' then JCCM.ContractStatus end= 2
    or
      case when @ContStatus='C' then JCCM.ContractStatus end = 3)
OR
JCCM.ContractStatus=case when @ContStatus = 'O' then 1 
                    when @ContStatus = 'A' then  JCCM.ContractStatus  end)






GO
GRANT EXECUTE ON  [dbo].[vrptJCDashboardNCF] TO [public]
GO
