SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.brptJCUnitCost    Script Date: 8/28/99 9:33:52 AM ******/
       -- drop proc brptJCUnitCost
      CREATE        proc [dbo].[brptJCUnitCost]
        (@JCCo bCompany, @BeginContract bContract ='', @EndContract bContract= 'zzzzzzzzz',
        @BeginDate bDate = '01/01/50', @EndDate bDate, @DateActPost varchar(1) = 'P', @JobActivity char(1))
        
     with recompile   
        /* created 03/18/97 Jim  Last change TF 3/26/98*/
        /*Added JobActivity parameter DH 6/19/01*/
        /* Mod 4/2/03 E.T. fixed to make ansii standard for Crystal 9.0 
                           fixed : using tables instead of views & non-ansii joins. Issue #20721 
           Mod 6/6/03 Issue 20731 DH Fixed Current Unit Price to calculate CurrConctractAmt/CurrContractUnits
    	Mod 7/21/03  issue not created yet....added NOLOCKS to the From Clause CR 
           Mod 8/7/03 JRE Issue 21900 - re-write for performance
           Mod 2/15/05 CR lengthened Phase from 16 to 20 Issue 26730    
		Mod 8/28/06 CR remmed out date where clause and inserted new case statement in the JCID section #26822
        Mod 9/6/06  CR re-wrote stored proc with new name, vrptJCUnitCost, keeping this one around for a limited time #120390
    */  
    as
