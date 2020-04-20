SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[brptJCEstCostItemPM]
      (@JCCo bCompany, @BeginContract bContract ='', @EndContract bContract= 'zzzzzzzzz',
      @BeginMonth bMonth= '01/01/51', @EndMonth bMonth)
   
      /*   declare @JCCo bCompany, @BeginContract bContract , @EndContract bContract,
      @BeginMonth bMonth, @EndMonth bMonth
   
      Select @JCCo=50, @BeginContract='', @EndContract= 'zzzzzzzzz',
      @BeginMonth= '01/01/51', @EndMonth='04/10/97' */
   
      /* This procedure is using the JCCH Item Unit flag to calculate which items units and amounts
      should be used to generate the amounts. Using the JCIP,JCCP,JCCH*/
   
    /* Last updated 10/28/99 - added ContractStatus for Open,Closed or All Job Parameters*/
    /* Mod 4/2/03 E.T. fixed to make ansii standard for Crystal 9.0 
                       fixed : using tables instead of views & non-ansii joins. Issue #20721 
       Mod 11/5/04 CR added NoLocks #25917
   
   */
   
      as
       create table #JCEstCostPayItem
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
   
          ActualHours     decimal(10,2)            NULL,
          ActualUnits     decimal(12,3)            NULL,
          ActualCost      decimal(16,2)            NULL,
   
          PerActualHours     decimal(10,2)            NULL,
          PerActualUnits     decimal(12,3)            NULL,
          PerActualCost      decimal(16,2)            NULL,
   
          OrigEstHours       decimal(10,2)             NULL,
          OrigEstUnits        decimal(12,3)            NULL,
          OrigEstCost         decimal(16,2)            NULL,
        --  OrigEstCostJCCH	decimal(16,2)		Null,
   
          CurrEstHours       decimal(10,2)             NULL,
          CurrEstUnits        decimal(12,3)            NULL,
          CurrEstCost         decimal(16,2)            NULL,
   
          ProjHours		decimal(16,2)		NULL,
          ProjUnits     decimal(12,3)            NULL,
          ProjCost      decimal(16,2)            NULL
      )
   
      /* insert Contract info */
      insert into #JCEstCostPayItem
      (JCCo, Contract, Item, OrigContractUnits, OrigContractAmt, OrigUnitPrice,
         CurrContractAmt, CurrContractUnits, CurrUnitPrice,BilledAmt, BilledUnits)
   
      Select JCCI.JCCo, JCCI.Contract, JCCI.Item,
      	JCCI.OrigContractUnits, JCCI.OrigContractAmt, JCCI.OrigUnitPrice,
      	sum(JCIP.ContractAmt),sum(JCIP.ContractUnits), sum(JCIP.CurrentUnitPrice),
              sum(JCIP.BilledAmt), sum(JCIP.BilledUnits)
      FROM JCCI --,JCIP
      Left join JCIP  on JCIP.JCCo=JCCI.JCCo and JCIP.Contract=JCCI.Contract and JCIP.Item=JCCI.Item
      Where JCIP.Mth<=@EndMonth and JCIP.JCCo=@JCCo and JCIP.Contract>=@BeginContract
              and JCIP.Contract<=@EndContract 
      /*JCCI
      Left Join JCID
      	on JCID.JCCo=JCCI.JCCo and JCID.Contract=JCCI.Contract and JCID.Item=JCCI.Item
              and JCID.PostedDate<=@EndDate and JCID.JCCo=@JCCo and JCID.Contract>=@BeginContract
              and JCID.Contract<=@EndContract
      where JCCI.JCCo=@JCCo and JCCI.Contract>=@BeginContract and JCCI.Contract<=@EndContract*/
   
      group by
         JCCI.JCCo, JCCI.Contract, JCCI.Item,
          JCCI.OrigContractUnits, JCCI.OrigContractAmt, JCCI.OrigUnitPrice
   
      /* insert jtd Cost info */
      insert into #JCEstCostPayItem
      (JCCo, Contract, Item, ActualHours, ActualUnits, ActualCost, CurrEstHours, CurrEstUnits,
      CurrEstCost,/*OrigEstCostJCCH,*/ OrigEstHours, OrigEstUnits, OrigEstCost,ProjHours,ProjUnits,ProjCost)
   
      Select JCJP.JCCo, JCJP.Contract, JCJP.Item,
      sum(JCCP.ActualHours),
   
      case JCCH.ItemUnitFlag when 'Y' then sum(JCCP.ActualUnits) else 0 end,
      sum(JCCP.ActualCost),
      sum(JCCP.CurrEstHours),
      case JCCH.ItemUnitFlag when 'Y' then sum(JCCP.CurrEstUnits) else 0 end,
      sum(JCCP.CurrEstCost),
      --0,
      sum(JCCP.OrigEstHours),
      case when JCCH.ItemUnitFlag = 'Y'  then sum(JCCP.OrigEstUnits) else 0 end,
      sum(JCCP.OrigEstCost),
      sum(JCCP.ProjHours),
      case JCCH.ItemUnitFlag when 'Y' then sum(JCCP.ProjUnits) else 0 end,
      sum(JCCP.ProjCost)
   
         FROM JCJP 
   join JCCH on JCCH.JCCo=JCJP.JCCo and JCCH.Job=JCJP.Job and JCCH.PhaseGroup=JCJP.PhaseGroup and JCCH.Phase=JCJP.Phase
   --join JCCH on JCCH.JCCo=JCJP.JCCo and JCCH.Job=JCJP.Job and JCCH.Phase=JCJP.Phase
   left join JCCP  on  JCCP.JCCo=JCCH.JCCo and JCCP.Job=JCCH.Job and JCCP.Phase=JCCH.Phase and JCCP.PhaseGroup=JCCH.PhaseGroup
    and JCCP.CostType=JCCH.CostType and JCCP.Mth<=@EndMonth
   
   
      where JCJP.JCCo=@JCCo and JCJP.Contract>=@BeginContract and JCJP.Contract<=@EndContract
    group by JCJP.JCCo, JCJP.Contract, JCJP.Item, JCCH.ItemUnitFlag
   
        /*Join JCCD on JCCD.JCCo=JCJP.JCCo and JCCD.Job=JCJP.Job and JCCD.Phase=JCJP.Phase
            and JCCD.PostedDate<=@EndDate
        Join JCCH on JCCH.JCCo=JCCD.JCCo and JCCH.Job=JCJP.Job and JCCH.Phase=JCJP.Phase
            and JCCH.CostType=JCCD.CostType
      where JCJP.JCCo=@JCCo and JCJP.Contract>=@BeginContract and JCJP.Contract<=@EndContract*/
       --  group by JCJP.JCCo, JCJP.Contract, JCJP.Item, JCCH.ItemUnitFlag
   
   
   
   create table #OriginalJCCHEst
         (JCCo            tinyint              NULL,
          Contract        char(10)            NULL,
          Item              char(16)       NULL,
           OrigEstCostJCCH	   decimal(16,2)               NULL)
   insert into #OriginalJCCHEst
   (JCCo, Contract, Item, OrigEstCostJCCH)
   select JCJP.JCCo, JCJP.Contract, JCJP.Item, sum(JCCH.OrigCost)
   FROM JCJP join JCCH  on JCCH.JCCo=JCJP.JCCo and JCCH.Job=JCJP.Job and JCCH.Phase=JCJP.Phase
   where JCJP.JCCo=@JCCo and JCJP.Contract>=@BeginContract and JCJP.Contract<=@EndContract
    group by JCJP.JCCo, JCJP.Contract, JCJP.Item
   
      /* insert ptd Cost info */
      insert into #JCEstCostPayItem
      (JCCo, Contract, Item,
        PerActualHours,PerActualUnits,PerActualCost)
   
      Select JCJP.JCCo, JCJP.Contract, JCJP.Item,sum(JCCP.ActualHours),
      case JCCH.ItemUnitFlag when 'Y' then sum(JCCP.ActualUnits) else 0 end,
      sum(JCCP.ActualCost)
   
      FROM JCJP --,JCCP,JCCH
      join JCCP on JCCP.JCCo=JCJP.JCCo and JCCP.Job=JCJP.Job and JCCP.PhaseGroup=JCJP.PhaseGroup and JCCP.Phase=JCJP.Phase
      join JCCH on JCCH.JCCo=JCCP.JCCo and JCCH.Job=JCCP.Job and JCCH.PhaseGroup=JCCP.PhaseGroup and JCCH.Phase=JCCP.Phase
            and JCCH.CostType=JCCP.CostType
     Where JCJP.JCCo=@JCCo and JCJP.Contract>=@BeginContract and JCJP.Contract<=@EndContract and JCCP.Mth>=@BeginMonth and JCCP.Mth<=@EndMonth
      /* Join JCCD on JCCD.JCCo=JCJP.JCCo and JCCD.Job=JCJP.Job and JCCD.Phase=JCJP.Phase
            and JCCD.PostedDate>=@BeginDate and JCCD.PostedDate<=@EndDate
        Join JCCH on JCCH.JCCo=JCCD.JCCo and JCCH.Job=JCJP.Job and JCCH.Phase=JCJP.Phase
            and JCCH.CostType=JCCD.CostType
      where JCJP.JCCo=@JCCo and JCJP.Contract>=@BeginContract and JCJP.Contract<=@EndContract*/
         group by JCJP.JCCo, JCJP.Contract, JCJP.Item, JCCH.ItemUnitFlag
   
      /* select the results */
      select JCCI.JCCo, COName=HQCO.Name,JCCI.Contract, ContDesc=JCCM.Description,
         JCCI.Item, ItemDesc=JCCI.Description,
        ItemUM=JCCI.UM, BilledUnits=sum(a.BilledUnits), BilledAmt=sum(a.BilledAmt),
         OrigContractUnits=sum(a.OrigContractUnits),
         OrigContractAmt=sum(a.OrigContractAmt),
         OrigUnitPrice=sum(a.OrigUnitPrice),
         CurrContractAmt=sum(a.CurrContractAmt),
         CurrContractUnits=sum(a.CurrContractUnits),
         CurrUnitPrice=sum(a.CurrUnitPrice),
   
         ActualHours=sum(a.ActualHours),
         ActualUnits=sum(a.ActualUnits),
         ActualCost=sum(a.ActualCost),
   
         PerActualHours=sum(PerActualHours),
         PerActualUnits=sum(PerActualUnits),
         PerActualCost=sum(PerActualCost),
   
         OrigEstHours=sum(OrigEstHours),
         OrigEstUnits=sum(OrigEstUnits),
         OrigEstCost=sum(OrigEstCost),
         OrigEstCostJCCH=avg(#OriginalJCCHEst.OrigEstCostJCCH),
         CurrEstHours=sum(CurrEstHours),
         CurrEstUnits=sum(CurrEstUnits),
         CurrEstCost=sum(CurrEstCost),
   
         ProjHours=sum(ProjHours),
         ProjUnits=sum(ProjUnits),
         ProjCost=sum(ProjCost),
        CoName=HQCO.Name,
        BeginMonth=@BeginMonth,
        EndMonth=@EndMonth,
        BeginContract=@BeginContract,
        EndContract=@EndContract,
        ContractStatus=JCCM.ContractStatus
   
   
         from #JCEstCostPayItem a
          LEFT Outer JOIN JCCI on JCCI.JCCo=a.JCCo and JCCI.Contract=a.Contract and
               JCCI.Item=a.Item
          LEFT Outer Join JCCM  on JCCM.JCCo=JCCI.JCCo and JCCM.Contract=JCCI.Contract
          LEFT Outer Join HQCO  on HQCO.HQCo=JCCI.JCCo
          LEFT Outer Join #OriginalJCCHEst on
   		a.JCCo=#OriginalJCCHEst.JCCo and a.Contract=#OriginalJCCHEst.Contract and a.Item=#OriginalJCCHEst.Item
   
      group by JCCI.JCCo, JCCI.Contract, JCCM.Description,
         JCCI.Item, JCCI.Description,JCCI.UM, HQCO.Name,JCCM.ContractStatus

GO
GRANT EXECUTE ON  [dbo].[brptJCEstCostItemPM] TO [public]
GO
