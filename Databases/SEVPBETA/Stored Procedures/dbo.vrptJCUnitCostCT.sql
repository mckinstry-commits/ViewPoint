SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[vrptJCUnitCostCT]
       (@JCCo bCompany, @BeginJob bJob='', @EndJob bJob='zzzzzzzzzz',
       @BeginDate bDate = '01/01/50', @EndDate bDate, @DateActPost varchar(1) = 'P', @JobActivity char(1))
       
    with recompile   
  
   as
declare @BeginPostedDate bDate,@EndPostedDate bDate,@BeginActualDate bDate,@EndActualDate bDate
   
   if @JCCo is null begin select @JCCo=0 end  --workaround for Crystal null issue
   
   select @BeginPostedDate=case when @DateActPost = 'P' then @BeginDate else '1/1/1950' end,
   	@EndPostedDate=case when @DateActPost = 'P' then @EndDate else '12/31/2050' end,
    	@BeginActualDate=case when @DateActPost <> 'P' then @BeginDate else '1/1/1950' end,
    	@EndActualDate=case when @DateActPost <> 'P' then @EndDate else '12/31/2050' end
   


Select JCCH.JCCo, JCCH.Job, JCJM.Description, JCCH.PhaseGroup, JCCH.Phase, PhaseDesc=JCJP.Description, JCCH.CostType, JCCH.UM, CTAbbrev=JCCT.Abbreviation, JCJP.Contract, ContDesc=JCCM.Description, JCJP.Item ,ItemDesc=JCCI.Description,
Cost.OrigEstHours, Cost.OrigEstUnits, Cost.OrigEstItemUnits, Cost.OrigEstPhaseUnits, Cost.JCCHOrigEstCost, Cost.OrigEstCost,
Cost.CurrEstHours, Cost.CurrEstUnits, Cost.CurrEstItemUnits, Cost.CurrEstPhaseUnits, Cost.CurrEstCost, Cost.ActualHours, 
Cost.ActualUnits, Cost.ActualItemUnits, Cost.ActualPhaseUnits, Cost.ActualCost, Cost.ProjHours, Cost.ProjUnits, Cost.ProjItemUnits,
Cost.ProjPhaseUnits, Cost.ProjCost, Cost.PerActualHours, Cost.PerActualUnits, Cost.PerActualItemUnits, Cost.PerActualPhaseUnits,
Cost.PerActualCost, ContractStatus=null, Cost.PhaseUM, Cost.ItemUM,

OrigContractAmt=0, OrigContractUnits=0, OrigUnitPrice=0,
CurrContractAmt=0, CurrContractUnits=0, CurrUnitPrice=0, BilledAmt=0, BilledUnits=0, ReceivedAmt=0,CoName=HQCO.Name


from JCCH
Join JCCT with (NOLOCK) on JCCT.PhaseGroup=JCCH.PhaseGroup and JCCT.CostType=JCCH.CostType
Join HQCO with (NOLOCK) on JCCH.JCCo=HQCO.HQCo
join JCJM with (NOLOCK) on JCCH.JCCo=JCJM.JCCo and JCCH.Job=JCJM.Job
Join JCJP with (Nolock) on JCCH.JCCo=JCJP.JCCo and JCCH.Job = JCJP.Job and JCCH.PhaseGroup=JCJP.PhaseGroup and JCCH.Phase=JCJP.Phase
join JCCM with (NOLOCK) on JCJP.JCCo=JCCM.JCCo and JCJP.Contract=JCCM.Contract
join JCCI with (NOLOCK) on JCJP.JCCo=JCCI.JCCo and JCJP.Contract=JCCI.Contract and JCJP.Item=JCCI.Item
        Join(select JCCD.JCCo, JCCD.Job, JCCD.PhaseGroup, JCCD.Phase, JCCD.CostType, JCCD.UM,
          PhaseUM=min(case when JCCH.PhaseUnitFlag='Y' then JCCH.UM end),
          ItemUM=min(case when JCCH.ItemUnitFlag='Y' then JCCH.UM end),
          OrigEstHours=sum(case when (JCCD.JCTransType='OE') then JCCD.EstHours else 0 end),
          OrigEstUnits=sum(case when JCCH.UM=JCCD.UM  and JCCD.JCTransType='OE' then JCCD.EstUnits else 0 end),
          OrigEstItemUnits=sum(case when(JCCH.UM=JCCD.UM and JCCH.ItemUnitFlag='Y' and JCCD.JCTransType = 'OE')
             then JCCD.EstUnits else 0 end),
          OrigEstPhaseUnits=sum(case when(JCCH.UM=JCCD.UM and JCCH.PhaseUnitFlag='Y' and JCCD.JCTransType = 'OE')
             then JCCD.EstUnits else 0 end),
          JCCHOrigEstCost=sum(JCCH.OrigCost),
          OrigEstCost=sum(case when (JCCD.JCTransType='OE') then JCCD.EstCost else 0 end),
          CurrEstHours=sum(JCCD.EstHours),
          CurrEstUnits=sum(case when JCCH.UM=JCCD.UM then JCCD.EstUnits else 0 end),
          CurrEstItemUnits=sum(case when(JCCH.UM=JCCD.UM and JCCH.ItemUnitFlag='Y') then JCCD.EstUnits else 0 end),
          CurrEstPhaseUnits=sum(case when(JCCH.UM=JCCD.UM and JCCH.PhaseUnitFlag='Y') then JCCD.EstUnits else 0 end),
          CurrEstCost=sum(JCCD.EstCost),
          ActualHours=sum(JCCD.ActualHours), 
          ActualUnits=sum(case when JCCH.UM=JCCD.UM then JCCD.ActualUnits else 0 end),
          ActualItemUnits=sum(case when(JCCH.UM=JCCD.UM and JCCH.ItemUnitFlag='Y') then JCCD.ActualUnits else 0 end),
          ActualPhaseUnits=sum(case when(JCCH.UM=JCCD.UM and JCCH.PhaseUnitFlag='Y') then JCCD.ActualUnits else 0 end),
          ActualCost=sum(JCCD.ActualCost),
          ProjHours=sum(JCCD.ProjHours),  
          ProjUnits=sum(case when JCCH.UM=JCCD.UM then JCCD.ProjUnits else 0 end),
          ProjItemUnits=sum(case when(JCCH.UM=JCCD.UM and JCCH.ItemUnitFlag='Y') then JCCD.ProjUnits else 0 end),
          ProjPhaseUnits=sum(case when(JCCH.UM=JCCD.UM and JCCH.PhaseUnitFlag='Y') then JCCD.ProjUnits else 0 end),
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
                                 and (case when @DateActPost = 'P' then JCCD.PostedDate  else JCCD.ActualDate end)<=@EndDate
          group by JCCD.JCCo, JCCD.Job, JCCD.PhaseGroup, JCCD.Phase, JCCD.CostType, JCCD.UM) as Cost

