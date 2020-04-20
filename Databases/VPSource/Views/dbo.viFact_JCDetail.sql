SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE View [dbo].[viFact_JCDetail]

/**************************************************
 * Alterd: DH 6/18/08
 * Modified:      
 * Usage:  Fact View returning Job Cost Data from JCCD (Cost Detail)
 *         for use as Measures in SSAS Cubes.  Also returns non-interfaced
 *         PM Committed and Pending CO Costs.  View uses 5 CTE's:
 *         JCDetail CTE:  Selects bJCCD data.
 *         PM Pending Costs CTE:  Selects bJCCH, bPMMF, bPMSL cost where Interface Date is null.
 *         PM Pending CO CTE:  Selects bPMOL cost where Interface Date is null. 
 *         JobCost CTE:  Combines JCDetail, PendingCosts, and PM Pending CO CTEs
 *         JCProjMth CTE:  Gets First Projected Mth by JCCo, Contract, Item.  Used to calculate EstCostComplete
 *         Final Select Statement returns columns with KeyID fields that are used to join to dimensions
 *         in the Cubes.
 ********************************************************/

as

/*Begin JCProjMth CTE:  Find first Projected Month by JCCo, Contract, Item
  Used to derive Estimated Cost at Completion*/

With JCProjMth

(JCCo,
 Contract,
 Item,
 FirstProjMth)

as

(Select bJCJP.JCCo,
	   bJCJP.Contract,
	   bJCJP.Item,
       min(bJCCP.Mth) as ProjMth
From bJCCP With (NoLock)
Join bJCJP With (NoLock) on bJCJP.JCCo=bJCCP.JCCo and bJCJP.Job=bJCCP.Job and bJCJP.PhaseGroup=bJCCP.PhaseGroup
          and bJCJP.Phase=bJCCP.Phase
Where bJCCP.ProjCost <> 0 or bJCCP.ProjPlug='Y'
Group By bJCJP.JCCo, bJCJP.Contract, bJCJP.Item
        
),

/*End JCProjMth CTE*/

/*Begin JCDetail CTE*/

 JCDetail 
	(JCCo,
	 Job,
	 PhaseGroup,
	 Phase,
	 CostType,
	 GLCo,
	 Mth,
	 CostTrans,
	 UM,
	 ActualDate,
	 PostedDate,
	 PRCo,
	 Crew,
	 ActualHours,
	 ActualUnits,
     ActualCost,
	 OrigEstHours,
	 OrigEstUnits,
	 OrigEstCost,
	 CurrEstHours,
	 CurrEstUnits,
	 CurrEstCost,
	 ProjHours,
	 ProjUnits,
	 ProjCost,
	 ForecastHours,
	 ForecastUnits,
	 ForecastCost,
	 TotalCmtdUnits,
	 TotalCmtdCost,
	 RemainCmtdUnits,
	 RemainCmtdCost,
     EstCostComplete,
     ActualCommittedCost,
     ActualCommittedUnits,
	 ProjMethod,
	 ProjMinPct)

as 

