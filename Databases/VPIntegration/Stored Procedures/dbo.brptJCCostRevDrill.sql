SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.brptJCCostRevDrill    Script Date: 8/28/99 9:33:51 AM ******/
        /* Expanded the CostTrans to allow 7 character.  01/24/2003  E.T. */
        /* Mod 4/2/03 E.T. fixed to make ansii standard for Crystal 9.0 
                           fixed : using tables instead of views & non-ansii joins. Issue #20721 */
        /* Mod 5/19/2003 E.T. Modified stored procedure to remove the temp file to make it faster. Issue #12292 */
        /* Issue 25868 add with (nolock) DW 10/22/04*/
      CREATE                   proc [dbo].[brptJCCostRevDrill]
        (@JCCo bCompany, @BeginContract bContract ='', @EndContract bContract= 'zzzzzzzzz',
        @BeginDate bDate = '01/01/51', @EndDate bDate, @ThroughMonth bDate)
        as
   /*declare @JCCo bCompany, @BeginContract bContract, @EndContract bContract,
         @BeginDate bDate, @EndDate bDate, @ThroughMonth bDate
       
   Select @JCCo=1, @BeginContract=' 1000-', @EndContract= ' 1010-',
         @BeginDate= '01/01/51', @EndDate='01/01/2020', @ThroughMonth='01/01/2020'*/ 
           
        Select JCCI.JCCo, JCCI.Contract, JCCI.Item, 
        Job=null, PhaseGroup=null, Phase=null, CostType=null, CTAbbrev=null,
      --JCCI.OrigContractAmt,
           OrigContractAmt=(case when JCID.JCTransType='OC' then sum(JCID.ContractAmt) else 0 end),
      --JCCI.OrigContractUnits, 
           OrigContractUnits=(case when JCID.JCTransType='OC' then sum(JCID.ContractUnits) else 0 end), 	
        OrigUnitPrice=JCCI.OrigUnitPrice,
        CurrContractAmt=sum(JCID.ContractAmt),CurrContractUnits=sum(JCID.ContractUnits), 
        CurrUnitPrice=sum(JCID.UnitPrice), BilledAmt=sum(JCID.BilledAmt), 
        BilledUnits=sum(JCID.BilledUnits), ReceivedAmt=sum(JCID.ReceivedAmt), OrigEstHours=0, 
        OrigEstUnits=0, OrigEstItemUnits=0, OrigEstPhaseUnits=0, OrigEstCost=0, CurrEstHours=0, 
        CurrEstUnits=0, CurrEstItemUnits=0, CurrEstPhaseUnits=0, CurrEstCost=0, ActualHours=0, 
        ActualUnits=0, ActualItemUnits=0, ActualPhaseUnits=0, ActualCost=0, Mth=null, 
        CostTrans=null, PostedDate=null, ActualDate=null, JCTransType=null, Source=null, 
        DetailDesc=null, ProjHours=0, ProjUnits=0, ProjItemUnits=0, ProjPhaseUnits=0, ProjCost=0, 
        ContDesc=max(c.Description), ItemDesc=max(JCCI.Description), JCCIUM=max(JCCI.UM), CoName=max(h.Name), 
        JobDesc=null, JobStatus=null, PhaseDesc=null, PhaseUM=null, ItemUM=null, JCCHUM=null,
        BeginDate=@BeginDate, EndDate=@EndDate, BeginContract=@BeginContract,
        EndContract=@EndContract, ThroughMonth=@ThroughMonth
                  
        FROM  JCCI with(nolock) --,JCID
        Join HQCO h with(nolock) on h.HQCo=JCCI.JCCo
        Join JCCM c with(nolock) on c.JCCo=JCCI.JCCo and c.Contract=JCCI.Contract
        Left Join JCID with(nolock) on JCID.JCCo=JCCI.JCCo and JCID.Contract=JCCI.Contract and JCID.Item=JCCI.Item
       where JCCI.JCCo=@JCCo and JCCI.Contract>=@BeginContract and JCCI.Contract<=@EndContract and JCID.ActualDate<=@EndDate and JCID.Mth<=@ThroughMonth
      
             group by
           JCCI.JCCo, JCCI.Contract , JCCI.Item,
           JCID.JCTransType,JCCI.OrigUnitPrice
      
        /* insert jtd Cost info */
   
   UNION ALL   
   /*declare @JCCo bCompany, @BeginContract bContract, @EndContract bContract,
         @BeginDate bDate, @EndDate bDate, @ThroughMonth bDate
       
   Select @JCCo=10, @BeginContract='9802-', @EndContract= '9802-',
         @BeginDate= '01/01/51', @EndDate='01/01/2020', @ThroughMonth='01/01/2020'*/  
        Select JCJP.JCCo, JCJP.Contract, JCJP.Item, Job=JCJP.Job, PhaseGroup=JCJP.PhaseGroup, 
        Phase=JCJP.Phase, CostType=JCCD.CostType, CTAbbrev=JCCT.Abbreviation, OrigContractAmt=0, 
        OrigContractUnits=0, OrigUnitPrice=0, CurrContractAmt=0, CurrContractUnits=0, 
        CurrUnitPrice=0, BilledAmt=0, BilledUnits=0, ReceivedAmt=0,
        OrigEstHours=(case when JCCD.JCTransType='OE' then JCCD.EstHours else 0 end),
        OrigEstUnits=(case when (JCCH.UM=JCCD.UM  and JCCD.JCTransType='OE') then JCCD.EstUnits else 0 end),
        OrigEstItemUnits=(case when(JCCH.UM=JCCD.UM and JCCH.ItemUnitFlag='Y' and JCCD.JCTransType = 'OE')
            then JCCD.EstUnits else 0 end),
        OrigEstPhaseUnits=(case when(JCCH.UM=JCCD.UM and JCCH.PhaseUnitFlag='Y' and JCCD.JCTransType = 'OE')
   
            then JCCD.EstUnits else 0 end),
        OrigEstCost=(case when JCCD.JCTransType='OE' then JCCD.EstCost else 0 end),
        CurrEstHours=JCCD.EstHours,
        CurrEstUnits=(case when JCCH.UM=JCCD.UM then JCCD.EstUnits else 0 end),
        CurrEstItemUnits=(case when(JCCH.UM=JCCD.UM and JCCH.ItemUnitFlag='Y') then JCCD.EstUnits else 0 end),
        CurrEstPhaseUnits=(case when(JCCH.UM=JCCD.UM and JCCH.PhaseUnitFlag='Y') then JCCD.EstUnits else 0 end),
        CurrEstCost=JCCD.EstCost,
   -- (JCCD.ActualHours)
        ActualHours=(case when JCCD.ActualDate>=@BeginDate then JCCD.ActualHours else 0 end),
        ActualUnits=(case when (JCCH.UM=JCCD.UM and JCCD.ActualDate>=@BeginDate) then JCCD.ActualUnits else 0 end),
        ActualItemUnits=(case when(JCCH.UM=JCCD.UM and JCCH.ItemUnitFlag='Y'and JCCD.ActualDate>=@BeginDate)
            then JCCD.ActualUnits else 0 end),
        ActualPhaseUnits=(case when(JCCH.UM=JCCD.UM and JCCH.PhaseUnitFlag='Y' and JCCD.ActualDate>=@BeginDate)
            then JCCD.ActualUnits else 0 end),
    --  (JCCD.ActualCost),
        ActualCost=(case when JCCD.ActualDate>=@BeginDate then JCCD.ActualCost else 0 end),
        Mth=JCCD.Mth, CostTrans=JCCD.CostTrans, PostedDate=JCCD.PostedDate, ActualDate=JCCD.ActualDate, 
        JCTransType=JCCD.JCTransType, Source=JCCD.Source, DetailDesc=JCCD.Description, 
        ProjHours=JCCD.ProjHours,  
        ProjUnits=(case when JCCH.UM=JCCD.UM then JCCD.ProjUnits else 0 end),
        ProjItemUnits=(case when (JCCH.UM=JCCD.UM and JCCH.ItemUnitFlag='Y') then JCCD.ProjUnits else 0 end),
        ProjPhaseUnits=(case when(JCCH.UM=JCCD.UM and JCCH.PhaseUnitFlag='Y') then JCCD.ProjUnits else 0 end),
        ProjCost=JCCD.ProjCost, ContDesc=null, ItemDesc=null, JCCIUM=null, CoName=null, 
        JobDesc=JCJM.Description, JobStatus=JCJM.JobStatus, PhaseDesc=JCJP.Description,
        PhaseUM=(case when JCCH.PhaseUnitFlag='Y' then JCCH.UM else null end),
        ItemUM=(case when JCCH.ItemUnitFlag='Y' then JCCH.UM else null end),
        JCCHUM=JCCH.UM, BeginDate=@BeginDate, EndDate=@EndDate, BeginContract=@BeginContract,
        EndContract=@EndContract, ThroughMonth=@ThroughMonth
   
        FROM JCJP with(nolock)
        Join JCJM with(nolock) on JCJM.JCCo=JCJP.JCCo and JCJM.Job=JCJP.Job
        Join JCCD with(nolock) on JCCD.JCCo=JCJP.JCCo and JCCD.Job=JCJP.Job and JCCD.Phase=JCJP.Phase 
              and JCCD.PhaseGroup=JCJP.PhaseGroup
        Join JCCH with(nolock) on JCCH.JCCo=JCCD.JCCo and JCCH.Job=JCCD.Job and JCCH.Phase=JCCD.Phase 
              and JCCH.PhaseGroup=JCCD.PhaseGroup and JCCH.CostType=JCCD.CostType
        Join JCCT with(nolock) on JCCH.CostType=JCCT.CostType and JCCT.PhaseGroup=JCCH.PhaseGroup
        where JCJP.JCCo=@JCCo and JCJP.Contract>=@BeginContract and JCJP.Contract<=@EndContract 
              and JCCD.ActualDate<=@EndDate and JCCD.Mth<=@ThroughMonth

GO
GRANT EXECUTE ON  [dbo].[brptJCCostRevDrill] TO [public]
GO
