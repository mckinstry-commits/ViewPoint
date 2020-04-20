SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE          proc [dbo].[brptJCEstCostItem]
      (@JCCo bCompany, @BeginContract bContract ='', @EndContract bContract= 'zzzzzzzzz',
       @EndMonth bMonth)
    
      /*   declare @JCCo bCompany, @BeginContract bContract , @EndContract bContract,
      @BeginMonth bMonth, @EndMonth bMonth
    
      Select @JCCo=50, @BeginContract='', @EndContract= 'zzzzzzzzz',
      @BeginMonth= '01/01/51', @EndMonth='04/10/97' */
    
      /* This procedure is using the JCCH Item Unit flag to calculate which items units and amounts
      should be used to generate the amounts. Using the JCIP,JCCP,JCCH*/
    
     /* Last updated 10/28/99 - added ContractStatus for Open,Closed or All Job Parameters*/
     
     /*Last updated 11/9/01 - added JCCM.Department,JCCM.StartMonth,JCCM.MonthClosed*/
     /* Mod 4/2/03 E.T. fixed to make ansii standard for Crystal 9.0 
                        fixed : non-ansii joins. Issue #20721 
   
        Mod 11/5/04 CR Added NoLocks #25916 
        Mod 3/31/05 CR Added JCIP.ProjDollars, JCIP.ProjUnits  #27209
        Mod 6/29/05 CR Added ProjMth field #29159
        Mod 3/23/06 CR removed @BegMonth parameter #120376
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
          CurrEstHours       decimal(10,2)             NULL,
          CurrEstUnits        decimal(12,3)            NULL,
          CurrEstCost         decimal(16,2)            NULL,
    
          ProjHours		decimal(16,2)		NULL,
          ProjUnits     decimal(12,3)            NULL,
          ProjCost      decimal(16,2)            NULL,
   
          ProjRevUnits   decimal(12,3)   Null,
          ProjDollars  decimal(16,2)  Null,
          ProjMth     smalldatetime Null
      )
   
     create clustered index biJCEst on #JCEstCostPayItem(JCCo, Contract, Item)
    
      /* insert Contract info */
      insert into #JCEstCostPayItem
      (JCCo, Contract, Item, OrigContractUnits, OrigContractAmt, OrigUnitPrice,
         CurrContractAmt, CurrContractUnits, CurrUnitPrice,BilledAmt, BilledUnits, ProjRevUnits,ProjDollars,
        ProjMth)
    
      Select JCCI.JCCo, JCCI.Contract, JCCI.Item,
      	JCCI.OrigContractUnits, JCCI.OrigContractAmt, JCCI.OrigUnitPrice,
      	sum(JCIP.ContractAmt),sum(JCIP.ContractUnits), sum(JCIP.CurrentUnitPrice),
              sum(JCIP.BilledAmt), sum(JCIP.BilledUnits), sum(JCIP.ProjUnits), sum(JCIP.ProjDollars),
           ProjMth=(select isnull(min(i.Mth),'12/1/2050') from JCIP i with (nolock)
              where JCIP.JCCo=i.JCCo and JCIP.Contract=i.Contract and JCIP.Item=i.Item and (i.ProjDollars <>0 or i.ProjPlug='Y'))
        
      FROM JCCI with (NOLOCK)
      Left Join JCIP with (NOLOCK) on JCIP.JCCo=JCCI.JCCo and JCIP.Contract=JCCI.Contract and JCIP.Item=JCCI.Item
      Where JCCI.JCCo=@JCCo and JCCI.Contract>=@BeginContract and JCCI.Contract<=@EndContract and JCIP.Mth<=@EndMonth
      /*JCCI
      Left Join JCID
      	on JCID.JCCo=JCCI.JCCo and JCID.Contract=JCCI.Contract and JCID.Item=JCCI.Item
              and JCID.PostedDate<=@EndDate and JCID.JCCo=@JCCo and JCID.Contract>=@BeginContract
              and JCID.Contract<=@EndContract
      where JCCI.JCCo=@JCCo and JCCI.Contract>=@BeginContract and JCCI.Contract<=@EndContract*/
    
      group by
         JCCI.JCCo, JCCI.Contract, JCCI.Item,
          JCCI.OrigContractUnits, JCCI.OrigContractAmt, JCCI.OrigUnitPrice,JCIP.JCCo, JCIP.Contract, JCIP.Item
   
      /* insert jtd Cost info */
      insert into #JCEstCostPayItem
      (JCCo, Contract, Item, ActualHours, ActualUnits, ActualCost, CurrEstHours, CurrEstUnits, CurrEstCost,
      OrigEstHours, OrigEstUnits, OrigEstCost,ProjHours,ProjUnits,ProjCost)
    
      Select JCJP.JCCo, JCJP.Contract, JCJP.Item,
      sum(JCCP.ActualHours),
      case JCCH.ItemUnitFlag when 'Y' then sum(JCCP.ActualUnits) else 0 end,
      sum(JCCP.ActualCost),
      sum(JCCP.CurrEstHours),
      case JCCH.ItemUnitFlag when 'Y' then sum(JCCP.CurrEstUnits) else 0 end,
      sum(JCCP.CurrEstCost),
      sum(JCCP.OrigEstHours),
      case when JCCH.ItemUnitFlag = 'Y'  then sum(JCCP.OrigEstUnits) else 0 end,
      sum(JCCP.OrigEstCost),
      sum(JCCP.ProjHours),
      case JCCH.ItemUnitFlag when 'Y' then sum(JCCP.ProjUnits) else 0 end,
      sum(JCCP.ProjCost)
    
      FROM JCJP with (NOLOCK) --,JCCP,JCCH
      join JCCP with (NOLOCK) on JCCP.JCCo=JCJP.JCCo and JCCP.Job=JCJP.Job and JCCP.PhaseGroup=JCJP.PhaseGroup and  JCCP.Phase=JCJP.Phase
      join JCCH with (NOLOCK) on JCCH.JCCo=JCCP.JCCo and JCCH.Job=JCJP.Job and JCCH.PhaseGroup=JCJP.PhaseGroup and JCCH.Phase=JCJP.Phase
             and JCCH.CostType=JCCP.CostType
      Where JCJP.JCCo=@JCCo and JCJP.Contract>=@BeginContract and JCJP.Contract<=@EndContract and JCCP.Mth<=@EndMonth
    
        /*Join JCCD on JCCD.JCCo=JCJP.JCCo and JCCD.Job=JCJP.Job and JCCD.Phase=JCJP.Phase
            and JCCD.PostedDate<=@EndDate
        Join JCCH on JCCH.JCCo=JCCD.JCCo and JCCH.Job=JCJP.Job and JCCH.Phase=JCJP.Phase
            and JCCH.CostType=JCCD.CostType
      where JCJP.JCCo=@JCCo and JCJP.Contract>=@BeginContract and JCJP.Contract<=@EndContract*/
         group by JCJP.JCCo, JCJP.Contract, JCJP.Item, JCCH.ItemUnitFlag
    
      /* insert ptd Cost info */
      insert into #JCEstCostPayItem
      (JCCo, Contract, Item,
        PerActualHours,PerActualUnits,PerActualCost)
    
      Select JCJP.JCCo, JCJP.Contract, JCJP.Item,sum(JCCP.ActualHours),
      case JCCH.ItemUnitFlag when 'Y' then sum(JCCP.ActualUnits) else 0 end,
      sum(JCCP.ActualCost)
    
      FROM JCJP with (NOLOCK)
      join JCCP with (NOLOCK) on JCCP.JCCo=JCJP.JCCo and JCCP.Job=JCJP.Job and JCCP.PhaseGroup=JCJP.PhaseGroup and JCCP.Phase=JCJP.Phase
      join JCCH with (NOLOCK) on JCCH.JCCo=JCCP.JCCo and JCCH.Job=JCCP.Job and JCCH.PhaseGroup=JCCP.PhaseGroup and JCCH.Phase=JCCP.Phase
            and JCCH.CostType=JCCP.CostType
      Where JCJP.JCCo=@JCCo and JCJP.Contract>=@BeginContract and JCJP.Contract<=@EndContract and JCCP.Mth<=@EndMonth
      /* Join JCCD on JCCD.JCCo=JCJP.JCCo and JCCD.Job=JCJP.Job and JCCD.Phase=JCJP.Phase
            and JCCD.PostedDate>=@BeginDate and JCCD.PostedDate<=@EndDate
        Join JCCH on JCCH.JCCo=JCCD.JCCo and JCCH.Job=JCJP.Job and JCCH.Phase=JCJP.Phase
            and JCCH.CostType=JCCD.CostType
      where JCJP.JCCo=@JCCo and JCJP.Contract>=@BeginContract and JCJP.Contract<=@EndContract*/
         group by JCJP.JCCo, JCJP.Contract, JCJP.Item, JCCH.ItemUnitFlag
    
      /* select the results */
      select a.JCCo, COName=HQCO.Name,a.Contract, ContDesc=JCCM.Description,
         a.Item, ItemDesc=JCCI.Description,
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
   
         CurrEstHours=sum(CurrEstHours),
         CurrEstUnits=sum(CurrEstUnits),
         CurrEstCost=sum(CurrEstCost),
   
    
         ProjHours=sum(ProjHours),
         ProjUnits=sum(ProjUnits),
         ProjCost=sum(ProjCost),
   
         ProjRevUnits=sum(a.ProjRevUnits),
         ProjDollars=sum(a.ProjDollars),
         ProjMth,
   
   
         UseProjectedEstimated = case when (select sum(ProjCost) from #JCEstCostPayItem c 
                        where c.JCCo=a.JCCo and c.Contract=a.Contract)<>0 then 'P' Else 'E' end,
   
        CoName=HQCO.Name,
        EndMonth=@EndMonth,
        BeginContract=@BeginContract,
        EndContract=@EndContract,
        ContractStatus=JCCM.ContractStatus,
        Department=JCCM.Department,
        StartMonth=JCCM.StartMonth,
        MonthClosed=JCCM.MonthClosed
    
    
         from #JCEstCostPayItem a
         JOIN JCCI with (NOLOCK) on JCCI.JCCo=a.JCCo and JCCI.Contract=a.Contract and
               JCCI.Item=a.Item
          Join JCCM with (NOLOCK) on JCCM.JCCo=JCCI.JCCo and JCCM.Contract=JCCI.Contract
          Join HQCO with (NOLOCK) on HQCO.HQCo=JCCI.JCCo
      group by a.JCCo, a.Contract, a.Item, a.ProjMth,JCCM.Description,
         JCCI.Description,JCCI.UM, HQCO.Name,JCCM.ContractStatus,JCCM.Department,JCCM.StartMonth,JCCM.MonthClosed

GO
GRANT EXECUTE ON  [dbo].[brptJCEstCostItem] TO [public]
GO