/*If amount columns = 0, set to Null - for better performance in SSAS*/

  (Select
	 bJCCD.JCCo,
	 bJCCD.Job,
	 bJCCD.PhaseGroup,
	 bJCCD.Phase,
	 bJCCD.CostType,
	 isnull(bJCCD.GLCo,bJCCO.GLCo) as GLCo,
	 bJCCD.Mth,
	 bJCCD.CostTrans,
	 bJCCD.UM,
	 bJCCD.ActualDate,
	 bJCCD.PostedDate,
	 bJCCD.PRCo,
	 bJCCD.Crew,
	 case when bJCCD.ActualHours<>0 then bJCCD.ActualHours else Null end,
	 case when bJCCD.ActualUnits<>0 then bJCCD.ActualUnits else Null end,
     case when bJCCD.ActualCost<>0 then bJCCD.ActualCost else Null end,
	 case when bJCCD.JCTransType='OE' then bJCCD.EstHours else Null end as OrigEstHours,
     case when bJCCD.JCTransType='OE' then bJCCD.EstUnits else Null end as OrigEstUnits,
     case when bJCCD.JCTransType='OE' then bJCCD.EstCost else Null end as OrigEstCost,
	 case when bJCCD.EstHours<>0 then bJCCD.EstHours else Null end,
	 case when bJCCD.EstUnits<>0 then bJCCD.EstUnits else Null end,
	 case when bJCCD.EstCost<>0 then bJCCD.EstCost else Null end,
	 case when bJCCD.ProjHours<>0 then bJCCD.ProjHours else Null end,
	 case when bJCCD.ProjUnits<>0 then bJCCD.ProjUnits else Null end,
	 case when bJCCD.ProjCost<>0 then bJCCD.ProjCost else Null end,
	 case when bJCCD.ForecastHours<>0 then bJCCD.ForecastHours else Null end,
	 case when bJCCD.ForecastUnits<>0 then bJCCD.ForecastUnits else Null end,
	 case when bJCCD.ForecastCost<>0 then bJCCD.ForecastCost else Null end,
	 case when bJCCD.TotalCmtdUnits<>0 then bJCCD.TotalCmtdUnits else Null end,
	 case when bJCCD.TotalCmtdCost<>0 then bJCCD.TotalCmtdCost else Null end,
	 case when bJCCD.RemainCmtdUnits<>0 then bJCCD.RemainCmtdUnits else Null end,
	 case when bJCCD.RemainCmtdCost<>0 then bJCCD.RemainCmtdCost else Null end,
     case when JCProjMth.FirstProjMth<=bJCCD.Mth 
             then isnull(bJCCD.ProjCost,0) 
        else isnull(bJCCD.EstCost,0) end as EstCostComplete,
     case when bJCCD.ActualCost<>0 or bJCCD.RemainCmtdCost<>0 then
               isnull(bJCCD.ActualCost,0)+isnull(bJCCD.RemainCmtdCost,0) end as ActualCommittedCost,
     case when bJCCD.ActualUnits<>0 or bJCCD.RemainCmtdUnits<>0 then
		       isnull(bJCCD.ActualUnits,0)+isnull(bJCCD.RemainCmtdUnits,0) end as ActualCommittedUnits,
	 bJCCO.ProjMethod,
	 case when bJCJP.ProjMinPct<>0 then bJCJP.ProjMinPct
		  when bJCJM.ProjMinPct<>0 then bJCJM.ProjMinPct
		  else bJCCO.ProjMinPct
     end as ProjMinPct
   From bJCCD With (NoLock)
   Join bJCCO With (NoLock) on bJCCO.JCCo=bJCCD.JCCo
   Left Join bJCJP With (NoLock) on bJCJP.JCCo=bJCCD.JCCo and bJCJP.Job=bJCCD.Job and bJCJP.PhaseGroup=bJCCD.PhaseGroup
                         and bJCJP.Phase=bJCCD.Phase
   Join bJCJM With (NoLock) on bJCJM.JCCo=bJCCD.JCCo and bJCJM.Job=bJCCD.Job
   Left Join JCProjMth With (NoLock) on JCProjMth.JCCo=bJCJP.JCCo
                    and JCProjMth.Contract=bJCJP.Contract
				    and JCProjMth.Item=bJCJP.Item



--union all

/*Select Estimated Cost at Completion (follows standard WIP report calculations)
  If first month a projection exists before or on bJCCP.Mth (FirstProjMth <= bJCCP.Mth)
  then use Projected Cost, else use Current Estimated Cost.  Set to either Projected or 
  Current Estimated for all bJCCP records by contract item (bJCJP.Item)*/

/*Select bJCCP.JCCo,
	   bJCCP.Job,
	   bJCCP.PhaseGroup,
	   bJCCP.Phase,
	   bJCCP.CostType,
	   bJCCO.GLCo,
	   bJCCP.Mth, 	
       Null as CostTrans,
	   Null as UM,
	   bJCCP.Mth as ActualDate,
	   bJCCP.Mth as PostedDate,
	   Null as ActualHours,
	   Null as ActualUnits,
       Null as ActualCost,
	   Null as OrigEstHours,
       Null as OrigEstUnits,
       Null as OrigEstCost,
	   Null as EstHours,
	   Null as EstUnits,
	   Null as EstCost,
	   Null as ProjHours,
	   Null as ProjUnits,
	   Null as ProjCost,
	   Null as ForecastHours,
	   Null as ForecastUnits,
	   Null as ForecastCost,
	   Null as TotalCmtdUnits,
	   Null as TotalCmtdCost,
	   Null as RemainCmtdUnits,
	   Null as RemainCmtdCost,
       (case when JCProjMth.FirstProjMth<=bJCCP.Mth 
             then isnull(bJCCP.ProjCost,0) 
        else isnull(bJCCP.CurrEstCost,0) end)

From bJCCP With (NoLock)
Join bJCCO With (NoLock) on bJCCO.JCCo=bJCCP.JCCo
Join bJCJP With (NoLock) on bJCJP.JCCo=bJCCP.JCCo and bJCJP.Job=bJCCP.Job and bJCJP.PhaseGroup=bJCCP.PhaseGroup
                         and bJCJP.Phase=bJCCP.Phase
Left Join JCProjMth With (NoLock) on JCProjMth.JCCo=bJCCP.JCCo
                    and JCProjMth.Contract=bJCJP.Contract
				    and JCProjMth.Item=bJCJP.Item*/

--union all

/*Reverse Current Estimated Costs in the first projection month
  This prevents Projected and Current Estimated costs from being added 
  when reports select a series of months*/

/*Select bJCCP.JCCo,
	   bJCCP.Job,
	   bJCCP.PhaseGroup,
	   bJCCP.Phase,
	   bJCCP.CostType,
	   max(bJCCO.GLCo) as GLCo,
	   max(JCProjMth.FirstProjMth), 	
       Null as CostTrans,
	   Null as UM,
	   max(JCProjMth.FirstProjMth) as ActualDate,
	   max(JCProjMth.FirstProjMth) as PostedDate,
	   Null as ActualHours,
	   Null as ActualUnits,
       Null as ActualCost,
	   Null as OrigEstHours,
       Null as OrigEstUnits,
       Null as OrigEstCost,
	   Null as EstHours,
	   Null as EstUnits,
	   Null as EstCost,
	   Null as ProjHours,
	   Null as ProjUnits,
	   Null as ProjCost,
	   Null as ForecastHours,
	   Null as ForecastUnits,
	   Null as ForecastCost,
	   Null as TotalCmtdUnits,
	   Null as TotalCmtdCost,
	   Null as RemainCmtdUnits,
	   Null as RemainCmtdCost,
       sum(CurrEstCost)*-1 as EstCostComplete

From bJCCP With (NoLock)
Join bJCCO With (NoLock) on bJCCO.JCCo=bJCCP.JCCo
Join bJCJP With (NoLock) on bJCJP.JCCo=bJCCP.JCCo and bJCJP.Job=bJCCP.Job and bJCJP.PhaseGroup=bJCCP.PhaseGroup
          and bJCJP.Phase=bJCCP.Phase
Join JCProjMth With (NoLock) on JCProjMth.JCCo=bJCJP.JCCo
                    and JCProjMth.Contract=bJCJP.Contract
				    and JCProjMth.Item=bJCJP.Item
				    and bJCCP.Mth<JCProjMth.FirstProjMth
    
Group By bJCCP.JCCo, bJCCP.Job, bJCCP.PhaseGroup, bJCCP.Phase, bJCCP.CostType*/


  ),  /*End JCDetail CTE*/

