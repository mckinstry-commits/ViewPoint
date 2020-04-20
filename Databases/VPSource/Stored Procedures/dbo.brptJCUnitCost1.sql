SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[brptJCUnitCost1]
        (@JCCo bCompany, @BeginContract bContract ='', @EndContract bContract= 'zzzzzzzzzz',
        @BeginDate bDate = '01/01/50', @EndDate bDate='12/31/2050', @DateActPost varchar(1) = 'P', @JobActivity char(1))
        
   with recompile  as
    declare @BeginPostedDate bDate,@EndPostedDate bDate,@BeginActualDate bDate,@EndActualDate bDate
    
    if @JCCo is null begin select @JCCo=0 end
    select @BeginPostedDate=case when @DateActPost = 'P' then @BeginDate else '1/1/1950' end,
    	@EndPostedDate=case when @DateActPost = 'P' then @EndDate else '12/31/2050' end,
     	@BeginActualDate=case when @DateActPost <> 'P' then @BeginDate else '1/1/1950' end,
     	@EndActualDate=case when @DateActPost <> 'P' then @EndDate else '12/31/2050' end

 Select JCCH.JCCo, JCCH.Job, JCCH.PhaseGroup, JCCH.Phase, JCCH.CostType, JCCH.UM, CTAbbrev=JCCT.Abbreviation, JCJP.Contract, JCJP.Item ,ItemDesc=null,
Cost.OrigEstHours, Cost.OrigEstUnits, Cost.OrigEstItemUnits, Cost.OrigEstPhaseUnits, Cost.JCCHOrigEstCost, Cost.OrigEstCost,
Cost.CurrEstHours, Cost.CurrEstUnits, Cost.CurrEstItemUnits, Cost.CurrEstPhaseUnits, Cost.CurrEstCost, Cost.ActualHours, 
Cost.ActualUnits, Cost.ActualItemUnits, Cost.ActualPhaseUnits, Cost.ActualCost, Cost.ProjHours, Cost.ProjUnits, Cost.ProjItemUnits,
Cost.ProjPhaseUnits, Cost.ProjCost, Cost.PerActualHours, Cost.PerActualUnits, Cost.PerActualItemUnits, Cost.PerActualPhaseUnits,
Cost.PerActualCost,ContDesc=null, ContractStatus=null, Cost.PhaseUM, Cost.ItemUM,

OrigContractAmt=0, OrigContractUnits=0, OrigUnitPrice=0,
CurrContractAmt=0, CurrContractUnits=0, CurrUnitPrice=0, BilledAmt=0, BilledUnits=0, ReceivedAmt=0,CoName=HQCO.Name


