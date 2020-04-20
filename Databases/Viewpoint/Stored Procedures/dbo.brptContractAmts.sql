SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.brptContractAmts    Script Date: 8/28/99 9:33:48 AM ******/
   --drop proc dbo.brptContractAmts 
   CREATE proc [dbo].[brptContractAmts]
      (@JCCo bCompany, @BeginContract bContract ='', @EndContract bContract= 'zzzzzzzzz',@ThroughMth bDate,
      @EndDate bDate)
      /* created 5/5/97 Not updated for security*/
      /* fixed 12/21/99 for incorrect join on JCJM - when multiple jobs per contract exist*/
      /* Mod 4/2/03 E.T. fixed to make ansii standard for Crystal 9.0 
                         fixed : using tables instead of views. Issue #20721 */
      as
      create table #ContractStatus
          (JCCo            tinyint              NULL,
          Contract        char(10)            NULL,
          Item		varchar(16)	NULL,
          ItemDesc		varchar(60)	NULL,
          Job             char(10)                 NULL,
          PhaseGroup        tinyint                  NULL,
    
          Phase		varchar(20)		NULL,
    
          CostType		tinyint                  NULL,
          CTAbbrev        char(5)                  NULL,
          Customer		int		NULL,
          CustName		varchar(60)	NULL,
          ProjCloseDate	smalldatetime	NULL,
          ContractDays		smallint	NULL,
          OrigContractAmt   decimal(12,2)               NULL,
          CurrContractAmt   decimal(12,2)              NULL,
          BilledAmt           decimal(12,2)              NULL,
          ReceivedAmt		decimal(12,2)		NULL,
          OrigEstCost         decimal(12,2)            NULL,
          CurrEstCost         decimal(12,2)            NULL,
          ActualCost      decimal(12,2)            NULL,
          ProjCost		decimal(12,2)            NULL,
          ActualUnits		decimal(12,2)            NULL,
      /* PaidToDate		decimal (12,2)		NULL*/
    
          )
     -- create table #OEFactor
    
     -- (TransType char(2) null, OEFactor tinyint null)
     -- insert into #OEFactor values('OE',1)
    
      /* insert Contract info */
      insert into #ContractStatus
      (JCCo, Contract, Item, ItemDesc, OrigContractAmt, CurrContractAmt,
      	BilledAmt,  ReceivedAmt)
      Select JCCI.JCCo, JCCI.Contract, JCCI.Item, JCCI.Description,
      	case when JCID.JCTransType = 'OC' then sum(JCID.ContractAmt) else 0 end,
      	sum(JCID.ContractAmt), sum(JCID.BilledAmt), sum(JCID.ReceivedAmt)
      FROM JCCI JCCI
    --  Left Join JCJP
    --  	on JCCI.JCCo=JCJP.JCCo and JCCI.Contract=JCJP.Contract and JCCI.Item=JCJP.Item
      Left Join JCID
      	on JCID.JCCo=JCCI.JCCo and JCID.Contract=JCCI.Contract and JCID.Item=JCCI.Item
              and JCID.PostedDate<=@EndDate and JCID.Mth<=@ThroughMth
      where JCCI.JCCo=@JCCo and JCCI.Contract>=@BeginContract and JCCI.Contract<=@EndContract
    
      group by
         JCCI.JCCo, JCCI.Contract, JCCI.Item,JCCI.Description, JCID.JCTransType
    
    
      /* insert jtd Cost info */
      insert into #ContractStatus
      (JCCo, Contract, Item, ItemDesc, Job, PhaseGroup, Phase, CostType, CTAbbrev,
       OrigEstCost, CurrEstCost, ActualCost, ProjCost, ActualUnits)
    
      Select JCJP.JCCo, JCJP.Contract, JCJP.Item, JCCI.Description, JCJP.Job, JCJP.PhaseGroup, JCJP.Phase,
       JCCD.CostType, JCCT.Abbreviation,
    
    --  sum(JCCD.EstCost * #OEFactor.OEFactor),
    sum(case when  JCCD.JCTransType='OE' then JCCD.EstCost else 0 end),
    
      sum(JCCD.EstCost),sum(JCCD.ActualCost),sum(JCCD.ProjCost),
      case when JCCD.UM=JCCH.UM then sum(JCCD.ActualUnits) else 0 end
      FROM JCJP
        Left Join JCCH on JCCH.JCCo=JCJP.JCCo and JCCH.Job=JCJP.Job and JCCH.PhaseGroup=JCJP.PhaseGroup
        and JCCH.Phase=JCJP.Phase
        Left Join JCCI on JCCI.JCCo=JCJP.JCCo and JCCI.Contract=JCJP.Contract and JCCI.Item=JCJP.Item
        Left Join JCCD on JCCH.JCCo=JCCD.JCCo and JCCH.Job=JCCD.Job and JCCH.PhaseGroup=JCCD.PhaseGroup
        and JCCH.Phase=JCCD.Phase and JCCH.CostType=JCCD.CostType and JCCD.PostedDate<=@EndDate and JCCD.Mth<=@ThroughMth
    
 
        Left Join JCCT on JCCD.CostType=JCCT.CostType and JCCT.PhaseGroup=JCCD.PhaseGroup
        -- Left Join #OEFactor on #OEFactor.TransType=JCCD.JCTransType
      where JCJP.JCCo=@JCCo and JCJP.Contract>=@BeginContract and JCJP.Contract<=@EndContract
         group by JCJP.JCCo, JCJP.Contract, JCJP.Item, JCCI.Description, JCJP.Job, JCJP.PhaseGroup, JCJP.Phase, JCCD.CostType,
          JCCT.Abbreviation, JCCH.UM, JCCD.UM
    
    
    
      /*insert Paid To Date Information*/
      /*insert into #ContractStatus
      (PaidToDate)
    
      select sum(APVM.PaidAmt)
      FROM APVM
      	Join APVM on APVM.VendorGroup=JCCD.VendorGroup and APVM.Vendor=JCCD.Vendor*/
    
    
      /* select the results */
    
    
      select JCCM.JCCo, JCCM.Contract, ContDesc=JCCM.Description, Item=a.Item,
      ItemDesc=a.ItemDesc,
       a.Job, ProjectMgr=JCMP.Name,
          a.PhaseGroup, a.Phase,
          CostType=a.CostType,
          CTAbbrev=a.CTAbbrev,
          Customer=JCCM.Customer,
    
          CustName=ARCM.Name,
          ProjCloseDate=JCCM.ProjCloseDate,
          ContractDays=JCCM.CurrentDays,
          OrigContractAmt=(a.OrigContractAmt),
          CurrContractAmt=(a.CurrContractAmt),
          BilledAmt=(a.BilledAmt),
          ReceivedAmt=(a.ReceivedAmt),
          OrigEstCost=(a.OrigEstCost),
          CurrEstCost=(a.CurrEstCost),
          ActualCost=(a.ActualCost),
          ProjCost=(a.ProjCost),
         /* PaidToDate=sum(a.PaidToDate),*/
    
    
        CoName=HQCO.Name,
        BeginContract=@BeginContract,
        EndContract=@EndContract,
        EndDate=@EndDate,
        ThroughMth=@ThroughMth,
         JCCM.Notes
    
    
         from #ContractStatus a
          JOIN JCCM on JCCM.JCCo=a.JCCo and JCCM.Contract=a.Contract
          Left Join ARCM on ARCM.CustGroup=JCCM.CustGroup and ARCM.Customer=JCCM.Customer
          Left Join JCJM on JCJM.JCCo=a.JCCo and JCJM.Job=a.Job
          Join HQCO on HQCO.HQCo=JCCM.JCCo
          Left Join JCMP on JCMP.JCCo=JCJM.JCCo and JCMP.ProjectMgr=JCJM.ProjectMgr
      /* Left Join JCCD on JCCD.JCCo=a.JCCo and JCCD.Job=a.Job and JCCD.PhaseGroup=a.PhaseGroup
          and JCCD.CostType=a.CostType
    
          Left Join APVM on APVM.VendorGroup=JCCD.VendorGroup and APVM.Vendor=JCCD.Vendor*/

GO
GRANT EXECUTE ON  [dbo].[brptContractAmts] TO [public]
GO