EstCost 
	(JCCo,
	 Job,
	 PhaseGroup,
	 Phase,
	 CostType,
	 GLCo,
	 Mth,
	 ActualDate,
	 PostedDate,
	 EstCostComplete)

as

(Select bJCCP.JCCo,
	   bJCCP.Job,
	   bJCCP.PhaseGroup,
	   bJCCP.Phase,
	   bJCCP.CostType,
	   max(bJCCO.GLCo) as GLCo,
	   max(JCProjMth.FirstProjMth), 	
       max(JCProjMth.FirstProjMth) as ActualDate,
	   max(JCProjMth.FirstProjMth) as PostedDate,	   
       sum(CurrEstCost)*-1 as EstCostComplete

From bJCCP With (NoLock)
Join bJCCO With (NoLock) on bJCCO.JCCo=bJCCP.JCCo
Join bJCJP With (NoLock) on bJCJP.JCCo=bJCCP.JCCo and bJCJP.Job=bJCCP.Job and bJCJP.PhaseGroup=bJCCP.PhaseGroup
          and bJCJP.Phase=bJCCP.Phase
Join JCProjMth With (NoLock) on JCProjMth.JCCo=bJCJP.JCCo
                    and JCProjMth.Contract=bJCJP.Contract
				    and JCProjMth.Item=bJCJP.Item
				    and bJCCP.Mth<JCProjMth.FirstProjMth
    
Group By bJCCP.JCCo, bJCCP.Job, bJCCP.PhaseGroup, bJCCP.Phase, bJCCP.CostType),

