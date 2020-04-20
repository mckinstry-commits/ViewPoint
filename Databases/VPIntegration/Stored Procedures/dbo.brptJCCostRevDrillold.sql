SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.brptJCCostRevDrill    Script Date: 8/28/99 9:33:51 AM ******/
     /* Expanded the CostTrans to allow 7 character.  01/24/2003  E.T. */
     /* Mod 4/2/03 E.T. fixed to make ansii standard for Crystal 9.0 
                        fixed : using tables instead of views & non-ansii joins. Issue #20721 */
   CREATE     proc dbo.brptJCCostRevDrillold
     (@JCCo bCompany, @BeginContract bContract ='', @EndContract bContract= 'zzzzzzzzz',
     @BeginDate bDate = '01/01/51', @EndDate bDate, @ThroughMonth bDate)
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
         Mth             smalldatetime       Null,
         CostTrans           numeric(7)          Null,
         PostedDate      smalldatetime                Null,
         ActualDate      smalldatetime                Null,
         TransType       varchar(2)          Null,
         Source          varchar(10)         Null,
         DetailDesc      varchar(60)         Null,
   
         ProjHours		decimal(10,2)		NULL,
         ProjUnits		decimal(12,3)            NULL,
         ProjItemUnits	decimal(12,3)		NULL,
   
         ProjPhaseUnits	decimal(12,3)		NULL,
         ProjCost		decimal(16,2)            NULL
     )
   
     /* insert Contract info */
     insert into #JCUnitCost
     (JCCo, Contract, Item, OrigContractAmt, OrigContractUnits, OrigUnitPrice,
        CurrContractAmt, CurrContractUnits, CurrUnitPrice,BilledAmt, BilledUnits,ReceivedAmt)
   
     /*declare @JCCo bCompany, @BeginContract bContract, @EndContract bContract,
     @BeginDate bDate, @EndDate bDate, @ThroughMonth bDate
   
     select @JCCo=1, @BeginContract='', @EndContract= 'zzzzzzzzz',
     @BeginDate= '01/01/51', @EndDate='01/01/2020', @ThroughMonth='01/01/2020' */
   
     Select JCCI.JCCo, JCCI.Contract, JCCI.Item,
     	case when (JCID.JCTransType='OC') then sum(JCID.ContractAmt) else 0 end,
   --JCCI.OrigContractAmt,
    	case when (JCID.JCTransType='OC') then sum(JCID.ContractUnits) else 0 end,
   --JCCI.OrigContractUnits,
   JCCI.OrigUnitPrice,
     	sum(JCID.ContractAmt),sum(JCID.ContractUnits), sum(JCID.UnitPrice),
             sum(JCID.BilledAmt), sum(JCID.BilledUnits), sum(JCID.ReceivedAmt)
     FROM  JCCI --,JCID
     /*Where JCCI.JCCo*=JCID.JCCo and JCCI.Contract*=JCID.Contract and JCCI.Item*=JCID.Item
     and JCCI.JCCo=@JCCo and JCCI.Contract>=@BeginContract and JCCI.Contract<=@EndContract
     and JCID.ActualDate<=@EndDate and JCID.Mth<=@ThroughMonth*/
     Left Join JCID on JCID.JCCo=JCCI.JCCo and JCID.Contract=JCCI.Contract and JCID.Item=JCCI.Item
    where JCCI.JCCo=@JCCo and JCCI.Contract>=@BeginContract and JCCI.Contract<=@EndContract and JCID.ActualDate<=@EndDate and JCID.Mth<=@ThroughMonth
   
     /*Order By JCCI.JCCo, JCCI.Contract, JCCI.Item*/
     group by
        JCCI.JCCo, JCCI.Contract, JCCI.Item,
   --JCCI.OrigContractAmt, JCCI.OrigContractUnits,
        JCID.JCTransType,JCCI.OrigUnitPrice
   
     /* insert jtd Cost info */
     insert into #JCUnitCost
     (JCCo, Contract, Item, Job, PhaseGroup, Phase, CostType, CTAbbrev,
     OrigEstHours, OrigEstUnits, OrigEstItemUnits, OrigEstPhaseUnits, OrigEstCost,
     CurrEstHours, CurrEstUnits, CurrEstItemUnits, CurrEstPhaseUnits, CurrEstCost,
     ActualHours,  ActualUnits,  ActualItemUnits,  ActualPhaseUnits,  ActualCost,
   
     Mth, CostTrans, PostedDate, ActualDate, TransType,  Source,   DetailDesc,
   
     ProjHours, ProjUnits, ProjItemUnits, ProjPhaseUnits, ProjCost)
   
   
     Select JCJP.JCCo, JCJP.Contract, JCJP.Item, JCJP.Job, JCJP.PhaseGroup, JCJP.Phase, JCCD.CostType,
     JCCT.Abbreviation,
   
     case when (JCCD.JCTransType='OE') then (JCCD.EstHours) else 0 end,
     case when JCCH.UM=JCCD.UM  and JCCD.JCTransType='OE' then (JCCD.EstUnits) else 0 end,
     case when(JCCH.UM=JCCD.UM and JCCH.ItemUnitFlag='Y' and JCCD.JCTransType = 'OE')
     then (JCCD.EstUnits) else 0 end,
     case when(JCCH.UM=JCCD.UM and JCCH.PhaseUnitFlag='Y' and JCCD.JCTransType = 'OE')
     then (JCCD.EstUnits) else 0 end,
     case when (JCCD.JCTransType='OE') then (JCCD.EstCost) else 0 end,
   
     (JCCD.EstHours),
     case when JCCH.UM=JCCD.UM then (JCCD.EstUnits) else 0 end,
     case when(JCCH.UM=JCCD.UM and JCCH.ItemUnitFlag='Y') then (JCCD.EstUnits) else 0 end,
     case when(JCCH.UM=JCCD.UM and JCCH.PhaseUnitFlag='Y') then (JCCD.EstUnits) else 0 end,
     (JCCD.EstCost),
   
   -- (JCCD.ActualHours)
     case when JCCD.ActualDate>=@BeginDate then (JCCD.ActualHours) else 0 end,
     case when (JCCH.UM=JCCD.UM and JCCD.ActualDate>=@BeginDate) then (JCCD.ActualUnits) else 0 end,
     case when(JCCH.UM=JCCD.UM and JCCH.ItemUnitFlag='Y'and JCCD.ActualDate>=@BeginDate)
   	then (JCCD.ActualUnits) else 0 end,
     case when(JCCH.UM=JCCD.UM and JCCH.PhaseUnitFlag='Y' and JCCD.ActualDate>=@BeginDate)
   	then (JCCD.ActualUnits) else 0 end,
   --  (JCCD.ActualCost),
     case when (JCCD.ActualDate>=@BeginDate) then (JCCD.ActualCost) else 0 end,
   JCCD.Mth, JCCD.CostTrans, JCCD.PostedDate, JCCD.ActualDate, JCCD.JCTransType,
     JCCD.Source, JCCD.Description,
     (JCCD.ProjHours),  case when JCCH.UM=JCCD.UM then (JCCD.ProjUnits) else 0 end,
     case when(JCCH.UM=JCCD.UM and JCCH.ItemUnitFlag='Y') then (JCCD.ProjUnits) else 0 end,
     case when(JCCH.UM=JCCD.UM and JCCH.PhaseUnitFlag='Y') then (JCCD.ProjUnits) else 0 end,
     (JCCD.ProjCost)
   
     FROM JCJP --,JCCD,JCCH,JCCT
     /*where JCCD.JCCo=JCJP.JCCo and JCCD.Job=JCJP.Job and JCCD.Phase=JCJP.Phase and
     JCCD.PhaseGroup=JCJP.PhaseGroup and JCCD.ActualDate<=@EndDate and JCCD.Mth<=@ThroughMonth
     and JCCH.JCCo=JCCD.JCCo and JCCH.Job=JCCD.Job and JCCH.Phase=JCCD.Phase
     and JCCH.PhaseGroup=JCCD.PhaseGroup and JCCH.CostType=JCCD.CostType and
     JCCT.PhaseGroup=JCCH.PhaseGroup and JCCT.CostType=JCCH.CostType
     and JCJP.JCCo=@JCCo and JCJP.Contract>=@BeginContract and JCJP.Contract<=@EndContract*/
   
     Join JCCD on JCCD.JCCo=JCJP.JCCo and JCCD.Job=JCJP.Job and JCCD.Phase=JCJP.Phase and JCCD.PhaseGroup=JCJP.PhaseGroup
     Join JCCH on JCCH.JCCo=JCCD.JCCo and JCCH.Job=JCCD.Job and JCCH.Phase=JCCD.Phase and JCCH.PhaseGroup=JCCD.PhaseGroup
           and JCCH.CostType=JCCD.CostType
     Join JCCT on JCCH.CostType=JCCT.CostType and JCCT.PhaseGroup=JCCH.PhaseGroup
     where JCJP.JCCo=@JCCo and JCJP.Contract>=@BeginContract and JCJP.Contract<=@EndContract and JCCD.ActualDate<=@EndDate and JCCD.Mth<=@ThroughMonth
      /*  group by JCJP.JCCo, JCJP.Contract, JCJP.Item, JCJP.Job, JCJP.Phase, JCJP.PhaseGroup, JCCD.CostType, JCCT.Abbreviation,
        JCCH.ItemUnitFlag,JCCH.PhaseUnitFlag, JCCD.JCTransType ,JCCD.UM, JCCH.UM*/
   
     /* select the results */
   
     select a.JCCo, a.Contract, ContDesc=JCCM.Description,
        a.Item, ItemDesc=JCCI.Description,a.Job,
     JobDesc=JCJM.Description,JobStatus=JCJM.JobStatus,
        a.PhaseGroup, a.Phase, PhaseDesc=JCJP.Description,CostType=a.CostType, CTAbbrev=a.CTAbbrev,
     PhaseUM=(select Min(JCCH.UM) from JCCH
     where JCCH.JCCo=a.JCCo and JCCH.Job=a.Job and JCCH.Phase=a.Phase and JCCH.PhaseGroup=a.PhaseGroup
     and JCCH.PhaseUnitFlag='Y'),
     ItemUM=(select Min(JCCH.UM) from JCJP, JCCH
     where JCCH.JCCo=JCJP.JCCo and JCCH.Job=JCJP.Job and JCCH.Phase=JCJP.Phase and JCCH.PhaseGroup=JCJP.PhaseGroup
     and JCJP.JCCo=a.JCCo and JCJP.Contract=a.Contract and JCJP.Item=a.Item
     and JCCH.ItemUnitFlag='Y'),JCCHUM=JCCH.UM,
       JCCIUM=JCCI.UM, a.BilledUnits, a.BilledAmt,a.ReceivedAmt,
       a.OrigContractUnits,
        a.OrigContractAmt,
       a.OrigUnitPrice,
        a.CurrContractAmt,
   
        a.CurrContractUnits,
        a.CurrUnitPrice,
   
        a.OrigEstHours,
        a.OrigEstUnits,
   
        a.OrigEstItemUnits,
   
        a.OrigEstPhaseUnits,
        a.OrigEstCost,
   
        a.CurrEstHours,
       a.CurrEstUnits,
        a.CurrEstItemUnits,
        a.CurrEstPhaseUnits,
       a.CurrEstCost,
   
        a.ActualHours,
        a.ActualUnits,
        a.ActualItemUnits,
        a.ActualPhaseUnits,
        a.ActualCost,
        a.Mth,a.CostTrans,a.PostedDate,a.ActualDate,a.TransType,a.Source,a.DetailDesc,
   
   
        a.ProjHours,
        a.ProjUnits,
        a.ProjItemUnits,
   
        a.ProjPhaseUnits,
        a.ProjCost,
   
       CoName=HQCO.Name,
   
       BeginDate=@BeginDate,
       EndDate=@EndDate,
       BeginContract=@BeginContract,
       EndContract=@EndContract,
       ThroughMonth=@ThroughMonth
   
        from #JCUnitCost a --,JCCI,JCJM,JCCM,HQCO,JCJP,JCCH
        /*where JCCI.JCCo=a.JCCo and JCCI.Contract=a.Contract and
              JCCI.Item=a.Item
   
              and a.JCCo*=JCJM.JCCo and a.Job*=JCJM.Job
   
              and JCCM.JCCo=JCCI.JCCo and JCCM.Contract=JCCI.Contract
   
              and HQCO.HQCo=JCCI.JCCo
   
              and a.JCCo*=JCJP.JCCo and a.Job*=JCJP.Job and a.Phase*=JCJP.Phase
              and a.PhaseGroup*=JCJP.PhaseGroup
   
              and a.JCCo*=JCCH.JCCo and a.Job*=JCCH.Job and a.Phase*=JCCH.Phase and
   
              a.PhaseGroup*=JCCH.PhaseGroup
              and a.CostType*=JCCH.CostType*/
   
   
         JOIN JCCI on JCCI.JCCo=a.JCCo and JCCI.Contract=a.Contract and JCCI.Item=a.Item
         Left Join JCJM on JCJM.JCCo=a.JCCo and JCJM.Job=a.Job
         Join JCCM on JCCM.JCCo=JCCI.JCCo and JCCM.Contract=JCCI.Contract
         Join HQCO on HQCO.HQCo=JCCI.JCCo
         Left Join JCJP on JCJP.JCCo=a.JCCo and JCJP.Job=a.Job and JCJP.Phase=a.Phase and JCJP.PhaseGroup=a.PhaseGroup
         Left Join JCCH on JCCH.JCCo=a.JCCo and JCCH.Job=a.Job and JCCH.Phase=a.Phase and JCCH.PhaseGroup=a.PhaseGroup and JCCH.CostType=a.CostType
 
   
     /*group by JCCI.JCCo, a.JCCo, JCCI.Contract, JCCM.Description,
        JCCI.Item, a.Job,JCJM.Description,JCJM.JobStatus, a.Phase, JCJP.Description,
   
     /*   a.CostType,*/
          a.CTAbbrev, JCCI.Description,JCCI.UM, HQCO.Name,
        a.PhaseGroup,JCCH.UM*/
GO
GRANT EXECUTE ON  [dbo].[brptJCCostRevDrillold] TO [public]
GO
