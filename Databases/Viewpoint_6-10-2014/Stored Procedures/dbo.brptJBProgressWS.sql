SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--Drop proc brptJBProgressWS
     CREATE              proc [dbo].[brptJBProgressWS]
         (@JCCo bCompany, @BeginContract bContract ='', @EndContract bContract= 'zzzzzzzzz',
          @ThroughMonth bMonth)
       
         /*   declare @JCCo bCompany, @BeginContract bContract , @EndContract bContract,
          @ThroughMonth bMonth
       
         Select @JCCo=1, @BeginContract='', @EndContract= 'zzzzzzzzz',
          @EndMonth='04/10/97' */
       
         /* This procedure is using the JCCH Bill flag to determine which amounts
         should be used to generate current dollar and unit amounts
         10/25/02 Modified this stored procedure to pull CurContract amounts from JBIS
         and pull the this billing amount from JCIP.  E.T.*/
         /* Issue 25865 add with (nolock) DW 10/22/04
         Issue 24248 Added JCCI.BillType SH 3/4/05 */
       
         as
         create table #WorksheetAmounts
            (JCCo            tinyint              NULL,
             Contract        char(10)            NULL,
             Item              char(16)       NULL,
        --     ItemUM		char(3)		Null,
             CurContractAmt   decimal(16,2)               NULL,
             CurContractUnits decimal(15,3)                NULL,
       
             ChangeOrderAmt   decimal(16,2)              NULL,
             ChangeOrderUnits decimal(15,3)              NULL,
        --     COUnitPrice	decimal(20,5)		null,
       
     	OrigContractAmt		decimal(16,2)		Null,
     	OrigContractUnits	decimal(15,3)		Null,
             PrevBilledAmt           decimal(16,2)              NULL,
             PrevBilledUnits           decimal(15,3)              NULL,
             PrevSMAmt		decimal(16,2)		Null,
       
             CurrEstCost         decimal(16,2)            NULL,
             CurrEstUnits        decimal(15,3)            NULL,
             ProjCost         decimal(16,2)            NULL,
             ProjUnits        decimal(15,3)            NULL,
       
             ActualCost      decimal(16,2)            NULL,
             ActualUnits     decimal(15,3)            NULL,
             BillGroup	   varchar(20)	          NULL
       
         )
       
         /* insert Contract info */
         insert into #WorksheetAmounts
         (JCCo, Contract, Item, CurContractAmt, CurContractUnits)
       
         Select JCIP.JCCo, JCIP.Contract, JCIP.Item,
         	JCIP.ContractAmt,JCIP.ContractUnits
       
         FROM JCIP with(nolock)
         where   JCIP.JCCo=@JCCo and JCIP.Contract>=@BeginContract
                 and JCIP.Contract<=@EndContract and JCIP.Mth<=@ThroughMonth
       
         group by
            JCIP.JCCo, JCIP.Contract, JCIP.Item, JCIP.Mth, JCIP.ContractAmt, JCIP.ContractUnits
       
     /* insert Change Order details*/
       --insert into #WorksheetAmounts
       -- (JCCo, Contract, Item,  ChangeOrderAmt,ChangeOrderUnits,COUnitPrice,BillGroup)
       
       --Select JCOI.JCCo,JCOI.Contract, JCOI.Item,JCOI.ContractAmt,JCOI.ContractUnits,JCOI.ContUnitPrice,JCOI.BillGroup
       
       --From JCOH
       --Join JCOI on JCOH.JCCo = JCOI.JCCo and JCOH.Job = JCOI.Job and JCOH.ACO = JCOI.ACO
       --where JCOI.JCCo=@JCCo and JCOI.Contract>=@BeginContract
       --          and JCOI.Contract<=@EndContract and JCOH.ApprovalDate<=@COThroughDate
       
       --Group by JCOI.JCCo,JCOI.Contract, JCOI.Item,JCOI.ContractAmt,JCOI.ContractUnits,JCOI.ContUnitPrice,JCOI.BillGroup
     
     /* insert billed and Stored Materials Amounts*/
       insert into #WorksheetAmounts
       (JCCo, Contract, Item,ChangeOrderAmt,ChangeOrderUnits,PrevBilledAmt,PrevBilledUnits,PrevSMAmt,BillGroup)
       
       select JBIS.JBCo,JBIS.Contract,JBIS.Item,sum(JBIS.ChgOrderAmt),sum(JBIS.ChgOrderUnits),
     	sum(JBIS.AmtBilled),sum(JBIS.UnitsBilled),sum(JBIS.SM),JBIS.BillGroup
       From JBIS with(nolock)
       where JBIS.JBCo=@JCCo and JBIS.Contract>=@BeginContract
                 and JBIS.Contract<=@EndContract
       Group by JBIS.JBCo,JBIS.Contract,JBIS.Item,JBIS.BillGroup
     
     /* insert orignal contract amount from JCCI */
       insert into #WorksheetAmounts
       (JCCo, Contract, Item, OrigContractAmt, OrigContractUnits, BillGroup)
       Select JCCI.JCCo, JCCI.Contract, JCCI.Item, JCCI.OrigContractAmt, JCCI.OrigContractUnits, JCCI.BillGroup
       FROM JCCI with(nolock)
       Where JCCI.JCCo=@JCCo and JCCI.Contract>=@BeginContract and JCCI.Contract<=@EndContract
       Group by JCCI.JCCo, JCCI.Contract, JCCI.Item, JCCI.OrigContractAmt, JCCI.OrigContractUnits, JCCI.BillGroup
      
         /* insert Estimated and Actual Units and Amounts*/
       insert into #WorksheetAmounts
       (JCCo, Contract, Item,BillGroup,CurrEstCost,CurrEstUnits, ProjCost,ProjUnits,ActualCost,ActualUnits)
       Select JCJP.JCCo, JCJP.Contract, JCJP.Item,JCCI.BillGroup,
       case when JCCH.BillFlag in ('Y','C') then sum(JCCP.CurrEstCost) else 0 end,
       case JCCH.BillFlag when 'Y' then sum(JCCP.CurrEstUnits) else 0 end,
       case when JCCH.BillFlag  in ('Y','C') then sum(JCCP.ProjCost) else 0 end,
       case JCCH.BillFlag when 'Y' then sum(JCCP.ProjUnits) else 0 end,
       --case when JCCH.BillFlag  in ('Y','C') then sum(JCCP.ActualCost) else 0 end,
       sum(JCCP.ActualCost),
       case JCCH.BillFlag when 'Y' then sum(JCCP.ActualUnits) else 0 end
       
       from JCJP with(nolock)
           Join JCCP with(nolock) on JCCP.JCCo=JCJP.JCCo and JCCP.Job=JCJP.Job and JCCP.Phase=JCJP.Phase and JCCP.Mth<=@ThroughMonth
       --    Join JCIP on JCIP.JCCo=JCJP.JCCo and JCIP.Contract=JCJP.Contract and JCIP.Mth<=@ThroughMonth
           Join JCCH with(nolock) on JCCH.JCCo=JCJP.JCCo and JCCH.Job=JCJP.Job and JCCH.Phase=JCJP.Phase and JCCH.CostType = JCCP.CostType
          Join JCCI with(nolock) on JCJP.JCCo=JCCI.JCCo and JCJP.Contract=JCCI.Contract and JCJP.Item=JCCI.Item
                 where JCJP.JCCo=@JCCo and JCJP.Contract>=@BeginContract and JCJP.Contract<=@EndContract
            group by JCJP.JCCo, JCJP.Contract, JCJP.Item,JCCI.BillGroup,JCCH.BillFlag
     
     
          /* select the results */
       select  a.JCCo, COName=HQCO.Name,a.Contract,ContDesc=JCCM.Description,a.Item ,ItemDesc=JCCI.Description,BillGroup=JCCI.BillGroup,
             ItemUM=JCCI.UM, a.CurContractAmt, a.CurContractUnits, a.ChangeOrderAmt, a.ChangeOrderUnits,
             a.OrigContractAmt, a.OrigContractUnits,	a.PrevBilledAmt, a.PrevBilledUnits,a.PrevSMAmt,
             a.CurrEstCost,a.CurrEstUnits ,a.ProjCost, a.ProjUnits, a.ActualCost,a.ActualUnits,BillType=JCCI.BillType,
       
       
       /*  select bJCCI.JCCo, COName=bHQCO.Name,bJCCI.Contract, ContDesc=bJCCM.Description,
            bJCCI.Item, ItemDesc=bJCCI.Description,
           ItemUM=bJCCI.UM, BilledUnits=sum(a.BilledUnits), BilledAmt=sum(a.BilledAmt),
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
           CoName=bHQCO.Name,
           BeginMonth=@BeginMonth,
           EndMonth=@EndMonth,*/
           BeginContract=@BeginContract,
           EndContract=@EndContract,
           ContractStatus=JCCM.ContractStatus,
           ThroughMonth=@ThroughMonth
        --   COThroughDate=@COThroughDate
       
            from #WorksheetAmounts a
            JOIN JCCI with(nolock) on JCCI.JCCo=a.JCCo and JCCI.Contract=a.Contract and
                  JCCI.Item=a.Item 
             Join JCCM with(nolock) on JCCM.JCCo=JCCI.JCCo and JCCM.Contract=JCCI.Contract
             Join HQCO with(nolock) on HQCO.HQCo=JCCI.JCCo
         group by
            a.JCCo, HQCO.Name,a.Contract,JCCM.Description,JCCM.ContractStatus,a.Item ,JCCI.BillGroup,
            JCCI.Description, JCCI.UM, a.CurContractAmt, a.CurContractUnits, a.ChangeOrderAmt,
            a.ChangeOrderUnits, a.OrigContractAmt, a.OrigContractUnits, a.PrevBilledAmt, 
            a.PrevBilledUnits,a.PrevSMAmt,a.CurrEstCost,a.CurrEstUnits, a.ProjCost,a.ProjUnits, 
            a.ActualCost,a.ActualUnits,JCCI.BillType

GO
GRANT EXECUTE ON  [dbo].[brptJBProgressWS] TO [public]
GO