/*Begin PendingCosts CTE*/
/*Exclude bPMMF and bPMSL Amounts on Pending CO's (PCO is not null, ACO is null)*/
PendingCosts
  (PMCo,
   Project,	
   PhaseGroup,
   Phase,
   CostType,
   StartMonth,
   PendingEstCost,
   PMCmtdCost)

 as
	 	 
 ( Select bJCCH.JCCo,
			bJCCH.Job,
			bJCCH.PhaseGroup,
			bJCCH.Phase,
			bJCCH.CostType, 
		    bJCCM.StartMonth, 
            bJCCH.OrigCost, 
			Null as PMCmtdCost
      from bJCCH With (NoLock)
      join bJCJM With (NoLock) 
				on bJCJM.JCCo=bJCCH.JCCo and bJCJM.Job=bJCCH.Job
	  join bJCCM With (NoLock) on bJCCM.JCCo=bJCJM.JCCo and bJCCM.Contract=bJCJM.Contract
	  where bJCCM.ContractStatus=0

	union all
     
     Select bPMMF.PMCo,
		  bPMMF.Project,
		  bPMMF.PhaseGroup,
		  bPMMF.Phase,
		  bPMMF.CostType,
		Null as StartMonth,
		Null as PendingEstCost,
	   sum(case when bPMMF.PCO is not NULL and bPMMF.ACO is NULL then 0 else bPMMF.Amount end) as PMCommittedAmount
   from bPMMF With (NoLock)
   Join bJCCH With (NoLock) on 
		bJCCH.JCCo=bPMMF.PMCo and
		bJCCH.Job=bPMMF.Project and
		bJCCH.PhaseGroup=bPMMF.PhaseGroup and
		bJCCH.Phase=bPMMF.Phase and
		bJCCH.CostType=bPMMF.CostType
   where MaterialOption = 'P' and  PO is not NULL 
		 and bJCCH.BuyOutYN='N'/*and bPMMF.InterfaceDate is null*/
   group by bPMMF.PMCo, bPMMF.Project, bPMMF.PhaseGroup, bPMMF.Phase, bPMMF.CostType
   
   union all
   
   Select bPMMF.PMCo,
		  bPMMF.Project,
		  bPMMF.PhaseGroup,
		  bPMMF.Phase,
		  bPMMF.CostType, 
		  Null as StartMonth,
          Null as PendingEstCost,
          sum(bPMMF.Amount) 
   from bPMMF With (NoLock)
   Join bJCCH With (NoLock) on 
		bJCCH.JCCo=bPMMF.PMCo and
		bJCCH.Job=bPMMF.Project and
		bJCCH.PhaseGroup=bPMMF.PhaseGroup and
		bJCCH.Phase=bPMMF.Phase and
		bJCCH.CostType=bPMMF.CostType
   where  MaterialOption = 'M' and MO is not NULL 
		  and bJCCH.BuyOutYN='N'/*and bPMMF.InterfaceDate is null*/
   group by bPMMF.PMCo, bPMMF.Project, bPMMF.PhaseGroup, bPMMF.Phase, bPMMF.CostType
   
   union all
   
   select bPMSL.PMCo,
		  bPMSL.Project,
		  bPMSL.PhaseGroup,
		  bPMSL.Phase,
		  bPMSL.CostType,  
		  Null as StartMonth,
          Null as PendingEstCost,
          sum(case when bPMSL.PCO is not NULL and bPMSL.ACO is NULL and bPMSL.SubCO is NULL then 0 else bPMSL.Amount end)
   from bPMSL With (NoLock)
   Join bJCCH With (NoLock) on 
		bJCCH.JCCo=bPMSL.PMCo and
		bJCCH.Job=bPMSL.Project and
		bJCCH.PhaseGroup=bPMSL.PhaseGroup and
		bJCCH.Phase=bPMSL.Phase and
		bJCCH.CostType=bPMSL.CostType
   where bPMSL.SL is not NULL 
		 and bJCCH.BuyOutYN='N'/*and bPMSL.InterfaceDate is null*/
   Group By bPMSL.PMCo, bPMSL.Project, bPMSL.PhaseGroup, bPMSL.Phase, bPMSL.CostType), /*End PendingCosts CTE*/

/*Begin Pending CO CTE*/
PendingCO

(PMCo,
 Project,
 PhaseGroup,
 Phase,
 CostType,
 ACOCost_NonInterface,
 PendingChgOrderCost)

as

(Select bPMOL.PMCo,
		bPMOL.Project,
		bPMOL.PhaseGroup,
		bPMOL.Phase,
		bPMOL.CostType,
        case when bPMOL.ACO is not null then bPMOL.EstCost end,
		bPMOL.EstCost
  From bPMOL  
  Join bPMOI on bPMOI.PMCo=bPMOL.PMCo and bPMOI.Project=bPMOL.Project and bPMOI.PCOType=bPMOL.PCOType
		   and bPMOI.PCO=bPMOL.PCO and bPMOI.PCOItem=bPMOL.PCOItem 
           and isnull(bPMOI.ACO,'')=isnull(bPMOL.ACO,'') and isnull(bPMOI.ACOItem,'')=isnull(bPMOL.ACOItem,'')
 Join bPMSC on bPMSC.Status=bPMOI.Status
 Where bPMOL.InterfacedDate is null and bPMSC.IncludeInProj='Y' 

 union all

 Select bPMOA.PMCo,
		bPMOA.Project,
		bPMPA.PhaseGroup,
		bPMPA.Phase,
		bPMPA.CostType,
		Null as ACOCost_NonInterface,
		sum(bPMOA.AddOnAmount) as AddonAmount
From bPMOA
Join bPMPA on bPMPA.PMCo=bPMOA.PMCo and bPMPA.Project=bPMOA.Project and bPMPA.AddOn=bPMOA.AddOn and bPMPA.Phase is not null
Join bPMOI on bPMOI.PMCo=bPMOA.PMCo and bPMOI.Project=bPMOA.Project and bPMOI.PCOType=bPMOA.PCOType
		   and bPMOI.PCO=bPMOA.PCO and bPMOI.PCOItem=bPMOA.PCOItem and bPMOI.ACO is null and bPMOI.ACOItem is null
 Join bPMSC on bPMSC.Status=bPMOI.Status
Where bPMOI.InterfacedDate is null and bPMSC.IncludeInProj='Y'
Group By bPMOA.PMCo,
		 bPMOA.Project,
		 bPMPA.PhaseGroup,
		 bPMPA.Phase,
		 bPMPA.CostType), /*End PendingCO CTE*/

