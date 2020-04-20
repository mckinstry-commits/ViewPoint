SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      view [dbo].[brvJCWIPCashFlow] as
select a.JCCo, a.Contract,c.ContractStatus,/*ProgramMgr=IsNull(JM.ProjectMgr,0),*/  a.Item ,a.Mth,
       a.OrigContractAmt, a.OrigContractUnits, a.OrigUnitPrice, a.ContractAmt, 
       a.ContractUnits, a.CurrentUnitPrice, a.BilledUnits, a.BilledAmt, 
       a.ReceivedAmt, a.CurrentRetainAmt, a.BilledTax,
   
      Job=null, PhaseGroup=0, Phase=null, CostType=0, ActualHours=0, ActualUnits=0, ActualCost=0, 
       OrigEstHours=0, OrigEstUnits=0, OrigEstCost=0, CurrEstHours=0, CurrEstUnits=0, CurrEstCost=0, 
       ProjHours=0, ProjUnits=0, ProjCost=0, ForecastHours=0, ForecastUnits=0, ForecastCost=0, 
       TotalCmtdUnits=0, TotalCmtdCost=0, RemainCmtdUnits=0, RemainCmtdCost=0, RecvdNotInvcdUnits=0, RecvdNotInvcdCost=0,
       UseProjectedEstimate=Null,
   
       CTAbbreviation = null, APOpenAmt=0, PaidMth='12/31/2050',
       RecType = 1
   
       from JCIP a
    Inner Join JCCM c on a.JCCo = c.JCCo and a.Contract = c.Contract
   --Left Join (Select JCCo, Contract,Job=Min(Job),ProjectMgr=Min(ProjectMgr)
         --From JCJM Group By JCCo,Contract ) As JM on
   	--a.JCCo = JM.JCCo and a.Contract = JM.Contract  
   
   Union all
   
   /*** Cost Info ***/
    select JCCP.JCCo, JCJP.Contract, c.ContractStatus,/*ProgramMgr=IsNull(JM.ProjectMgr,0),*/JCJP.Item, JCCP.Mth,
        0,0,0,0,     0,0,0,0,      0,0, 0,
       JCCP.Job, JCCP.PhaseGroup, JCCP.Phase, JCCP.CostType, JCCP.ActualHours, JCCP.ActualUnits, JCCP.ActualCost, 
       JCCP.OrigEstHours, JCCP.OrigEstUnits, JCCP.OrigEstCost, JCCP.CurrEstHours, JCCP.CurrEstUnits, JCCP.CurrEstCost, 
       JCCP.ProjHours, JCCP.ProjUnits, JCCP.ProjCost, JCCP.ForecastHours, JCCP.ForecastUnits, JCCP.ForecastCost, 
       JCCP.TotalCmtdUnits, JCCP.TotalCmtdCost, JCCP.RemainCmtdUnits, JCCP.RemainCmtdCost, JCCP.RecvdNotInvcdUnits, JCCP.RecvdNotInvcdCost,
	   /* 2009-01-19, timsc: UseProjectedEstimate does not properly calculate the Projected Estimate;
	      did not remove as this would cause errors in custom reports that use this view. */
       UseProjectedEstimate = case when (select sum(JCCP.ProjCost)  from JCCP join JCJP J on JCCP.JCCo=J.JCCo and JCCP.Job=J.Job and  JCCP.Phase=J.Phase and JCCP.PhaseGroup=J.PhaseGroup where JCCP.JCCo = JCJP.JCCo and J.Contract = JCJP.Contract and J.Item = JCJP.Item) <>0 then 'P' Else 	'E' End,
       null,0,'12/31/2050',
       RecType = 2
   
   from JCCP 
   Inner join JCJP on JCCP.JCCo=JCJP.JCCo and JCCP.Job=JCJP.Job and JCCP.Phase=JCJP.Phase and JCCP.PhaseGroup=JCJP.PhaseGroup 
   Inner Join JCCM c on JCJP.JCCo = c.JCCo and JCJP.Contract = c.Contract
   --Inner Join (Select JCCo, Contract,Job=Min(Job),ProjectMgr=Min(ProjectMgr)  From JCJM Group By JCCo,Contract ) As JM on
   	--JCJP.JCCo = JM.JCCo and JCJP.Contract = JM.Contract 
   
   
   Union all
   /**AP Amount**/
   Select JCJM.JCCo, JCJM.Contract, Max(e.ContractStatus),/*ProjectMgr=IsNull(Max(JM.ProjectMgr),0),*/null,APTD.Mth,
    0,0,0,0,     0,0,0,0,      0,0, 0,
   JCJM.Job, 0, Phase = null, 0, 0,0,0, 
   0, 0,0,0, 0,0, 
   0,0,0,0,0, 0, 
   0,0,0,0,0,0,null,
   null, Sum(APTD.Amount) - Sum(APTD.GSTtaxAmt), PaidMth=IsNull(PaidMth,'12/31/2050'),
   RecType = 3
   from JCJM
   join APTL on APTL.JCCo=JCJM.JCCo and APTL.Job=JCJM.Job
   join APTD on APTD.APCo=APTL.APCo and APTD.Mth=APTL.Mth and APTD.APTrans=APTL.APTrans and APTL.APLine=APTD.APLine
   Inner Join JCCM e on JCJM.JCCo = e.JCCo and JCJM.Contract = e.Contract
   ---Inner Join (Select JCCo, Contract,Job=Min(Job),ProjectMgr=Min(ProjectMgr)  From JCJM Group By JCCo,Contract ) As JM on
   	--e.JCCo = JM.JCCo and e.Contract = JM.Contract 
   Group BY JCJM.JCCo, JCJM.Contract,APTD.Mth,JCJM.Job,APTD.PaidMth

GO
GRANT SELECT ON  [dbo].[brvJCWIPCashFlow] TO [public]
GRANT INSERT ON  [dbo].[brvJCWIPCashFlow] TO [public]
GRANT DELETE ON  [dbo].[brvJCWIPCashFlow] TO [public]
GRANT UPDATE ON  [dbo].[brvJCWIPCashFlow] TO [public]
GO