from JCCH
Join JCCT with (NOLOCK) on JCCT.PhaseGroup=JCCH.PhaseGroup and JCCT.CostType=JCCH.CostType
Join HQCO with (NOLOCK) on JCCH.JCCo=HQCO.HQCo
Join JCJP with (Nolock) on JCCH.JCCo=JCJP.JCCo and JCCH.Job = JCJP.Job
        Join(select JCCD.JCCo, JCCD.Job, JCCD.PhaseGroup, JCCD.Phase, JCCD.CostType, JCCD.UM,
          PhaseUM=min(case when JCCH.PhaseUnitFlag='Y' then JCCH.UM end),
          ItemUM=min(case when JCCH.ItemUnitFlag='Y' then JCCH.UM end),
          OrigEstHours=case when (JCCD.JCTransType='OE') then sum(JCCD.EstHours) else 0 end,
          OrigEstUnits=case when JCCH.UM=JCCD.UM  and JCCD.JCTransType='OE' then sum(JCCD.EstUnits) else 0 end,
          OrigEstItemUnits=case when(JCCH.UM=JCCD.UM and JCCH.ItemUnitFlag='Y' and JCCD.JCTransType = 'OE')
             then sum(JCCD.EstUnits) else 0 end,
          OrigEstPhaseUnits=case when(JCCH.UM=JCCD.UM and JCCH.PhaseUnitFlag='Y' and JCCD.JCTransType = 'OE')
             then sum(JCCD.EstUnits) else 0 end,
          JCCHOrigEstCost=sum(JCCH.OrigCost),
          OrigEstCost=case when (JCCD.JCTransType='OE') then sum(JCCD.EstCost) else 0 end,
          CurrEstHours=sum(JCCD.EstHours),
          CurrEstUnits=case when JCCH.UM=JCCD.UM then sum(JCCD.EstUnits) else 0 end,
          CurrEstItemUnits=case when(JCCH.UM=JCCD.UM and JCCH.ItemUnitFlag='Y') then sum(JCCD.EstUnits) else 0 end,
          CurrEstPhaseUnits=case when(JCCH.UM=JCCD.UM and JCCH.PhaseUnitFlag='Y') then sum(JCCD.EstUnits) else 0 end,
          CurrEstCost=sum(JCCD.EstCost),
          ActualHours=sum(JCCD.ActualHours), 
          ActualUnits=case when JCCH.UM=JCCD.UM then sum(JCCD.ActualUnits) else 0 end,
          ActualItemUnits=case when(JCCH.UM=JCCD.UM and JCCH.ItemUnitFlag='Y') then sum(JCCD.ActualUnits) else 0 end,
          ActualPhaseUnits=case when(JCCH.UM=JCCD.UM and JCCH.PhaseUnitFlag='Y') then sum(JCCD.ActualUnits) else 0 end,
          ActualCost=sum(JCCD.ActualCost),
          ProjHours=sum(JCCD.ProjHours),  
          ProjUnits=case when JCCH.UM=JCCD.UM then sum(JCCD.ProjUnits) else 0 end,
          ProjItemUnits=case when(JCCH.UM=JCCD.UM and JCCH.ItemUnitFlag='Y') then sum(JCCD.ProjUnits) else 0 end,
          ProjPhaseUnits=case when(JCCH.UM=JCCD.UM and JCCH.PhaseUnitFlag='Y') then sum(JCCD.ProjUnits) else 0 end,
          ProjCost=sum(JCCD.ProjCost),
          PerActualHours=sum(case when JCCD.PostedDate>=@BeginPostedDate and JCCD.ActualDate>=@BeginActualDate
                   and JCCD.PostedDate<=@EndPostedDate and JCCD.ActualDate<=@EndActualDate
                   then JCCD.ActualHours else 0 end),
          PerActualUnits=sum(case when JCCH.UM=JCCD.UM and JCCD.PostedDate>=@BeginPostedDate and JCCD.ActualDate>=@BeginActualDate
                   and JCCD.PostedDate<=@EndPostedDate and JCCD.ActualDate<=@EndActualDate
                   then JCCD.ActualUnits else 0 end),
          PerActualItemUnits=sum(case when JCCH.UM=JCCD.UM and JCCH.ItemUnitFlag='Y' 
                   and JCCD.PostedDate>=@BeginPostedDate and JCCD.ActualDate>=@BeginActualDate
                   and JCCD.PostedDate<=@EndPostedDate and JCCD.ActualDate<=@EndActualDate
                   then JCCD.ActualUnits else 0 end),
          PerActualPhaseUnits=sum(case when JCCH.UM=JCCD.UM and JCCH.PhaseUnitFlag='Y'
                   and JCCD.PostedDate>=@BeginPostedDate and JCCD.ActualDate>=@BeginActualDate
                   and JCCD.PostedDate<=@EndPostedDate and JCCD.ActualDate<=@EndActualDate
                   then JCCD.ActualUnits else 0 end),
          PerActualCost=sum(case when JCCD.PostedDate>=@BeginPostedDate and JCCD.ActualDate>=@BeginActualDate
                   and JCCD.PostedDate<=@EndPostedDate and JCCD.ActualDate<=@EndActualDate
                   then JCCD.ActualCost else 0 end)   
          from JCCD
          Join JCCH with (NOLOCK) on JCCD.JCCo=JCCH.JCCo and JCCD.Job=JCCH.Job and JCCD.PhaseGroup=JCCH.PhaseGroup and 
                                 JCCD.Phase=JCCH.Phase and JCCD.CostType=JCCH.CostType
         
          group by JCCD.JCCo, JCCD.Job, JCCD.PhaseGroup, JCCD.Phase, JCCD.CostType, JCCD.JCTransType, JCCD.UM,
                  JCCH.UM, JCCH.ItemUnitFlag, JCCH.PhaseUnitFlag) as Cost

on Cost.JCCo=JCCH.JCCo and Cost.Job=JCCH.Job and Cost.PhaseGroup=JCCH.PhaseGroup and Cost.Phase=JCCH.Phase and Cost.CostType=JCCH.CostType
where @JCCo=JCCH.JCCo and JCJP.Contract >= @BeginContract and JCJP.Contract<=@EndContract

union all
       
Select JCCI.JCCo, null, null, null, null, null,null,JCCI.Contract, JCCI.Item,ItemDesc=JCCI.Description,
0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,ContDesc=Min(JCCM.Description), ContractStatus=Min(JCCM.ContractStatus), Null, Null,
        	JCCI.OrigContractAmt, JCCI.OrigContractUnits, JCCI.OrigUnitPrice,
        	sum(JCID.ContractAmt),sum(JCID.ContractUnits), JCCI.UnitPrice,
     	    sum(JCID.BilledAmt), sum(JCID.BilledUnits), sum(JCID.ReceivedAmt),null
        FROM  JCCI with (NOLOCK) 
        Join JCID with (NOLOCK) on JCID.JCCo=JCCI.JCCo and JCID.Contract=JCCI.Contract and JCID.Item=JCCI.Item
        Join JCCM with (NOLOCK) on JCCM.JCCo=JCCI.JCCo and JCCM.Contract=JCCI.Contract
        --Join HQCO with (NOLOCK) on HQCO.HQCo=JCCI.JCCo
        where JCCI.JCCo=@JCCo and JCCI.Contract>=@BeginContract and JCCI.Contract<=@EndContract and 
              case when (@DateActPost = 'P') then JCID.PostedDate  else JCID.ActualDate end <=@EndDate
            
        group by
           JCCI.JCCo, JCCI.Contract, JCCI.Item,JCCI.OrigContractAmt, JCCI.OrigContractUnits,
           JCCI.OrigUnitPrice, JCCI.UnitPrice, JCCI.Description
GO
GRANT EXECUTE ON  [dbo].[brptJCUnitCost1] TO [public]
GO