/*Begin JobCost CTE:  Combines JCDetail, PendingCosts, and PendingCO CTEs*/
JobCost

(JCCo,
 Job,
 PhaseGroup,
 Phase,
 CostType,
 GLCo,
 Mth,
 CostTrans,
 UM,
 ActualDate,
 PostedDate,
 PRCo,
 Crew,
 ActualHours,
 ActualUnits,
 ActualCost,
 OrigEstHours,
 OrigEstUnits,
 OrigEstCost,
 CurrEstHours,
 CurrEstUnits,
 CurrEstCost,
 ProjHours,
 ProjUnits,
 ProjCost,
 ForecastHours,
 ForecastUnits,
 ForecastCost,
 TotalCmtdUnits,
 TotalCmtdCost,
 RemainCmtdUnits,
 RemainCmtdCost,
 PendingEstCost,
 PMCmtdCost,
 ACOCost_NonInterface,
 PendingChgOrderCost,
 EstCostComplete,
 ProjMethod,
 ProjMinPct,	
 ActualCommittedCost,
 ActualCommittedUnits,
 ActualforForecastCost,
 ActualforForecastUnits)

as

(Select 
     JCDetail.JCCo,
	 JCDetail.Job,
	 JCDetail.PhaseGroup,
	 JCDetail.Phase,
	 JCDetail.CostType,
	 JCDetail.GLCo,
	 JCDetail.Mth,
	 JCDetail.CostTrans,
	 JCDetail.UM,
	 JCDetail.ActualDate,
	 JCDetail.PostedDate,
	 JCDetail.PRCo,
	 JCDetail.Crew,
	 JCDetail.ActualHours,
	 JCDetail.ActualUnits,
     JCDetail.ActualCost,
	 JCDetail.OrigEstHours,
	 JCDetail.OrigEstUnits,
	 JCDetail.OrigEstCost,
	 JCDetail.CurrEstHours,
	 JCDetail.CurrEstUnits,
	 JCDetail.CurrEstCost,
	 JCDetail.ProjHours,
	 JCDetail.ProjUnits,
	 JCDetail.ProjCost,
	 JCDetail.ForecastHours,
	 JCDetail.ForecastUnits,
	 JCDetail.ForecastCost,
	 JCDetail.TotalCmtdUnits,
	 JCDetail.TotalCmtdCost,
	 JCDetail.RemainCmtdUnits,
	 JCDetail.RemainCmtdCost,
	 Null as PendingEstCost,
	 Null as PMCmtdCost,
	 Null as ACOCost_NonInterface,
	 Null as PendingChgOrderCost,
     EstCostComplete,
     JCDetail.ProjMethod,
	 JCDetail.ProjMinPct,
     ActualCommittedCost,
     ActualCommittedUnits,
     case when JCDetail.ProjMethod=2 then JCDetail.ActualCommittedCost else JCDetail.ActualCost end as ActualforForecastCost,
	 case when JCDetail.ProjMethod=2 then JCDetail.ActualCommittedUnits else JCDetail.ActualUnits end as ActualforForecastUnits
     
From JCDetail
--Join bJCCO on bJCCO.JCCo=JCDetail.JCCo

union all

Select 
     EstCost.JCCo,
	 EstCost.Job,
	 EstCost.PhaseGroup,
	 EstCost.Phase,
	 EstCost.CostType,
	 EstCost.GLCo,
	 EstCost.Mth,
	 Null as CostTrans,
	 Null as UM,
	 EstCost.ActualDate,
	 EstCost.PostedDate,
	 Null as PRCo,
	 Null as Crew,
	 Null as ActualHours,
	 Null as ActualUnits,
     Null as ActualCost,
	 Null as OrigEstHours,
	 Null as OrigEstUnits,
	 Null as OrigEstCost,
	 Null as CurrEstHours,
	 Null as CurrEstUnits,
	 Null as CurrEstCost,
	 Null as ProjHours,
	 Null as ProjUnits,
	 Null as ProjCost,
	 Null as ForecastHours,
	 Null as ForecastUnits,
	 Null as ForecastCost,
	 Null as TotalCmtdUnits,
	 Null as TotalCmtdCost,
	 Null as RemainCmtdUnits,
	 Null as RemainCmtdCost,
	 Null as PendingEstCost,
	 Null as PMCmtdCost,
     Null as ACOCost_NonInterface,
	 Null as PendingChgOrderCost,
     EstCostComplete,
     Null as ProjMethod,
     Null as ProjMinPct,
	 Null as ActualCommittedCost,
     Null as ActualCommittedUnits,
     Null as ActualforForecastCost,
     Null as ActualforForecastUnits
From EstCost

union all

Select
     PendingCosts.PMCo,
	 PendingCosts.Project,
	 PendingCosts.PhaseGroup,
	 PendingCosts.Phase,
	 PendingCosts.CostType,
	 bJCCO.GLCo as GLCo,  
	 Case when PendingCosts.StartMonth is not null then PendingCosts.StartMonth
		  else DATEADD(d,DATEDIFF(d,0,GETDATE()),0) - (Day(DATEADD(d,DATEDIFF(d,0,GETDATE()),0))-1)
	 End as Mth, /*Returns StartMonth if exists else Current Month (based on Current Date) for PM data*/
	 Null as CostTrans,
	 Null as UM,
	 DATEADD(d,DATEDIFF(d,0,GETDATE()),0) as ActualDate, --removes time from getdate
	 DATEADD(d,DATEDIFF(d,0,GETDATE()),0) as PostedDate, --removes time from getdate
	 Null as PRCo,
	 Null as Crew,
	 Null as ActualHours,
	 Null as ActualUnits,
     Null as ActualCost,
	 Null as OrigEstHours,
	 Null as OrigEstUnits,
	 Null as OrigEstCost,
	 Null as CurrEstHours,
	 Null as CurrEstUnits,
	 Null as CurrEstCost,
	 Null as ProjHours,
	 Null as ProjUnits,
	 Null as ProjCost,
	 Null as ForecastHours,
	 Null as ForecastUnits,
	 Null as ForecastCost,
	 Null as TotalCmtdUnits,
	 Null as TotalCmtdCost,
	 Null as RemainCmtdUnits,
	 Null as RemainCmtdCost,
	 PendingCosts.PendingEstCost,
	 PendingCosts.PMCmtdCost,
     Null as ACOCost_NonInterface,
	 Null as PendingChgOrderCost,
     Null as EstCostComplete,
	 Null as ProjMethod,
	 Null as ProjMinPct,
     Null as ActualCommittedCost,
     Null as ActualCommittedUnits,
     Null as ActualforForecastCost,
     Null as ActualforForecastUnits
From PendingCosts
Join bJCCO With (NoLock) on bJCCO.JCCo=PendingCosts.PMCo

union all

Select
	 PendingCO.PMCo,
	 PendingCO.Project,
	 PendingCO.PhaseGroup,
	 PendingCO.Phase,
	 PendingCO.CostType,
	 bJCCO.GLCo as GLCo,
	 DATEADD(d,DATEDIFF(d,0,GETDATE()),0) - (Day(DATEADD(d,DATEDIFF(d,0,GETDATE()),0))-1) as Mth,
	 Null as CostTrans,
	 Null as UM,
	 DATEADD(d,DATEDIFF(d,0,GETDATE()),0) as ActualDate,
	 DATEADD(d,DATEDIFF(d,0,GETDATE()),0) as PostedDate,
	 Null as PRCo,
	 Null as Crew,
	 Null as ActualHours,
	 Null as ActualUnits,
     Null as ActualCost,
	 Null as OrigEstHours,
	 Null as OrigEstUnits,
	 Null as OrigEstCost,
	 Null as CurrEstHours,
	 Null as CurrEstUnits,
	 Null as CurrEstCost,
	 Null as ProjHours,
	 Null as ProjUnits,
	 Null as ProjCost,
	 Null as ForecastHours,
	 Null as ForecastUnits,
	 Null as ForecastCost,
	 Null as TotalCmtdUnits,
	 Null as TotalCmtdCost,
	 Null as RemainCmtdUnits,
	 Null as RemainCmtdCost,
	 Null as PendingEstCost,
	 Null as PMCmtdCost,
	 PendingCO.ACOCost_NonInterface,
	 PendingCO.PendingChgOrderCost,
     Null as EstCostComplete,
	 Null as ProjMethod,
	 Null as ProjMinPct,
	 Null as ActualCommittedCost,
     Null as ActualCommittedUnits,
     Null as ActualforForecastCost,
     Null as ActualforForecastUnits
From PendingCO
Join bJCCO With (NoLock) on bJCCO.JCCo=PendingCO.PMCo

) /*End Job Cost CTE*/