declare @BeginPostedDate bDate,@EndPostedDate bDate,@BeginActualDate bDate,@EndActualDate bDate
    
    if @JCCo is null begin select @JCCo=0 end  --workaround for Crystal null issue
    
    select @BeginPostedDate=case when @DateActPost = 'P' then @BeginDate else '1/1/1950' end,
    	@EndPostedDate=case when @DateActPost = 'P' then @EndDate else '12/31/2050' end,
     	@BeginActualDate=case when @DateActPost <> 'P' then @BeginDate else '1/1/1950' end,
     	@EndActualDate=case when @DateActPost <> 'P' then @EndDate else '12/31/2050' end
    
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
       Contract varchar (10) NULL)
      
    
        /* insert Contract info */
        insert into #JCUnitCost
        (JCCo, Contract, Item, OrigContractAmt, OrigContractUnits, OrigUnitPrice,
           CurrContractAmt, CurrContractUnits, CurrUnitPrice,BilledAmt, BilledUnits,ReceivedAmt)
        
        /*declare @JCCo bCompany, @BeginContract bContract, @EndContract bContract,
        @BeginDate bDate, @EndDate bDate
        
        select @JCCo=1, @BeginContract='', @EndContract= 'zzzzzzzzz',
        @BeginDate= '01/01/51', @EndDate='01/01/20'*/
        
        Select JCCI.JCCo, JCCI.Contract, JCCI.Item,
        	JCCI.OrigContractAmt, JCCI.OrigContractUnits, JCCI.OrigUnitPrice,
        	sum(JCID.ContractAmt),sum(JCID.ContractUnits), JCCI.UnitPrice,
     	/*TerryL 04/01/2003,  Changed sum(JCID.UnitPrice) to JCCI.UnitPrice Issue 20731*/
                sum(JCID.BilledAmt), sum(JCID.BilledUnits), sum(JCID.ReceivedAmt)
        FROM  JCCI with (NOLOCK) --,JCID
        Left Join JCID with (NOLOCK) on JCID.JCCo=JCCI.JCCo and JCID.Contract=JCCI.Contract and JCID.Item=JCCI.Item
        where JCCI.JCCo=@JCCo and JCCI.Contract>=@BeginContract and JCCI.Contract<=@EndContract and /*JCID.PostedDate<=@EndDate--Issue 23855*/
              --JCID.PostedDate<=@EndPostedDate and JCID.ActualDate <=@EndActualDate
				case when (@DateActPost = 'P') then JCID.PostedDate  else JCID.ActualDate end <=@EndDate
        
        /*Order By JCCI.JCCo, JCCI.Contract, JCCI.Item*/
        group by
           JCCI.JCCo, JCCI.Contract, JCCI.Item,JCCI.OrigContractAmt, JCCI.OrigContractUnits,
           JCCI.OrigUnitPrice, JCCI.UnitPrice
        
        
        
        /* insert jtd Cost info */
        insert into #JCUnitCost
        (JCCo, Contract, Item, Job, PhaseGroup, Phase, CostType, CTAbbrev,
        OrigEstHours, OrigEstUnits, OrigEstItemUnits, OrigEstPhaseUnits, JCCHOrigEstCost, OrigEstCost,
        CurrEstHours, CurrEstUnits, CurrEstItemUnits, CurrEstPhaseUnits, CurrEstCost,
        ActualHours,  ActualUnits,  ActualItemUnits,  ActualPhaseUnits,  ActualCost,
        ProjHours, ProjUnits, ProjItemUnits, ProjPhaseUnits, ProjCost,
        PerActualHours,PerActualUnits,PerActualItemUnits, PerActualPhaseUnits, PerActualCost,
        DayActualHours,DayActualUnits,DayActualItemUnits, DayActualPhaseUnits, DayActualCost)
        
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
        sum(JCCD.ProjCost),
    ---
        sum(case when JCCD.PostedDate>=@BeginPostedDate and JCCD.ActualDate>=@BeginActualDate
                   and JCCD.PostedDate<=@EndPostedDate and JCCD.ActualDate<=@EndActualDate
                   then JCCD.ActualHours else 0 end),
        sum(case when JCCH.UM=JCCD.UM and JCCD.PostedDate>=@BeginPostedDate and JCCD.ActualDate>=@BeginActualDate
                   and JCCD.PostedDate<=@EndPostedDate and JCCD.ActualDate<=@EndActualDate
                   then JCCD.ActualUnits else 0 end),
        sum(case when JCCH.UM=JCCD.UM and JCCH.ItemUnitFlag='Y' 
                   and JCCD.PostedDate>=@BeginPostedDate and JCCD.ActualDate>=@BeginActualDate
                   and JCCD.PostedDate<=@EndPostedDate and JCCD.ActualDate<=@EndActualDate
                   then JCCD.ActualUnits else 0 end),
        sum(case when JCCH.UM=JCCD.UM and JCCH.PhaseUnitFlag='Y'
                   and JCCD.PostedDate>=@BeginPostedDate and JCCD.ActualDate>=@BeginActualDate
                   and JCCD.PostedDate<=@EndPostedDate and JCCD.ActualDate<=@EndActualDate
                   then JCCD.ActualUnits else 0 end),
        sum(case when JCCD.PostedDate>=@BeginPostedDate and JCCD.ActualDate>=@BeginActualDate
                   and JCCD.PostedDate<=@EndPostedDate and JCCD.ActualDate<=@EndActualDate
                   then JCCD.ActualCost else 0 end),
    --- Daily info
        sum (case when @DateActPost = 'P' and JCCD.PostedDate=@EndDate then JCCD.ActualHours
                  when @DateActPost <> 'P' and JCCD.ActualDate=@EndDate then JCCD.ActualHours
                  else 0 end),
        sum (case when @DateActPost = 'P' and JCCD.PostedDate=@EndDate and JCCH.UM=JCCD.UM then JCCD.ActualUnits
                  when @DateActPost <> 'P' and JCCD.ActualDate=@EndDate and JCCH.UM=JCCD.UM then JCCD.ActualUnits
                  else 0 end),
        sum (case when @DateActPost = 'P' and JCCD.PostedDate=@EndDate and JCCH.UM=JCCD.UM and JCCH.ItemUnitFlag='Y' 
                       then JCCD.ActualUnits
                  when @DateActPost <> 'P' and JCCD.ActualDate=@EndDate and JCCH.UM=JCCD.UM and JCCH.ItemUnitFlag='Y'
                       then JCCD.ActualUnits
                  else 0 end),
        sum (case when @DateActPost = 'P' and JCCD.PostedDate=@EndDate and JCCH.UM=JCCD.UM and JCCH.PhaseUnitFlag='Y'
    		   then JCCD.ActualUnits
                  when @DateActPost <> 'P' and JCCD.ActualDate=@EndDate and JCCH.UM=JCCD.UM and JCCH.PhaseUnitFlag='Y'
                       then JCCD.ActualUnits
                  else 0 end),
        sum (case when @DateActPost = 'P' and JCCD.PostedDate=@EndDate then JCCD.ActualCost
                  when @DateActPost <> 'P' and JCCD.ActualDate=@EndDate then JCCD.ActualCost
                  else 0 end)
    ---    
        FROM JCJP with (NOLOCK)
        Join JCCH with (NOLOCK)on JCCH.JCCo=JCJP.JCCo and JCCH.Job=JCJP.Job and JCCH.Phase=JCJP.Phase 
        Join JCCD with (NOLOCK)on JCCH.JCCo=JCCD.JCCo and JCCH.Job=JCCD.Job and JCCH.Phase=JCCD.Phase
        and JCCH.PhaseGroup=JCCD.PhaseGroup and JCCH.CostType=JCCD.CostType 
        and (case when @DateActPost = 'P' then JCCD.PostedDate  else JCCD.ActualDate end)<=@EndDate  
        -- JCCD.PostedDate<=@EndDate
        Join JCJM with (NOLOCK) on JCJP.JCCo=JCJM.JCCo and JCJP.Job=JCJM.Job
        Join JCCT with (NOLOCK) on JCCT.PhaseGroup=JCCH.PhaseGroup and JCCT.CostType=JCCH.CostType
        and JCJP.JCCo=@JCCo and JCJP.Contract>=@BeginContract and JCJP.Contract<=@EndContract
        
        /*  Join JCCD on JCCD.JCCo=JCJP.JCCo and JCCD.Job=JCJP.Job and JCCD.Phase=JCJP.Phase and JCCD.PhaseGroup=JCJP.PhaseGroup
              and JCCD.PostedDate<=@EndDate
          Join JCCH on JCCH.JCCo=JCCD.JCCo and JCCH.Job=JCCD.Job and JCCH.Phase=JCCD.Phase and JCCH.PhaseGroup=JCCD.PhaseGroup
              and JCCH.CostType=JCCD.CostType
          Join JCCT on JCCH.CostType=JCCT.CostType and JCCT.PhaseGroup=JCCH.PhaseGroup
    
        where JCJP.JCCo=@JCCo and JCJP.Contract>=@BeginContract and JCJP.Contract<=@EndContract*/
           group by JCJP.JCCo, JCJP.Contract, JCJP.Item, JCJP.Job, JCJP.Phase, JCJP.PhaseGroup, JCCD.CostType, JCCT.Abbreviation,
           JCCH.ItemUnitFlag,JCCH.PhaseUnitFlag, JCCD.JCTransType ,JCCD.UM, JCCH.UM
        
        
        /* insert ptd Cost info */
    /* no longer needed 
        insert into #JCUnitCost
        (JCCo, Contract, Item, Job, PhaseGroup, Phase, CostType, CTAbbrev,
          PerActualHours,PerActualUnits,PerActualItemUnits, PerActualPhaseUnits, PerActualCost)
        
        Select JCJP.JCCo, JCJP.Contract, JCJP.Item, JCJP.Job, JCJP.PhaseGroup, JCJP.Phase, JCCD.CostType, JCCT.Abbreviation,
        sum(JCCD.ActualHours),
        case when JCCH.UM=JCCD.UM then sum(JCCD.ActualUnits) else 0 end,
        case when(JCCH.UM=JCCD.UM and JCCH.ItemUnitFlag='Y') then sum(JCCD.ActualUnits) else 0 end,
        case when(JCCH.UM=JCCD.UM and JCCH.PhaseUnitFlag='Y') then sum(JCCD.ActualUnits) else 0 end,
        sum(JCCD.ActualCost)
        
        FROM JCJP with (NOLOCK) --,JCCD,JCCH,JCCT
        Join JCCH with (NOLOCK) on JCCH.JCCo=JCJP.JCCo and JCCH.Job=JCJP.Job and JCCH.PhaseGroup=JCJP.PhaseGroup and JCCH.Phase=JCJP.Phase 
        Join JCCD with (NOLOCK) on JCCD.JCCo=JCCH.JCCo and JCCD.Job=JCCH.Job and JCCD.PhaseGroup=JCCH.PhaseGroup and JCCD.Phase=JCCH.Phase
            and JCCD.CostType=JCCH.CostType
        Join JCCT with (NOLOCK) on JCCT.PhaseGroup=JCCH.PhaseGroup and JCCT.CostType=JCCH.CostType
        Where JCJP.JCCo=@JCCo and JCJP.Contract>=@BeginContract and JCJP.Contract<=@EndContract 
        and (case when @DateActPost = 'P' then JCCD.PostedDate else JCCD.ActualDate end)>=@BeginDate
        and (case when @DateActPost = 'P' then JCCD.PostedDate  else JCCD.ActualDate end)<=@EndDate 
        group by JCJP.JCCo, JCJP.Contract, JCJP.Item, JCJP.Job, JCJP.PhaseGroup, JCJP.Phase,
        JCCD.CostType, JCCT.Abbreviation, JCCH.UM, JCCD.UM, JCCH.ItemUnitFlag, JCCH.PhaseUnitFlag
        
        /*  Join JCCD on JCCD.JCCo=JCJP.JCCo and JCCD.Job=JCJP.Job and JCCD.Phase=JCJP.Phase and JCCD.PhaseGroup=JCJP.PhaseGroup
              and JCCD.PostedDate>=@BeginDate and JCCD.PostedDate<=@EndDate
          Join JCCH on JCCH.JCCo=JCCD.JCCo and JCCH.Job=JCCD.Job and JCCH.Phase=JCCD.Phase and JCCH.PhaseGroup=JCCD.PhaseGroup
              and JCCH.CostType=JCCD.CostType
          Join JCCT on JCCT.CostType=JCCH.CostType and  JCCT.PhaseGroup=JCCH.PhaseGroup
        where JCJP.JCCo=@JCCo and JCJP.Contract>=@BeginContract and JCJP.Contract<=@EndContract
           group by JCJP.JCCo, JCJP.Contract, JCJP.Item, JCJP.Job, JCJP.PhaseGroup, JCJP.Phase, JCCD.CostType, JCCT.Abbreviation,
           JCCH.UM, JCCD.UM, JCCH.ItemUnitFlag, JCCH.PhaseUnitFlag*/
     */   
        /* insert today Cost info */
    /* not needed 
        insert into #JCUnitCost
        (JCCo, Contract, Item, Job, PhaseGroup, Phase, CostType, CTAbbrev,
          DayActualHours,DayActualUnits,DayActualItemUnits, DayActualPhaseUnits, DayActualCost)
        
        
        Select JCJP.JCCo, JCJP.Contract, JCJP.Item,JCJP.Job, JCJP.PhaseGroup, JCJP.Phase, JCCD.CostType, JCCT.Abbreviation,
         sum(JCCD.ActualHours),
        
        case when JCCH.UM=JCCD.UM then sum(JCCD.ActualUnits) else 0 end,
        case when(JCCH.UM=JCCD.UM and JCCH.ItemUnitFlag='Y') then sum(JCCD.ActualUnits) else 0 end,
        case when(JCCH.UM=JCCD.UM and JCCH.PhaseUnitFlag='Y') then sum(JCCD.ActualUnits) else 0 end,
        sum(JCCD.ActualCost)
        FROM JCJP with (NOLOCK) --,JCCD,JCCH,JCCT
        Join JCCH with (NOLOCK) on JCCH.JCCo=JCJP.JCCo and JCCH.Job=JCJP.Job and JCCH.PhaseGroup=JCJP.PhaseGroup and JCCH.Phase=JCJP.Phase 
        Join JCCD with (NOLOCK) on JCCD.JCCo=JCCH.JCCo and JCCD.Job=JCCH.Job and JCCD.PhaseGroup=JCCH.PhaseGroup and JCCD.Phase=JCCH.Phase
              and JCCD.CostType=JCCH.CostType
        Join JCCT with (NOLOCK) on JCCT.PhaseGroup=JCCD.PhaseGroup and JCCT.CostType=JCCD.CostType
        Where JCJP.JCCo=@JCCo and JCJP.Contract>=@BeginContract and JCJP.Contract<=@EndContract
              and (case when @DateActPost = 'P' then JCCD.PostedDate else JCCD.ActualDate end ) = @EndDate 
      */
          /*Join JCCD on JCCD.JCCo=JCJP.JCCo and JCCD.Job=JCJP.Job and JCCD.Phase=JCJP.Phase and JCCD.PhaseGroup=JCJP.PhaseGroup
              and JCCD.PostedDate=@EndDate
          Join JCCH on JCCH.JCCo=JCCD.JCCo and JCCH.Job=JCCD.Job and JCCH.Phase=JCCD.Phase and JCCH.PhaseGroup=JCCD.PhaseGroup
              and JCCH.CostType=JCCD.CostType
          Join JCCT on JCCT.CostType=JCCH.CostType and JCCT.PhaseGroup=JCCH.PhaseGroup
        where JCJP.JCCo=@JCCo and JCJP.Contract>=@BeginContract and JCJP.Contract<=@EndContract and JCCD.PostedDate=@EndDate
        */
    /*
           group by JCJP.JCCo, JCJP.Contract, JCJP.Item, JCJP.Job, JCJP.Phase, JCCD.CostType, JCCT.Abbreviation, JCCH.UM, JCCD.UM,
           JCCH.ItemUnitFlag, JCCH.PhaseUnitFlag, JCJP.PhaseGroup
     */   
        
        /* select the results */
        
      insert into #JobActivity
      select JCCo, Contract From #JCUnitCost Group By JCCo, Contract having Max(case when @JobActivity<>'Y' then ActualCost else 1 end)<>0
      
        select a.JCCo, a.Contract, ContDesc=Min(JCCM.Description), ContractStatus=Min(JCCM.ContractStatus),
           a.Item, ItemDesc=JCCI.Description,a.Job,
        JobDesc=Min(JCJM.Description),JobStatus=JCJM.JobStatus,
           a.PhaseGroup, a.Phase, PhaseDesc=min(JCJP.Description),CostType=a.CostType, CTAbbrev=a.CTAbbrev,
          PhaseUM=min(case when JCCH.PhaseUnitFlag='Y' then JCCH.UM end),
          ItemUM=min(case when JCCH.ItemUnitFlag='Y' then JCCH.UM end),
          --PhaseUM=(select min(UM) from JCCH  where JCCH.JCCo=a.JCCo and JCCH.Job=a.Job and JCCH.Phase=a.Phase and JCCH.PhaseGroup=a.PhaseGroup and JCCH.PhaseUnitFlag='Y'),
          --ItemUM=(select min(UM) from JCCH where JCCH.JCCo=a.JCCo and JCCH.Job=a.Job and JCCH.Phase=a.Phase and JCCH.PhaseGroup=a.PhaseGroup and JCCH.ItemUnitFlag='Y'),
          JCCHUM=JCCH.UM, JCCIUM=JCCI.UM, BilledUnits=sum(a.BilledUnits), BilledAmt=sum(a.BilledAmt),ReceivedAmt=sum(a.ReceivedAmt),
           OrigContractUnits=sum(a.OrigContractUnits),
           OrigContractAmt=sum(a.OrigContractAmt),
           OrigUnitPrice=sum(a.OrigUnitPrice),
           CurrContractAmt=sum(a.CurrContractAmt),
           CurrContractUnits=sum(a.CurrContractUnits),
           CurrUnitPrice=(case when isnull(sum(a.CurrContractUnits),0)<>0 then sum(isnull(a.CurrContractAmt,0))/sum(a.CurrContractUnits) else 0 end),
        
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
        
        
          CoName=HQCO.Name,
        
          BeginDate=@BeginDate,
          EndDate=@EndDate,
          BeginContract=@BeginContract,
          EndContract=@EndContract,
          DateActPost=@DateActPost
       
        
        
           from #JCUnitCost a --,JCCI,JCJM,JCCM,HQCO,JCJP,JCCH, #JobActivity 
           Join JCCI on JCCI.JCCo=a.JCCo and JCCI.Contract=a.Contract and JCCI.Item=a.Item
           Left Join JCJM on JCJM.JCCo=a.JCCo and JCJM.Job=a.Job
           Join JCCM on JCCM.JCCo=JCCI.JCCo and JCCM.Contract=JCCI.Contract
           Join HQCO on HQCO.HQCo=JCCI.JCCo
           Left Join JCJP on JCJP.JCCo=a.JCCo and JCJP.Job=a.Job and JCJP.PhaseGroup=a.PhaseGroup and JCJP.Phase=a.Phase
           Left Join JCCH on JCCH.JCCo=a.JCCo and JCCH.Job=a.Job and JCCH.PhaseGroup=a.PhaseGroup and JCCH.Phase=a.Phase 
                 and JCCH.CostType=a.CostType
          Join #JobActivity on #JobActivity.JCCo=a.JCCo and #JobActivity.Contract=a.Contract
          /*  JOIN JCCI on JCCI.JCCo=a.JCCo and JCCI.Contract=a.Contract and
                 JCCI.Item=a.Item
            Left Join JCJM on JCJM.JCCo=a.JCCo and JCJM.Job=a.Job
            Join JCCM on JCCM.JCCo=JCCI.JCCo and JCCM.Contract=JCCI.Contract
            Join HQCO on HQCO.HQCo=JCCI.JCCo
            Left Join JCJP on JCJP.JCCo=a.JCCo and JCJP.Job=a.Job and JCJP.Phase=a.Phase and JCJP.PhaseGroup=a.PhaseGroup
            Left Join JCCH on JCCH.JCCo=a.JCCo and JCCH.Job=a.Job and JCCH.Phase=a.Phase and JCCH.PhaseGroup=a.PhaseGroup
            and JCCH.CostType=a.CostType*/
        
        group by a.JCCo, a.Contract, a.Item, a.Phase, a.CostType,
        a.JCCo, a.Job,
       --JCJM.Description,
       JCJM.JobStatus, 
       --  JCJP.Description,JCCM.Description,
             a.CTAbbrev, JCCI.Description,JCCI.UM, HQCO.Name,
             a.PhaseGroup,JCCH.UM

GO
GRANT EXECUTE ON  [dbo].[brptJCUnitCost] TO [public]
GO
