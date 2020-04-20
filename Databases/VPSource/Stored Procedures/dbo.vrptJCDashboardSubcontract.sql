SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      proc [dbo].[vrptJCDashboardSubcontract] 
(@Company bCompany, @Dept bDept=null, @SubCostType bJCCType, @ContStatus char, @BegCont bContract, @EndCont bContract) 
as
/*
  Stored Procedure for the Dashboard Subcontract subreport 
   Created 9/21/06 CR
   Modified 10/1/07 Added the Contract Status and Beg/End Contract Parameters CR Issue 125026         
      
   Reports that use: JCDashboardSub2.rpt

*/
select JCCH.JCCo, JCCH.Job, JCCH.PhaseGroup, JCCH.Phase,  JCCH.BuyOutYN, JCCM.Department, JCCM.ContractStatus, JobDesc=JCJM.Description, PhaseDesc=JCJP.Description,
          Estimated=sum(JCCH.OrigCost), ApprovedCOAmt=sum(ACO.ACOAmt), CommittedAmt=sum(PM.CommittedAmt), UnassignedAmt=sum(PM.UnassignedAmt),
          UncommittedAmt = case when JCCH.BuyOutYN = 'N' then 
                (case when (sum(isnull(JCCH.OrigCost,0))+sum(isnull(ACO.ACOAmt,0)))-sum(isnull(PM.CommittedAmt,0)) < 0 then 0 
                else (sum(isnull(JCCH.OrigCost,0))+sum(isnull(ACO.ACOAmt,0)))-sum(isnull(PM.CommittedAmt,0)) end)
          else 0 end

   from JCCH
 join JCJM with (nolock) on JCCH.JCCo=JCJM.JCCo and JCCH.Job=JCJM.Job
 join JCCM with (nolock) on JCJM.JCCo=JCCM.JCCo and JCJM.Contract=JCCM.Contract
 Join JCJP with (nolock) on JCCH.JCCo=JCJP.JCCo and JCCH.Job=JCJP.Job and JCCH.PhaseGroup=JCJP.PhaseGroup and JCCH.Phase=JCJP.Phase

 left join (select PMOL.PMCo, PMOL.Project, PMOL.PhaseGroup, PMOL.Phase, PMOL.CostType, ACOAmt=sum(PMOL.EstCost)
   from PMOL
   where PMOL.ACO is not NULL
   group by PMOL.PMCo, PMOL.Project, PMOL.PhaseGroup, PMOL.Phase, PMOL.CostType) as ACO on
   JCCH.JCCo=ACO.PMCo and JCCH.Job=ACO.Project and JCCH.Phase=ACO.Phase and JCCH.PhaseGroup=ACO.PhaseGroup and JCCH.CostType=ACO.CostType

   
 left join(select PMSL.PMCo, PMSL.Project, PMSL.PhaseGroup, PMSL.Phase, PMSL.CostType, 
          CommittedAmt=sum(case when PMSL.PCO is not NULL and PMSL.ACO is NULL and PMSL.SubCO is NULL then 0
                              when PMSL.SL is not Null then  PMSL.Amount
                              else 0 end),

          UnassignedAmt=sum (case when PMSL.PCO is not NULL and PMSL.ACO is NULL and PMSL.SubCO is NULL then 0
                           when PMSL.SL is Null then  PMSL.Amount
                           else 0 end) 
   from PMSL
   join JCCH with (nolock) on PMSL.PMCo=JCCH.JCCo and PMSL.Project=JCCH.Job and PMSL.Phase=JCCH.Phase and 
        PMSL.PhaseGroup=JCCH.PhaseGroup and PMSL.CostType=JCCH.CostType
   group by PMSL.PMCo, PMSL.Project, PMSL.PhaseGroup, PMSL.Phase, PMSL.CostType) as PM on
   JCCH.JCCo=PM.PMCo and JCCH.Job=PM.Project and JCCH.PhaseGroup=PM.PhaseGroup and JCCH.Phase=PM.Phase and JCCH.CostType=PM.CostType

where JCCH.JCCo=@Company and JCCM.Department=@Dept and JCCH.CostType=@SubCostType  and  
     JCCM.Contract>=@BegCont and JCCM.Contract<=@EndCont
and ((case when @ContStatus='C' then JCCM.ContractStatus end= 2
    or
      case when @ContStatus='C' then JCCM.ContractStatus end = 3)
OR
JCCM.ContractStatus=case when @ContStatus = 'O' then 1 
                    when @ContStatus = 'A' then  JCCM.ContractStatus  end)
 
Group by JCCH.JCCo, JCCM.Department, JCCM.ContractStatus, JCCH.Job, JCJM.Description, JCCH.PhaseGroup, JCCH.Phase, JCJP.Description, JCCH.BuyOutYN

GO
GRANT EXECUTE ON  [dbo].[vrptJCDashboardSubcontract] TO [public]
GO