/*Final Select from JobCost CTE.  Join maintenance tables (i.e. bJCCo, bJCJM) to get KeyID's*/
select   bJCCO.KeyID as JCCoID
		,bPMCO.KeyID as PMCoID
        ,bJCJM.KeyID as JobID
        ,bJCJP.KeyID as JobPhaseID
		--,viDim_JCJobPhases.JobPhaseID
	    --,isnull(viDim_JCPhaseMaster.MasterPhaseID,0) as MasterPhaseID
        ,bJCCH.KeyID as JobPhaseCostTypeID
        ,bJCCT.KeyID as CostTypeID
        ,bJCCM.KeyID as ContractID
        ,bARCM.KeyID as CustomerID
        ,bJCCI.KeyID as ContractItemID
        ,bJCDM.KeyID as JCDeptID
        ,bJCCI.KeyID as DeptContractHierarchyID
		,isnull(bJCMP.KeyID,0) as ProjectMgrID
        ,JobCost.Mth
        ,Datediff(mm,'1/1/1950',JobCost.Mth) as MonthID
        ,JobCost.CostTrans as CostTransNumber
        ,JobCost.ActualDate
        ,Datediff(dd,'1/1/1950',JobCost.ActualDate) as ActualDateID
        ,JobCost.PostedDate
        ,Datediff(dd,'1/1/1950',JobCost.PostedDate) as PostedDateID
		,isnull(Cast(cast(bGLFP.GLCo as varchar(3))+cast(Datediff(dd,'1/1/1950',bGLFP.Mth) as varchar(10)) as int),0) as FiscalMthID
		,isnull(bPRCR.KeyID,0) as PRCrewID
        --,isnull(viDim_GLFiscalMth.FiscalMthID,0) as FiscalMthID
		,JobCost.ActualHours, JobCost.ActualUnits, JobCost.ActualCost /*Actual Measures*/
        ,JobCost.OrigEstHours
        ,JobCost.OrigEstUnits
        ,JobCost.OrigEstCost /*Original Estimate Measures*/
        ,JobCost.CurrEstHours
        ,JobCost.CurrEstUnits
        ,JobCost.CurrEstCost /*Current Estimate Measures*/
        ,JobCost.ProjHours, JobCost.ProjUnits, JobCost.ProjCost /*Projected Measures*/
        ,JobCost.ForecastHours, JobCost.ForecastUnits, Null as ForecastCost /*Forecast Measures*/
        ,JobCost.TotalCmtdUnits, JobCost.TotalCmtdCost, JobCost.RemainCmtdUnits, JobCost.RemainCmtdCost /*Committed Measures*/
		--,case when bJCCH.BuyOutYN='N' then (isnull(JobCost.CurrEstCost,0)+isnull(JobCost.ACOCost_NonInterface,0)) - isnull(JobCost.PMCmtdCost,0) else Null end as RemainingBuyout
		,(isnull(JobCost.CurrEstCost,0)+isnull(JobCost.ACOCost_NonInterface,0)) - isnull(JobCost.PMCmtdCost,0) as RemainingBuyout
        ,case when bJCCH.UM=JobCost.UM and bJCCH.PhaseUnitFlag='Y' then JobCost.OrigEstUnits end as OrigEstPhaseUnits /*Phase Units*/
		,case when bJCCH.UM=JobCost.UM and bJCCH.PhaseUnitFlag='Y' then JobCost.CurrEstUnits end as CurrEstPhaseUnits
		,case when bJCCH.UM=JobCost.UM and bJCCH.PhaseUnitFlag='Y' then JobCost.ProjUnits end as ProjPhaseUnits
		,case when bJCCH.UM=JobCost.UM and bJCCH.PhaseUnitFlag='Y' then JobCost.ForecastUnits end as ForecastPhaseUnits
		,case when bJCCH.UM=JobCost.UM and bJCCH.PhaseUnitFlag='Y' then JobCost.ActualUnits end as ActualPhaseUnits
		,case when bJCCH.UM=JobCost.UM and bJCCH.PhaseUnitFlag='Y' then JobCost.TotalCmtdUnits end as TotalCmtdPhaseUnits
		,case when bJCCH.UM=JobCost.UM and bJCCH.PhaseUnitFlag='Y' then JobCost.RemainCmtdUnits end as RemainCmtdPhaseUnits
		,JobCost.PendingEstCost
        ,JobCost.PMCmtdCost
		,JobCost.ACOCost_NonInterface
		,JobCost.PendingChgOrderCost   
        ,EstCostComplete
		,JobCost.ProjMethod
	    ,JobCost.ProjMinPct
		,Null as ProgressPctComplete /*Placeholder for Progress Units Complete.  Will be set to calc in Cube*/
		,JobCost.ActualCommittedCost
        ,JobCost.ActualCommittedUnits
        ,JobCost.ActualforForecastCost
        ,JobCost.ActualforForecastUnits
		,case when bJCCH.BuyOutYN='Y' then JobCost.ActualCommittedCost end as BuyOutFinalCosts
		,case when JobCost.ActualCommittedCost<>0 then 1
			  when JobCost.CurrEstCost<>0 then 1
			  else Null
		 end as ForecastIndicator /*Field that returns 1 if Actual+Committed or CurrentEstCost exists.
								    Use by Forecast calculations in Cube*/
		
        
        
