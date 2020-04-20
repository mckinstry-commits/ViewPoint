SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE      view [dbo].[brvJCUCDrilldown] as
/*
changed 1st select statement to gather data from JCCD instead of brvJCCDDetlDesc
issue 123718 CR



*/

select
      JCCo=JCCD.JCCo, Contract=max(JCJP.Contract), Item=max(JCJP.Item), ItemDesc=' ',Job=JCCD.Job,
      PhaseGroup=JCCD.PhaseGroup, Phase=JCCD.Phase, PhaseDesc=max(JCJP.Description), CostType=JCCD.CostType, 
      PhaseUM = max(case when JCCH.PhaseUnitFlag = 'Y' then JCCH.UM else ' ' end), 
      ItemUM= max(case when JCCH.ItemUnitFlag = 'Y' then JCCH.UM else ' ' end ), JCCIUM=' ', BilledUnits=0, BilledAmt=0, CurrContractUnits=0,
      CurrContractAmt=0, CurrUnitPrice=0, 
      CurrEstUnits=sum(case when JCCH.UM = JCCD.UM then JCCD.EstUnits else 0 end), 
      CurrEstItemUnits=sum(case when JCCH.UM = JCCD.UM and JCCH.ItemUnitFlag = 'Y' then JCCD.EstUnits else 0 end),
      CurrEstPhaseUnits=sum(case when JCCH.UM = JCCD.UM and JCCH.PhaseUnitFlag = 'Y' then JCCD.EstUnits else 0 end), 
      CurrEstCost=sum(JCCD.EstCost), ActualHours=sum(JCCD.ActualHours), 
      ActualUnits=sum(case when JCCH.UM = JCCD.UM then JCCD.ActualUnits else 0 end), 
      ActualItemUnits=sum(case when JCCH.UM = JCCD.UM and JCCH.ItemUnitFlag = 'Y' then JCCD.ActualUnits else 0 end), 
      ActualPhaseUnits=sum(case when JCCH.UM = JCCD.UM and JCCH.PhaseUnitFlag = 'Y' then JCCD.ActualUnits else 0 end), 
      ActualCost=sum(JCCD.ActualCost),
      Mth=JCCD.Mth, CostTrans=JCCD.CostTrans, PostedDate=max(JCCD.PostedDate), ActualDate=max(JCCD.ActualDate), 
      JCTransType=max(JCCD.JCTransType), Source=max(JCCD.Source), JCCDDesc=max(JCCD.Description), 
      ProjCost=sum(JCCD.ProjCost), PerActualHours=sum(JCCD.ActualHours),
      PerActualUnits=sum(JCCD.ActualUnits), 
      PerActualItemUnits=sum(case when JCCH.UM = JCCD.UM and JCCH.ItemUnitFlag = 'Y' then JCCD.ActualUnits else 0 end), 
      PerActualPhaseUnits=sum(case when JCCH.UM = JCCD.UM and JCCH.PhaseUnitFlag = 'Y' then JCCD.ActualUnits else 0 end),
      PerActualCost=sum(JCCD.ActualCost),  DetlDesc=Max(Description.DetlDesc), Record= 'JCCD'
   
   from
   JCCD
      join JCJP on JCCD.JCCo = JCJP.JCCo and JCCD.Job = JCJP.Job and
                JCCD.PhaseGroup = JCJP.PhaseGroup and JCCD.Phase = JCJP.Phase
      join JCCH on JCCD.JCCo = JCCH.JCCo and JCCD.Job = JCCH.Job and
                JCCD.PhaseGroup = JCCH.PhaseGroup and JCCD.Phase = JCCH.Phase and JCCD.CostType = JCCH.CostType

      left join (select JCCo=brvJCCDDetlDesc.JCCo, Job=brvJCCDDetlDesc.Job, Phase=brvJCCDDetlDesc.Phase, CT=brvJCCDDetlDesc.CostType, 
                 Mth=brvJCCDDetlDesc.Mth, CostTrans=brvJCCDDetlDesc.CostTrans, DetlDesc=brvJCCDDetlDesc.DetlDesc from brvJCCDDetlDesc ) as Description on
               JCCD.JCCo=Description.JCCo and JCCD.Job=Description.Job and JCCD.Phase=Description.Phase and 
               JCCD.CostType=Description.CT and JCCD.Mth=Description.Mth and JCCD.CostTrans=Description.CostTrans             
              

   group by JCCD.JCCo, JCCD.Mth, JCCD.CostTrans, JCCD.Job, 
            JCCD.PhaseGroup, JCCD.Phase, JCCD.CostType
   UNION ALL


   select
      JCCo=JCID.JCCo, Contract=JCID.Contract, Item=JCID.Item, ItemDesc=max(JCCI.Description), Job=max(JCJP.Job),
      PhaseGroup=max(JCJP.PhaseGroup),Phase=max(JCJP.Phase), PhaseDesc=' ',CostType=0, 
      PhaseUM=' ', ItemUM=' ', JCCIUM=min(JCCI.UM), BilledUnits=max(JCID.BilledUnits), BilledAmt=max(JCID.BilledAmt), CurrContractUnits=max(JCID.ContractUnits),
      CurrContractAmt=max(JCID.ContractAmt), CurrUnitPrice=0, CurrEstUnits=0, CurrEstItemUnits=0,
      CurrEstPhaseUnits=0, CurrEstCost=0, ActualHours=0,
      ActualUnits=0, ActualItemUnits=0, ActualPhaseUnits=0, ActualCost=0,
      Mth=JCID.Mth, CostTrans=0, JCID.PostedDate, JCID.ActualDate, NULL,
      NULL, NULL, ProjCost=0, PerActualHours=0,
      PerActualUnits=0, PerActualItemUnits=0, PerActualPhaseUnits=0,
      PerActualCost=0, NULL, Record = 'JCCI'
   from
   	JCCI
   	join JCID on JCCI.JCCo=JCID.JCCo and JCCI.Contract=JCID.Contract and JCCI.Item=JCID.Item
           left outer join JCJP on JCCI.JCCo=JCJP.JCCo and JCCI.Contract=JCJP.Contract and JCCI.Item = JCJP.Item
   
   group by JCID.JCCo, JCID.Mth, JCID.ItemTrans, JCID.Contract, JCID.Item, JCID.PostedDate, JCID.ActualDate

GO
GRANT SELECT ON  [dbo].[brvJCUCDrilldown] TO [public]
GRANT INSERT ON  [dbo].[brvJCUCDrilldown] TO [public]
GRANT DELETE ON  [dbo].[brvJCUCDrilldown] TO [public]
GRANT UPDATE ON  [dbo].[brvJCUCDrilldown] TO [public]
GRANT SELECT ON  [dbo].[brvJCUCDrilldown] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvJCUCDrilldown] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvJCUCDrilldown] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvJCUCDrilldown] TO [Viewpoint]
GO
