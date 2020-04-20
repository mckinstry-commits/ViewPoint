SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.brptJCUnitCostDrillDown    Script Date: 8/28/99 9:33:52 AM ******/
   --drop proc brptJCUnitCostDrillDown
   CREATE            proc [dbo].[brptJCUnitCostDrillDown]
   (@JCCo bCompany, @BeginContract bContract ='', @EndContract bContract= 'zzzzzzzzzz',
   @BeginDate bDate = '01/01/50', @EndDate bDate,@ThruMth bMonth, @DateActPost varchar(1) = 'P')
   
   
   /* created 03/18/97 Jim  Last change TF 3/26/98*/
   /* 2/26/00 changed to use current joins and ThroughMonth
      BeginDate param used for period info only-Contract amts are always Through @EndDate and @ThruMth*/
   /* Mod 4/2/03 E.T. fixed to make ansii standard for Crystal 9.0 
                         fixed : using tables instead of views & non-ansi joins. Issue #20721 
     Mod 10/28/07 CR  changed JCJM link to Left from Equal in last select statment  Issue 25343 */
   /* Issue 25873 add with (nolock) DW 10/22/04
      Mod 2/15/05 CR lengthened Phase from 16 to 20 Issue 26730*/  
   as
   create table #JCUnitCost
      (JCCo		tinyint		NULL,
       Contract		char(10)	NULL,
       Item		char(16)	NULL,
       OrigContractAmt	decimal(16,2)	NULL,
       OrigContractUnits	decimal(12,3)	NULL,
       OrigUnitPrice	decimal(16,5)	NULL,
       CurrContractAmt	decimal(16,2)	NULL,
       CurrContractUnits	decimal(12,3)	NULL,
       CurrUnitPrice	decimal(16,5)	NULL,
       BilledAmt		decimal(16,2)	NULL,
       BilledUnits		decimal(12,3)	NULL,
       ReceivedAmt		decimal(16,2)	NULL,
       Job			char(10)	NULL,
       PhaseGroup		tinyint		NULL,
       Phase		char(20) 	NULL,
       CostType		tinyint 	NULL,
       CTAbbrev		char(10)  	NULL,
       OrigEstHours	decimal(10,2)	NULL,
       OrigEstUnits	decimal(12,3)	NULL,
       OrigEstItemUnits	decimal(12,3)	NULL,
       OrigEstPhaseUnits	decimal(12,3) 	NULL,
       OrigEstCost		decimal(16,2)	NULL,
       CurrEstHours	decimal(10,2)	NULL,
       CurrEstUnits	decimal(12,3)	NULL,
       CurrEstItemUnits	decimal(12,3)	NULL,
       CurrEstPhaseUnits	decimal(12,3)	NULL,
       CurrEstCost		decimal(16,2)	NULL,
       ActualHours		decimal(10,2)	NULL,
       ActualUnits		decimal(12,3)	NULL,
       ActualItemUnits	decimal(12,3)	NULL,
       ActualPhaseUnits	decimal(12,3)	NULL,
       ActualCost		decimal(16,2)	NULL,
       Mth			smalldatetime	Null,
       CostTrans		integer		Null,
       PostedDate		smalldatetime	Null,
       ActualDate		smalldatetime	Null,
       TransType		varchar(2)	Null,
       Source		varchar(10)	Null,
       DetailDesc		varchar(60)	Null,
       ProjHours		decimal(10,2)	NULL,
       ProjUnits		decimal(12,3)	NULL,
       ProjItemUnits	decimal(12,3)	NULL,
       ProjPhaseUnits	decimal(12,3)	NULL,
       ProjCost		decimal(16,2)	NULL,
       PerActualHours	decimal(10,2)	NULL,
       PerActualUnits	decimal(12,3)	NULL,
       PerActualItemUnits	decimal(12,3)	NULL,
       PerActualPhaseUnits	decimal(12,3)	NULL,
       PerActualCost	decimal(16,2)	NULL
   
   )
   
   /* insert Contract info */
   insert into #JCUnitCost
   (JCCo, Contract, Item, OrigContractAmt, OrigContractUnits, OrigUnitPrice,
      CurrContractAmt, CurrContractUnits, CurrUnitPrice,BilledAmt, BilledUnits,ReceivedAmt,Mth,PostedDate,ActualDate)
   
   /*declare @JCCo bCompany, @BeginContract bContract, @EndContract bContract,
   @BeginDate bDate, @EndDate bDate
   
   select @JCCo=1, @BeginContract='', @EndContract= 'zzzzzzzzz',
   @BeginDate= '01/01/51', @EndDate='01/01/20'*/
   
   Select JCCI.JCCo, JCCI.Contract, JCCI.Item,
   	JCCI.OrigContractAmt, JCCI.OrigContractUnits, JCCI.OrigUnitPrice,
   	sum(JCID.ContractAmt),
   	sum(JCID.ContractUnits),
   	sum(JCID.UnitPrice),
           	case when (JCID.ActualDate >=@BeginDate) then  sum(JCID.BilledAmt) else 0 end,
   	case when (JCID.ActualDate >=@BeginDate) then sum(JCID.BilledUnits) else 0 end,
   	case when (JCID.ActualDate >=@BeginDate) then sum(JCID.ReceivedAmt) else 0 end,
   JCID.Mth,JCID.PostedDate,JCID.ActualDate
   FROM  JCCI with(nolock)
   /*,JCID
   Where JCCI.JCCo*=JCID.JCCo and JCCI.Contract*=JCID.Contract and JCCI.Item*=JCID.Item
   and JCCI.JCCo=@JCCo and JCCI.Contract>=@BeginContract and JCCI.Contract<=@EndContract*/
   
   Left Join JCID with(nolock)
   	on JCID.JCCo=JCCI.JCCo and JCID.Contract=JCCI.Contract and JCID.Item=JCCI.Item
            and JCID.ActualDate<=@EndDate and JCID.Mth<=@ThruMth
   where JCCI.JCCo=@JCCo and JCCI.Contract>=@BeginContract and JCCI.Contract<=@EndContract
   
   /*Order By JCCI.JCCo, JCCI.Contract, JCCI.Item*/
   group by
      JCCI.JCCo, JCCI.Contract, JCCI.Item,JCCI.OrigContractAmt, JCCI.OrigContractUnits,
      JCCI.OrigUnitPrice,JCID.Mth,JCID.PostedDate,JCID.ActualDate
   
   /* insert jtd Cost info */
   insert into #JCUnitCost
   (JCCo, Contract, Item, Job, PhaseGroup, Phase, CostType, CTAbbrev,
   OrigEstHours, OrigEstUnits, OrigEstItemUnits, OrigEstPhaseUnits, OrigEstCost,
   CurrEstHours, CurrEstUnits, CurrEstItemUnits, CurrEstPhaseUnits, CurrEstCost,
   ActualHours,  ActualUnits,  ActualItemUnits,  ActualPhaseUnits,  ActualCost,
   Mth ,CostTrans,PostedDate,ActualDate,TransType,Source,DetailDesc,
   PerActualHours,PerActualUnits,PerActualItemUnits, PerActualPhaseUnits, PerActualCost,
   ProjHours, ProjUnits, ProjItemUnits, ProjPhaseUnits, ProjCost)
   
   Select JCJP.JCCo, JCJP.Contract, JCJP.Item, JCJP.Job, JCJP.PhaseGroup, JCJP.Phase, JCCD.CostType, JCCT.Abbreviation,
   
   case when (JCCD.JCTransType='OE') then JCCD.EstHours else 0 end,
   case when (JCCH.UM=JCCD.UM  and JCCD.JCTransType='OE') then JCCD.EstUnits else 0 end,
   case when (JCCH.UM=JCCD.UM and JCCH.ItemUnitFlag='Y' and JCCD.JCTransType = 'OE')
   then JCCD.EstUnits else 0 end,
   case when (JCCH.UM=JCCD.UM and JCCH.PhaseUnitFlag='Y' and JCCD.JCTransType = 'OE')
   then JCCD.EstUnits else 0 end,
   case when (JCCD.JCTransType='OE') then JCCD.EstCost else 0 end,
   JCCD.EstHours, 
   case when (JCCH.UM=JCCD.UM) then JCCD.EstUnits else 0 end,
   case when(JCCH.UM=JCCD.UM and JCCH.ItemUnitFlag='Y') then JCCD.EstUnits else 0 end,
   case when(JCCH.UM=JCCD.UM and JCCH.PhaseUnitFlag='Y') then JCCD.EstUnits else 0 end,
   JCCD.EstCost, JCCD.ActualHours, 
   case when (JCCH.UM=JCCD.UM) then JCCD.ActualUnits else 0 end,
   case when(JCCH.UM=JCCD.UM and JCCH.ItemUnitFlag='Y') then JCCD.ActualUnits else 0 end,
   case when(JCCH.UM=JCCD.UM and JCCH.PhaseUnitFlag='Y') then JCCD.ActualUnits else 0 end,
   JCCD.ActualCost, JCCD.Mth, JCCD.CostTrans, JCCD.PostedDate, JCCD.ActualDate, JCCD.JCTransType,
   JCCD.Source, JCCD.Description,
   case when (JCCD.ActualDate>=@BeginDate) then JCCD.ActualHours else 0 end,
   case when (JCCH.UM=JCCD.UM and JCCD.ActualDate>=@BeginDate) then JCCD.ActualUnits else 0 end,
   case when (JCCH.UM=JCCD.UM and JCCH.ItemUnitFlag='Y' and JCCD.ActualDate>=@BeginDate) then JCCD.ActualUnits else 0 end,
   case when (JCCH.UM=JCCD.UM and JCCH.PhaseUnitFlag='Y' and JCCD.ActualDate>=@BeginDate) then JCCD.ActualUnits else 0 end,
   case when (JCCD.ActualDate>=@BeginDate) then JCCD.ActualCost else 0 end,
   JCCD.ProjHours,
   case when (JCCH.UM=JCCD.UM) then JCCD.ProjUnits else 0 end,
   case when (JCCH.UM=JCCD.UM and JCCH.ItemUnitFlag='Y')  then JCCD.ProjUnits else 0 end,
   case when (JCCH.UM=JCCD.UM and JCCH.PhaseUnitFlag='Y')  then JCCD.ProjUnits else 0 end,
   JCCD.ProjCost 
   FROM JCJP with(nolock)
   /*,JCCD,JCCH,JCCT
   where JCCD.JCCo=JCJP.JCCo and JCCD.Job=JCJP.Job and JCCD.Phase=JCJP.Phase and
   JCCD.PhaseGroup=JCJP.PhaseGroup and JCCD.ActualDate<=@EndDate
   and JCCH.JCCo=JCCD.JCCo and JCCH.Job=JCCD.Job and JCCH.Phase=JCCD.Phase
   and JCCH.PhaseGroup=JCCD.PhaseGroup and JCCH.CostType=JCCD.CostType and
   JCCT.PhaseGroup=JCCH.PhaseGroup and JCCT.CostType=JCCH.CostType
   and JCJP.JCCo=@JCCo and JCJP.Contract>=@BeginContract and JCJP.Contract<=@EndContract*/
   
     Join JCCD with(nolock) on JCCD.JCCo=JCJP.JCCo and JCCD.Job=JCJP.Job and JCCD.Phase=JCJP.Phase and JCCD.PhaseGroup=JCJP.PhaseGroup
         and (case when @DateActPost = 'P'then JCCD.PostedDate  else JCCD.ActualDate end )<=@EndDate  and JCCD.Mth<=@ThruMth
     Join JCCH with(nolock) on JCCH.JCCo=JCCD.JCCo and JCCH.Job=JCCD.Job and JCCH.Phase=JCCD.Phase and JCCH.PhaseGroup=JCCD.PhaseGroup
         and JCCH.CostType=JCCD.CostType
     Join JCCT with(nolock) on JCCH.CostType=JCCT.CostType and JCCT.PhaseGroup=JCCH.PhaseGroup
      Join JCJM with (NOLOCK) on JCCD.JCCo=JCJM.JCCo and JCCD.Job=JCJM.Job
      where JCJP.JCCo=@JCCo and JCJP.Contract>=@BeginContract and JCJP.Contract<=@EndContract
   
    /*  group by JCJP.JCCo, JCJP.Contract, JCJP.Item, JCJP.Job, JCJP.Phase, JCJP.PhaseGroup, JCCD.CostType, JCCT.Abbreviation,
      JCCH.ItemUnitFlag,JCCH.PhaseUnitFlag, JCCD.JCTransType ,JCCD.UM, JCCH.UM*/
   
   /* select the results */
   
   select JCCI.JCCo, JCCI.Contract, ContDesc=JCCM.Description,
      JCCI.Item, ItemDesc=JCCI.Description,a.Job,
   JobDesc=JCJM.Description,JobStatus=JCJM.JobStatus,
      a.PhaseGroup, a.Phase, PhaseDesc=JCJP.Description,CostType=a.CostType, CTAbbrev=a.CTAbbrev,
   PhaseUM=(select min(UM) from JCCH with(nolock)
   where JCCH.JCCo=a.JCCo and JCCH.Job=a.Job and JCCH.Phase=a.Phase and JCCH.PhaseGroup=a.PhaseGroup
   and JCCH.PhaseUnitFlag='Y'),
   ItemUM=(select Min(UM) from JCCH with(nolock)
   where JCCH.JCCo=a.JCCo and JCCH.Job=a.Job and JCCH.Phase=a.Phase and JCCH.PhaseGroup=a.PhaseGroup
   and JCCH.ItemUnitFlag='Y'),JCCHUM=JCCH.UM,
     JCCIUM=JCCI.UM, BilledUnits=a.BilledUnits, BilledAmt=a.BilledAmt,ReceivedAmt=a.ReceivedAmt,
      OrigContractUnits=a.OrigContractUnits,
      OrigContractAmt=a.OrigContractAmt,
      OrigUnitPrice=a.OrigUnitPrice,
      CurrContractAmt=a.CurrContractAmt,
      CurrContractUnits=a.CurrContractUnits,
      CurrUnitPrice=a.CurrUnitPrice,
   
      OrigEstHours=a.OrigEstHours,
      OrigEstUnits=a.OrigEstUnits,
   
      OrigEstItemUnits=a.OrigEstItemUnits,
      OrigEstPhaseUnits=a.OrigEstPhaseUnits,
      OrigEstCost=a.OrigEstCost,
   
      CurrEstHours=a.CurrEstHours,
      CurrEstUnits=a.CurrEstUnits,
      CurrEstItemUnits=a.CurrEstItemUnits,
      CurrEstPhaseUnits=a.CurrEstPhaseUnits,
      CurrEstCost=a.CurrEstCost,
   
   
      ActualHours=a.ActualHours,
      ActualUnits=a.ActualUnits,
      ActualItemUnits=a.ActualItemUnits,
      ActualPhaseUnits=a.ActualPhaseUnits,
      ActualCost=a.ActualCost,
   
      Mth=a.Mth, a.CostTrans, a.PostedDate, a.ActualDate, a.TransType,
      a.Source, a.DetailDesc,
   
      ProjHours=a.ProjHours,
      ProjUnits=a.ProjUnits,
      ProjItemUnits=a.ProjItemUnits,
      ProjPhaseUnits=a.ProjPhaseUnits,
      ProjCost=a.ProjCost,
   
      PerActualHours=a.PerActualHours,
      PerActualUnits=a.PerActualUnits,
      PerActualItemUnits=a.PerActualItemUnits,
      PerActualPhaseUnits=a.PerActualPhaseUnits,
      PerActualCost=a.PerActualCost,
   
     CoName=HQCO.Name,
   
     BeginDate=@BeginDate,
     EndDate=@EndDate,
     BeginContract=@BeginContract,
     EndContract=@EndContract,
     ThroughMonth=@ThruMth,
     DateActPost = @DateActPost
   
   
      from #JCUnitCost a
   /*a,JCCI,JCJM,JCCM,HQCO,JCJP,JCCH
      where JCCI.JCCo=a.JCCo and JCCI.Contract=a.Contract and
            JCCI.Item=a.Item and a.JCCo*=JCJM.JCCo and a.Job*=JCJM.Job
            and JCCM.JCCo=JCCI.JCCo and JCCM.Contract=JCCI.Contract
            and HQCO.HQCo=JCCI.JCCo
            and a.JCCo*=JCJP.JCCo and a.Job*=JCJP.Job and a.Phase*=JCJP.Phase
            and a.PhaseGroup*=JCJP.PhaseGroup
            and a.JCCo*=JCCH.JCCo and a.Job*=JCCH.Job and a.Phase*=JCCH.Phase and
            a.PhaseGroup*=JCCH.PhaseGroup
            and a.CostType*=JCCH.CostType*/
   
   
   
   JOIN JCCI with(nolock) on JCCI.JCCo=a.JCCo and JCCI.Contract=a.Contract and JCCI.Item=a.Item
       Left Join JCJM with(nolock) on JCJM.JCCo=a.JCCo and JCJM.Job=a.Job
       Join JCCM with(nolock) on JCCM.JCCo=JCCI.JCCo and JCCM.Contract=JCCI.Contract
       Join HQCO with(nolock) on HQCO.HQCo=JCCI.JCCo
       Left Join JCJP with(nolock) on JCJP.JCCo=a.JCCo and JCJP.Job=a.Job and JCJP.Phase=a.Phase and JCJP.PhaseGroup=a.PhaseGroup
       Left Join JCCH with(nolock) on JCCH.JCCo=a.JCCo and JCCH.Job=a.Job and JCCH.Phase=a.Phase and JCCH.PhaseGroup=a.PhaseGroup
       and JCCH.CostType=a.CostType
   
   /* group by JCCI.JCCo, a.JCCo, JCCI.Contract, JCCM.Description,
      JCCI.Item, a.Job,JCJM.Description,JCJM.JobStatus, a.Phase, JCJP.Description,
     a.CostType,
        a.CTAbbrev, JCCI.Description,JCCI.UM, HQCO.Name,
      a.PhaseGroup,JCCH.UM */

GO
GRANT EXECUTE ON  [dbo].[brptJCUnitCostDrillDown] TO [public]
GO