From JobCost With (NoLock)
Join vDDBICompanies on vDDBICompanies.Co=JobCost.JCCo
Join bJCCO With (NoLock) on bJCCO.JCCo=JobCost.JCCo
Left Join bPMCO With (NoLock) on bPMCO.PMCo=JobCost.JCCo
Join bJCJM With (NoLock) on bJCJM.JCCo=JobCost.JCCo and bJCJM.Job=JobCost.Job
Left Join bJCMP With (NoLock) on bJCMP.JCCo=bJCJM.JCCo and bJCMP.ProjectMgr=bJCJM.ProjectMgr
Left Join bJCCT With (NoLock) on bJCCT.PhaseGroup=JobCost.PhaseGroup and bJCCT.CostType=JobCost.CostType
Left Join bJCJP With (NoLock) on bJCJP.JCCo=JobCost.JCCo and bJCJP.Job=JobCost.Job and bJCJP.PhaseGroup=JobCost.PhaseGroup
           and bJCJP.Phase=JobCost.Phase
/*Join viDim_JCJobPhases With (NoLock) on viDim_JCJobPhases.JCCo=JobCost.JCCo 
								 and viDim_JCJobPhases.Job=JobCost.Job
                                 and viDim_JCJobPhases.PhaseGroup=JobCost.PhaseGroup
                                 and viDim_JCJobPhases.JobPhase=JobCost.Phase
							     and viDim_JCJobPhases.JobPhaseCostType=JobCost.CostType*/