on Cost.JCCo=JCCH.JCCo and Cost.Job=JCCH.Job and Cost.PhaseGroup=JCCH.PhaseGroup and Cost.Phase=JCCH.Phase and Cost.CostType=JCCH.CostType
where @JCCo=JCCH.JCCo and JCJP.Job >= @BeginJob and JCJP.Job<=@EndJob















/*

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
       Join JCCT with (NOLOCK) on JCCT.PhaseGroup=JCCH.PhaseGroup and JCCT.CostType=JCCH.CostType
       and JCJP.JCCo=@JCCo and JCJP.Job>=@BeginJob and JCJP.Job<=@EndJob
       Join JCJM with (NOLOCK) on JCCD.JCCo=JCJM.JCCo and JCCD.Job=JCJM.Job

group by JCJP.JCCo, JCJP.Contract, JCJP.Item, JCJP.Job, JCJP.Phase, JCJP.PhaseGroup, JCCD.CostType, JCCT.Abbreviation,
          JCCH.ItemUnitFlag,JCCH.PhaseUnitFlag, JCCD.JCTransType ,JCCD.UM, JCCH.UM
       
       

       
       /* select the results */
       
     insert into #JobActivity
     select JCCo, Contract From #JCUnitCost Group By JCCo, Contract having Max(case when @JobActivity<>'Y' then ActualCost else 1 end)<>0
     
       select a.JCCo, a.Contract, ContDesc=Min(JCCM.Description), ContractStatus=Min(JCCM.ContractStatus),
          a.Item, ItemDesc=JCCI.Description,a.Job,
       JobDesc=Min(JCJM.Description),JobStatus=JCJM.JobStatus,
          a.PhaseGroup, a.Phase, PhaseDesc=min(JCJP.Description),CostType=a.CostType, CTAbbrev=a.CTAbbrev,
         PhaseUM=min(case when JCCH.PhaseUnitFlag='Y' then JCCH.UM end),
         ItemUM=min(case when JCCH.ItemUnitFlag='Y' then JCCH.UM end),
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
         BeginJob=@BeginJob,      
         EndJob=@EndJob,
         DateActPost=@DateActPost
      
       
       
          from #JCUnitCost a 
          Join JCCI on JCCI.JCCo=a.JCCo and JCCI.Contract=a.Contract and JCCI.Item=a.Item
          Left Join JCJM on JCJM.JCCo=a.JCCo and JCJM.Job=a.Job
          Join JCCM on JCCM.JCCo=JCCI.JCCo and JCCM.Contract=JCCI.Contract
          Join HQCO on HQCO.HQCo=JCCI.JCCo
          Left Join JCJP on JCJP.JCCo=a.JCCo and JCJP.Job=a.Job and JCJP.PhaseGroup=a.PhaseGroup and JCJP.Phase=a.Phase
          Left Join JCCH on JCCH.JCCo=a.JCCo and JCCH.Job=a.Job and JCCH.PhaseGroup=a.PhaseGroup and JCCH.Phase=a.Phase 
                and JCCH.CostType=a.CostType
         Join #JobActivity on #JobActivity.JCCo=a.JCCo and #JobActivity.Contract=a.Contract
        
       
       group by a.JCCo, a.Contract, a.Item, a.Phase, a.CostType,
       a.JCCo, a.Job, JCJM.JobStatus, a.CTAbbrev, JCCI.Description,JCCI.UM, HQCO.Name, a.PhaseGroup,JCCH.UM
*/

GO
GRANT EXECUTE ON  [dbo].[vrptJCUnitCostCT] TO [public]
GO
