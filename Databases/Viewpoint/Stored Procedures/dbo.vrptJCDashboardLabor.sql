SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE       proc [dbo].[vrptJCDashboardLabor]
(@Company bCompany, @Dept bDept, @LaborCostType bJCCType, @ContStatus char, @BegCont bContract, @EndCont bContract) 
as
/*
  Stored Procedure for the Dashboard Labor subreport 
   Created 9/21/06 CR
   Modified 10/1/07 Added the Contract Status and Beg/End Contract Parameters CR Issue 125026         
      
   Reports that use: JCDashboardLabor.rpt

*/

select JCCD.JCCo, JCCD.Job, JobDesc=JCJM.Description, JCCI.Department, JCCM.ContractStatus, JCCD.PhaseGroup, JCCD.Phase, PhaseDesc=JCJP.Description, 
ActualHours=sum(JCCD.ActualHours), ActualUnits=sum(JCCD.ActualUnits), ActualCost=sum(JCCD.ActualCost),
EstHours=sum(JCCD.EstHours), EstUnits=sum(JCCD.EstUnits), EstCost=sum(JCCD.EstCost),
ProjHours=sum(JCCD.ProjHours), ProjUnits=sum(JCCD.ProjUnits), ProjCost=sum(JCCD.ProjCost)
--CurrEstPhaseUnits=sum(case when(JCCH.UM=JCCD.UM and JCCH.PhaseUnitFlag='Y') then JCCD.EstUnits else 0 end)

from JCCD 
join JCJP on JCCD.JCCo=JCJP.JCCo and JCCD.Job=JCJP.Job and JCCD.PhaseGroup=JCJP.PhaseGroup and JCCD.Phase=JCJP.Phase
join JCJM on JCCD.JCCo=JCJM.JCCo and JCCD.Job=JCJM.Job
join JCCI on JCJP.JCCo=JCCI.JCCo and JCJP.Contract=JCCI.Contract and JCJP.Item=JCCI.Item
join JCCM on JCJM.JCCo=JCCM.JCCo and JCJM.Contract=JCCM.Contract
--join JCCH on JCCD.JCCo=JCCH.JCCo and JCCD.Job=JCCH.Job and JCCD.PhaseGroup=JCCH.PhaseGroup and JCCD.Phase=JCCH.Phase
--and JCCD.CostType=JCCH.CostType



where JCCD.JCCo=@Company and JCCD.CostType=@LaborCostType and JCCI.Department=@Dept and  
       JCJP.Contract>=@BegCont and JCJP.Contract<=@EndCont
and ((case when @ContStatus='C' then JCCM.ContractStatus end= 2
    or
      case when @ContStatus='C' then JCCM.ContractStatus end = 3)
OR
JCCM.ContractStatus=case when @ContStatus = 'O' then 1 
                    when @ContStatus = 'A' then  JCCM.ContractStatus  end)
Group by JCCD.JCCo, JCCI.Contract, JCCI.Department, JCCM.ContractStatus, JCCD.Job, JCJM.Description,JCCD.PhaseGroup, JCCD.Phase,JCJP.Description







GO
GRANT EXECUTE ON  [dbo].[vrptJCDashboardLabor] TO [public]
GO