--Left Join viDim_JCPhaseMaster on viDim_JCPhaseMaster.PhaseGroup=JobCost.PhaseGroup and viDim_JCPhaseMaster.Phase=JobCost.Phase
Left Join bJCCM With (NoLock) on bJCCM.JCCo=bJCJP.JCCo and bJCCM.Contract=bJCJP.Contract
Left Join bARCM With (NoLock) on bARCM.CustGroup=bJCCM.CustGroup and bARCM.Customer=bJCCM.Customer
Left Join bJCCI With (NoLock) on bJCCI.JCCo=bJCJP.JCCo and bJCCI.Contract=bJCJP.Contract and bJCCI.Item=bJCJP.Item
Left Join bJCDM With (NoLock) on bJCDM.JCCo=bJCCI.JCCo and bJCDM.Department=bJCCI.Department
--Join GLFiscalMth With (NoLock) on GLFiscalMth.GLCo=JobCost.GLCo and GLFiscalMth.Mth=JobCost.Mth
Left Join bGLFP With (NoLock) on bGLFP.GLCo=JobCost.GLCo and bGLFP.Mth=JobCost.Mth
--Join viDim_GLFiscalMth With (NoLock) on viDim_GLFiscalMth.GLCo=bGLFP.GLCo and viDim_GLFiscalMth.Mth=bGLFP.Mth and viDim_GLFiscalMth.FiscalPd=bGLFP.FiscalPd
/*Join viDim_JCDeptContract_Hierarchy With (NoLock) 
                                 on viDim_JCDeptContract_Hierarchy.JCCo=bJCJP.JCCo
                                 and viDim_JCDeptContract_Hierarchy.Contract=bJCJP.Contract
                                 and viDim_JCDeptContract_Hierarchy.Item=bJCJP.Item*/
Left Join bJCCH on bJCCH.JCCo=JobCost.JCCo and bJCCH.Job=JobCost.Job and bJCCH.PhaseGroup=JobCost.PhaseGroup 
		   and bJCCH.Phase=JobCost.Phase and bJCCH.CostType=JobCost.CostType
Left Join bPRCR	on bPRCR.PRCo = JobCost.PRCo and bPRCR.Crew = JobCost.Crew	   
--Left Join JCProjMth on JCProjMth.JCCo=bJCCI.JCCo and JCProjMth.Contract=bJCCI.Contract and JCProjMth.Item=bJCCI.Item

/****** Object:  View [dbo].[viFact_JCRevenueDetail]    Script Date: 05/07/2009 14:24:44 ******/



GO
GRANT SELECT ON  [dbo].[viFact_JCDetail] TO [public]
GRANT INSERT ON  [dbo].[viFact_JCDetail] TO [public]
GRANT DELETE ON  [dbo].[viFact_JCDetail] TO [public]
GRANT UPDATE ON  [dbo].[viFact_JCDetail] TO [public]
GO
