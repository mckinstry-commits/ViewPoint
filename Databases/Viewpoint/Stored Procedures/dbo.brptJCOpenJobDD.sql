SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.brptJCUnitCost    Script Date: 8/28/99 9:33:52 AM ******/
   -- drop proc brptJCOpenJobDD
  CREATE           proc dbo.brptJCOpenJobDD
    (@JCCo bCompany, @BeginJob bJob ='', @EndJob bJob = 'zzzzzzzzz',
    @BeginDate bDate = '01/01/51', @EndDate bDate, @DateActPost varchar(1) = 'P', @JobActivity char(1))
    
    
    /* created 03/18/97 Jim  Last change TF 3/26/98*/
    /*Added JobActivity parameter DH 6/19/01*/
    /* Mod 4/2/03 E.T. fixed to make ansii standard for Crystal 9.0 
                       fixed : non-ansii joins. Issue #20721 
  
     Mod 11/8/04 CR Added NoLock #25921
     Mod 2/15/05 CR lengthened Phase from 16 to 20 issue 26730
  */
  
    as
    create table #JCUnitCost
       (JCCo            tinyint              NULL,
       Contract        char(10)            NULL,
        Item              char(16)       NULL,
        OrigContractAmt   decimal(16,2)               NULL,
        OrigContractUnits decimal(12,3)                NULL,
        OrigUnitPrice     decimal(16,5)            NULL,
    
        CurrContractAmt   decimal(16,2)              NULL,
        CurrContractUnits decimal(12,3)              NULL,
        CurrUnitPrice     decimal(16,5)              NULL,
        BilledAmt           decimal(16,2)              NULL,
        BilledUnits           decimal(12,3)              NULL,
        ReceivedAmt		decimal(16,2)		NULL,
    
        Job             char(10)                 NULL,
        PhaseGroup        tinyint                  NULL,
        Phase           char(20)                 NULL,
        CostType		tinyint                  NULL,
        CTAbbrev        char(10)                  NULL,
    
    
        OrigEstHours       decimal(10,2)             NULL,
        OrigEstUnits        decimal(12,3)            NULL,
        OrigEstItemUnits        decimal(12,3)            NULL,
        OrigEstPhaseUnits        decimal(12,3)            NULL,
        JCCHOrigEstCost          decimal(16,2)            NULL,
        OrigEstCost         decimal(16,2)            NULL,
    
        CurrEstHours       decimal(10,2)             NULL,
        CurrEstUnits        decimal(12,3)            NULL,
        CurrEstItemUnits        decimal(12,3)            NULL,
        CurrEstPhaseUnits        decimal(12,3)            NULL,
        CurrEstCost         decimal(16,2)            NULL,
    
        ActualHours     decimal(10,2)            NULL,
        ActualUnits     decimal(12,3)            NULL,
        ActualItemUnits     decimal(12,3)            NULL,
        ActualPhaseUnits     decimal(12,3)            NULL,
        ActualCost      decimal(16,2)            NULL,
    
    
        ProjHours		decimal(10,2)		NULL,
        ProjUnits		decimal(12,3)            NULL,
        ProjItemUnits	decimal(12,3)		NULL,
        ProjPhaseUnits	decimal(12,3)		NULL,
        ProjCost		decimal(16,2)            NULL,
    
        PerActualHours     decimal(10,2)            NULL,
        PerActualUnits     decimal(12,3)            NULL,
        PerActualItemUnits     decimal(12,3)            NULL,
        PerActualPhaseUnits     decimal(12,3)            NULL,
        PerActualCost      decimal(16,2)            NULL,
    
        DayActualHours     decimal(10,2)            NULL,
        DayActualUnits     decimal(12,3)            NULL,
        DayActualItemUnits     decimal(12,3)            NULL,
        DayActualPhaseUnits     decimal(12,3)            NULL,
        DayActualCost      decimal(16,2)            NULL
    
    
    )
    
  create table #JobActivity
  (JCCo tinyint NULL,
   Job varchar (10) NULL)
  
    /* insert Contract info */
    insert into #JCUnitCost
    (JCCo, Contract, Item,Job, OrigContractAmt, OrigContractUnits, OrigUnitPrice,
     CurrContractAmt, CurrContractUnits, CurrUnitPrice,BilledAmt, BilledUnits,ReceivedAmt)
   
    Select JCCI.JCCo, JCCI.Contract, JCCI.Item,JCJP.Job,
    	JCCI.OrigContractAmt, JCCI.OrigContractUnits, JCCI.OrigUnitPrice,
    	sum(JCID.ContractAmt),
          sum(JCID.ContractUnits),
          sum(JCID.UnitPrice),
          sum(JCID.BilledAmt),
  
          sum(JCID.BilledUnits),
          sum(JCID.ReceivedAmt)
    FROM  JCCI with (NOLOCK)
    Left Join JCID with (NOLOCK) ON JCCI.JCCo = JCID.JCCo and JCCI.Contract = JCID.Contract and JCCI.Item = JCID.Item
    Inner Join JCJP with (NOLOCK) On JCCI.JCCo = JCJP.JCCo and JCCI.Contract = JCJP.Contract and JCCI.Item = JCJP.Item
    Where JCCI.JCCo=@JCCo and JCJP.Job>=@BeginJob and JCJP.Job<=@EndJob
    group by JCCI.JCCo, JCCI.Contract, JCCI.Item,JCJP.Job,JCCI.OrigContractAmt, JCCI.OrigContractUnits,JCCI.OrigUnitPrice
  
  
  /* insert jtd Cost info */
    insert into #JCUnitCost
    (JCCo, Contract, Item, Job, PhaseGroup, Phase, CostType, CTAbbrev,
    OrigEstHours, OrigEstUnits, OrigEstItemUnits, OrigEstPhaseUnits, JCCHOrigEstCost, OrigEstCost,
    CurrEstHours, CurrEstUnits, CurrEstItemUnits, CurrEstPhaseUnits, CurrEstCost,
    ActualHours,  ActualUnits,  ActualItemUnits,  ActualPhaseUnits,  ActualCost,
    ProjHours, ProjUnits, ProjItemUnits, ProjPhaseUnits, ProjCost)
    
    Select JCJP.JCCo, JCJP.Contract, JCJP.Item, JCJP.Job, JCJP.PhaseGroup, JCJP.Phase, JCCD.CostType, JCCT.Abbreviation,
    
    case when (JCCD.JCTransType='OE') then sum(JCCD.EstHours) else 0 end,
    case when JCCH.UM=JCCD.UM  and JCCD.JCTransType='OE' then sum(JCCD.EstUnits) else 0 end,
    case when(JCCH.UM=JCCD.UM and JCCH.ItemUnitFlag='Y' and JCCD.JCTransType = 'OE')
    then sum(JCCD.EstUnits) else 0 end,
    case when(JCCH.UM=JCCD.UM and JCCH.PhaseUnitFlag='Y' and JCCD.JCTransType = 'OE')
    then sum(JCCD.EstUnits) else 0 end,
    sum(JCCH.OrigCost),
    case when (JCCD.JCTransType='OE') then sum(JCCD.EstCost) else 0 end,
    
    sum(JCCD.EstHours),
    case when JCCH.UM=JCCD.UM then sum(JCCD.EstUnits) else 0 end,
    case when(JCCH.UM=JCCD.UM and JCCH.ItemUnitFlag='Y') then sum(JCCD.EstUnits) else 0 end,
    case when(JCCH.UM=JCCD.UM and JCCH.PhaseUnitFlag='Y') then sum(JCCD.EstUnits) else 0 end,
    sum(JCCD.EstCost),
    
    sum(JCCD.ActualHours), case when JCCH.UM=JCCD.UM then sum(JCCD.ActualUnits) else 0 end,
    case when(JCCH.UM=JCCD.UM and JCCH.ItemUnitFlag='Y') then sum(JCCD.ActualUnits) else 0 end,
    case when(JCCH.UM=JCCD.UM and JCCH.PhaseUnitFlag='Y') then sum(JCCD.ActualUnits) else 0 end,
    sum(JCCD.ActualCost),
    
    sum(JCCD.ProjHours),  case when JCCH.UM=JCCD.UM then sum(JCCD.ProjUnits) else 0 end,
    case when(JCCH.UM=JCCD.UM and JCCH.ItemUnitFlag='Y') then sum(JCCD.ProjUnits) else 0 end,
    case when(JCCH.UM=JCCD.UM and JCCH.PhaseUnitFlag='Y') then sum(JCCD.ProjUnits) else 0 end,
    sum(JCCD.ProjCost)
    
    FROM JCJP with (NOLOCK)
    Left Outer Join JCCH with (NOLOCK) on JCCH.JCCo=JCJP.JCCo and JCCH.Job=JCJP.Job and JCCH.PhaseGroup=JCJP.PhaseGroup and JCCH.Phase=JCJP.Phase 
    Left Outer Join JCCD with (NOLOCK) on JCCH.JCCo=JCCD.JCCo and JCCH.Job=JCCD.Job and JCCH.PhaseGroup=JCCD.PhaseGroup and JCCH.Phase=JCCD.Phase
        and JCCH.CostType=JCCD.CostType
    Join JCCT with (NOLOCK) on JCCT.PhaseGroup=JCCH.PhaseGroup and JCCT.CostType=JCCH.CostType
    Where JCJP.JCCo=@JCCo and JCJP.Job>=@BeginJob and JCJP.Job<=@EndJob 
        and (case when @DateActPost = 'P' then JCCD.PostedDate  else JCCD.ActualDate end)<=@EndDate  
    group by JCJP.JCCo, JCJP.Job, JCJP.Phase, JCJP.PhaseGroup, JCCD.CostType, 
    JCCT.Abbreviation,JCCH.ItemUnitFlag,JCCH.PhaseUnitFlag, JCCD.JCTransType,
    JCCD.UM, JCCH.UM,JCJP.Contract, JCJP.Item          
    
   /* insert ptd Cost info */
    insert into #JCUnitCost
    (JCCo, Contract, Item, Job, PhaseGroup, Phase, CostType, CTAbbrev,
      PerActualHours,PerActualUnits,PerActualItemUnits, PerActualPhaseUnits, PerActualCost)
    
    Select JCJP.JCCo, JCJP.Contract, JCJP.Item, JCJP.Job, JCJP.PhaseGroup, JCJP.Phase, JCCD.CostType, JCCT.Abbreviation,
    sum(JCCD.ActualHours),
    case when JCCH.UM=JCCD.UM then sum(JCCD.ActualUnits) else 0 end,
    case when(JCCH.UM=JCCD.UM and JCCH.ItemUnitFlag='Y') then sum(JCCD.ActualUnits) else 0 end,
    case when(JCCH.UM=JCCD.UM and JCCH.PhaseUnitFlag='Y') then sum(JCCD.ActualUnits) else 0 end,
    sum(JCCD.ActualCost)
    FROM JCJP with (NOLOCK)--,JCCD,JCCH,JCCT
    Join JCCH with (NOLOCK) on JCCH.JCCo=JCJP.JCCo and JCCH.Job=JCJP.Job and JCCH.PhaseGroup=JCJP.PhaseGroup and JCCH.Phase=JCJP.Phase  
    Join JCCD with (NOLOCK) on  JCCD.JCCo=JCCH.JCCo and JCCD.Job=JCCH.Job and JCCD.PhaseGroup=JCCH.PhaseGroup and JCCD.Phase=JCCH.Phase 
            and JCCD.CostType=JCCH.CostType
    Join JCCT with (NOLOCK) on JCCT.PhaseGroup=JCCD.PhaseGroup and JCCT.CostType=JCCD.CostType
    Where JCJP.JCCo=@JCCo and JCJP.Job>=@BeginJob and JCJP.Job<= @EndJob
    and (case when @DateActPost = 'P' then JCCD.PostedDate else JCCD.ActualDate end)>=@BeginDate
    and (case when @DateActPost = 'P' then JCCD.PostedDate  else JCCD.ActualDate end)<=@EndDate 
    group by JCJP.JCCo,  JCJP.Job, JCJP.PhaseGroup, JCJP.Phase,JCCD.CostType, 
    JCCT.Abbreviation, JCCH.UM, JCCD.UM, JCCH.ItemUnitFlag, JCCH.PhaseUnitFlag, 
    JCJP.Contract, JCJP.Item
  
   /* insert today Cost info */
    insert into #JCUnitCost
    (JCCo, Contract, Item,Job, PhaseGroup, Phase, CostType, CTAbbrev,
     DayActualHours,DayActualUnits,DayActualItemUnits, DayActualPhaseUnits, DayActualCost)
    
    Select JCJP.JCCo, JCJP.Contract, JCJP.Item,JCJP.Job, JCJP.PhaseGroup, JCJP.Phase, JCCD.CostType, JCCT.Abbreviation,
    sum(JCCD.ActualHours),
    case when JCCH.UM=JCCD.UM then sum(JCCD.ActualUnits) else 0 end,
    case when(JCCH.UM=JCCD.UM and JCCH.ItemUnitFlag='Y') then sum(JCCD.ActualUnits) else 0 end,
    case when(JCCH.UM=JCCD.UM and JCCH.PhaseUnitFlag='Y') then sum(JCCD.ActualUnits) else 0 end,
    sum(JCCD.ActualCost)
    FROM JCJP with (NOLOCK) --JCCD,JCCH,JCCT
    Join JCCH with (NOLOCK) on JCCH.JCCo=JCJP.JCCo and JCCH.Job=JCJP.Job and JCCH.PhaseGroup=JCJP.PhaseGroup and JCCH.Phase=JCJP.Phase  
    Join JCCD with (NOLOCK) on JCCD.JCCo=JCCH.JCCo and JCCD.Job=JCCH.Job and JCCD.PhaseGroup=JCCH.PhaseGroup and JCCD.Phase=JCCH.Phase
            and JCCD.CostType=JCCH.CostType
    Join JCCT with (NOLOCK) on JCCT.PhaseGroup=JCCD.PhaseGroup and JCCT.CostType=JCCD.CostType
    Where JCJP.JCCo=@JCCo and JCJP.Job>=@BeginJob and JCJP.Job<=@EndJob 
          and (case when @DateActPost = 'P' then JCCD.PostedDate else JCCD.ActualDate end ) = @EndDate 
    group by JCJP.JCCo,  JCJP.Job,JCJP.PhaseGroup, JCJP.Phase, JCCD.CostType,
          JCCT.Abbreviation, JCCH.UM, JCCD.UM,JCCH.ItemUnitFlag, JCCH.PhaseUnitFlag,
          JCJP.Contract, JCJP.Item
    
    
  insert into #JobActivity
  select JCCo, Job From #JCUnitCost Group By JCCo, Job having Max(case when @JobActivity<>'Y' then ActualCost else 1 end)<>0
  
  /* select the results */
  
  select
   a.JCCo, a.Job,a.PhaseGroup, a.Phase,CostType=a.CostType, CTAbbrev=a.CTAbbrev, JobStatus=JCJM.JobStatus,
       a.Contract, ContDesc=Min(JCCM.Description), ContractStatus=Min(JCCM.ContractStatus),
       a.Item, ItemDesc=JCCI.Description,
       JobDesc=Min(JCJM.Description),
       PhaseDesc=min(JCJP.Description),
       PhaseUM=Min(case when JCCH.PhaseUnitFlag='Y' then JCCH.UM end),
       ItemUM=Min(case when JCCH.PhaseUnitFlag='Y' then JCCH.UM end),
       JCCHUM=JCCH.UM, JCCIUM=JCCI.UM, BilledUnits=sum(a.BilledUnits), BilledAmt=sum(a.BilledAmt),ReceivedAmt=sum(a.ReceivedAmt),
       OrigContractUnits=sum(a.OrigContractUnits),
       OrigContractAmt=sum(a.OrigContractAmt),
       OrigUnitPrice=sum(a.OrigUnitPrice),
       CurrContractAmt=sum(a.CurrContractAmt),
       CurrContractUnits=sum(a.CurrContractUnits),
       CurrUnitPrice=sum(a.CurrUnitPrice),
    
       OrigEstHours=sum(a.OrigEstHours),
       OrigEstUnits=sum(a.OrigEstUnits),
    
       OrigEstItemUnits=sum(a.OrigEstItemUnits),
       OrigEstPhaseUnits=sum(a.OrigEstPhaseUnits),
       JCCHOrigEstCost=sum(a.JCCHOrigEstCost),
       OrigEstCost=sum(a.OrigEstCost),
    
       CurrEstHours=sum(a.CurrEstHours),
       CurrEstUnits=sum(a.CurrEstUnits),
       CurrEstItemUnits=sum(a.CurrEstItemUnits),
       CurrEstPhaseUnits=sum(a.CurrEstPhaseUnits),
       CurrEstCost=sum(a.CurrEstCost),
    
    
       ActualHours=sum(a.ActualHours),
       ActualUnits=sum(a.ActualUnits),
       ActualItemUnits=sum(a.ActualItemUnits),
       ActualPhaseUnits=sum(a.ActualPhaseUnits),
       ActualCost=sum(a.ActualCost),
    
       ProjHours=sum(a.ProjHours),
       ProjUnits=sum(a.ProjUnits),
       ProjItemUnits=sum(a.ProjItemUnits),
       ProjPhaseUnits=sum(a.ProjPhaseUnits),
       ProjCost=sum(a.ProjCost),
    
       PerActualHours=sum(a.PerActualHours),
       PerActualUnits=sum(a.PerActualUnits),
       PerActualItemUnits=sum(a.PerActualItemUnits),
       PerActualPhaseUnits=sum(a.PerActualPhaseUnits),
       PerActualCost=sum(a.PerActualCost),
    
       DayActualHours=sum(DayActualHours),
       DayActualUnits=sum(DayActualUnits),
       DayActualItemUnits=sum(a.DayActualItemUnits),
       DayActualPhaseUnits=sum(a.DayActualPhaseUnits),
       DayActualCost=sum(a.DayActualCost),
   
      CoName = HQCO.Name,
   
     BeginDate=@BeginDate,
      EndDate=@EndDate,
      BeginJob =@BeginJob,
      EndJob=@EndJob,
      DateActPost=@DateActPost
    
      from #JCUnitCost a
       Left Join JCCI with (NOLOCK) on a.JCCo = JCCI.JCCo and a.Contract = JCCI.Contract and a.Item = JCCI.Item
       Left Join JCJM with (NOLOCK) on a.JCCo = JCJM.JCCo and a.Job = JCJM.Job 	    	
       Left Join JCCM with (NOLOCK) on JCCI.JCCo = JCCM.JCCo and JCCI.Contract = JCCM.Contract
       Inner Join HQCO with (NOLOCK) on a.JCCo = HQCO.HQCo
       Left Join JCJP with (NOLOCK) on a.JCCo = JCJP.JCCo and a.Job = JCJP.Job and a.PhaseGroup = JCJP.PhaseGroup
       and a.Phase = JCJP.Phase
       Left Join JCCH with (NOLOCK) on a.JCCo= JCCH.JCCo and a.Job= JCCH.Job and a.Phase = JCCH.Phase 
       and a.PhaseGroup = JCCH.PhaseGroup and a.CostType = JCCH.CostType
       Inner Join #JobActivity  On a.JCCo=#JobActivity.JCCo and a.Job=#JobActivity.Job 
  
  Group By  a.JCCo, a.Job, a.PhaseGroup,a.Phase,a.CostType,
            a.CTAbbrev, JCCH.UM, JCJM.JobStatus,a.Contract, a.Item,JCCI.Description,JCCI.UM,HQCO.Name
GO
GRANT EXECUTE ON  [dbo].[brptJCOpenJobDD] TO [public]
GO
