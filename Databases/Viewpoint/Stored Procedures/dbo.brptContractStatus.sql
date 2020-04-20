SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.brptContractStatus    Script Date: 8/28/99 9:33:48 AM ******/
     CREATE  proc [dbo].[brptContractStatus]
        (@JCCo bCompany, @BeginContract bContract ='', @EndContract bContract= 'zzzzzzzzz',@ThroughMth bDate,
        @EndDate bDate)
        /* created 04/28/97 
         mod JRE 07/20/00 multipl records if more than 1 job per contract 
        
        select @JCCo=50, @BeginContract='', @EndContract= 'zzzzzzzzz',@ThroughMth='01/01/2020',
         @EndDate='01/01/2020'*/
        /* Mod 4/2/03 E.T. fixed to make ansii standard for Crystal 9.0 
                         fixed : notes & using tables instead of views. Issue #20721 */
   
   
        as
        create table #ContractStatus
            (JCCo            tinyint              NULL,
            Contract        char(10)            NULL,
            Job             char(10)                 NULL,
            PhaseGroup        tinyint                  NULL,
            CostType		tinyint                  NULL,
            CTAbbrev        char(5)                  NULL,
            Customer		int		NULL,
            CustName		varchar(60)	NULL,
            ProjCloseDate	smalldatetime	NULL,
            ContractDays		smallint	NULL,
            OrigContractAmt   decimal(12,2)               NULL,
            CurrContractAmt   decimal(12,2)              NULL,
            BilledAmt           decimal(12,2)              NULL,
            CurrRetainAmt      decimal (12,2)          Null,
            BilledTax      decimal (12,2)      Null,
            ReceivedAmt		decimal(12,2)		NULL,
            OrigEstCost         decimal(12,2)            NULL,
            CurrEstCost         decimal(12,2)            NULL,
            ActualCost      decimal(12,2)            NULL,
            ProjCost		decimal(12,2)            NULL,
            APAmount		decimal (12,2)		NULL,
            SourceAPAmt		decimal (12,2)    NULL
            )
   
        /* insert Contract info */
        insert into #ContractStatus
        (JCCo, Contract, OrigContractAmt, CurrContractAmt,
        	BilledAmt, CurrRetainAmt, BilledTax,  ReceivedAmt)
   
        Select JCCM.JCCo, JCCM.Contract,
                sum(case when JCID.JCTransType = 'OC' then(JCID.ContractAmt) else 0 end),
        	sum(JCID.ContractAmt), sum(JCID.BilledAmt), sum(JCID.CurrentRetainAmt), sum(JCID.BilledTax),
           sum(JCID.ReceivedAmt)
   
        FROM JCCM
       JOIN JCID on  JCCM.JCCo=JCID.JCCo and JCCM.Contract=JCID.Contract 
       where JCID.Mth<=@ThroughMth   and JCID.ActualDate<=@EndDate and
                JCCM.JCCo=@JCCo and JCCM.Contract>=@BeginContract and JCCM.Contract<=@EndContract
        group by
           JCCM.JCCo, JCCM.Contract
   
        /* insert jtd Cost info */
        insert into #ContractStatus
        (JCCo, Contract, Job, PhaseGroup,CostType, CTAbbrev,
         OrigEstCost, CurrEstCost, ActualCost, ProjCost)
   
        Select JCJM.JCCo, JCJM.Contract, JCJM.Job, JCCD.PhaseGroup,  JCCD.CostType, JCCT.Abbreviation,
   
        sum(case when JCCD.JCTransType='OE' then JCCD.EstCost else 0 end),
        sum(JCCD.EstCost),sum(JCCD.ActualCost),sum(JCCD.ProjCost)
   
        FROM JCJM
        JOIN JCCD on JCJM.JCCo=JCCD.JCCo and JCJM.Job=JCCD.Job
        JOIN JCCT on JCCD.PhaseGroup=JCCT.PhaseGroup and JCCD.CostType=JCCT.CostType
        Where JCCD.Mth<=@ThroughMth    and JCCD.ActualDate<=@EndDate
              and JCJM.JCCo=@JCCo and JCJM.Contract>=@BeginContract and JCJM.Contract<=@EndContract
   
        GROUP BY
        	JCJM.JCCo, JCJM.Contract,  JCJM.Job, JCCD.PhaseGroup, JCCD.CostType, JCCT.Abbreviation
   
   
        /* Get source AP */
        insert into #ContractStatus
   
               (JCCo, Contract, Job, PhaseGroup,CostType, CTAbbrev, SourceAPAmt)
   
        select JCJM.JCCo, JCJM.Contract, JCJM.Job, JCCD.PhaseGroup, JCCD.CostType,
               JCCT.Abbreviation, sum(JCCD.ActualCost)
        from JCJM    
        JOIN JCCD on JCJM.JCCo=JCCD.JCCo and JCJM.Job=JCCD.Job
        JOIN JCCT on JCCD.PhaseGroup=JCCT.PhaseGroup and JCCD.CostType=JCCT.CostType
        where  JCCD.JCTransType='AP' and
                 JCJM.JCCo=@JCCo and JCJM.Contract>=@BeginContract and JCJM.Contract<=@EndContract
                 and JCCD.JCTransType='AP' and JCCD.Mth <= @ThroughMth 
   
   
        GROUP BY
        	JCJM.JCCo, JCJM.Contract,  JCJM.Job, JCCD.PhaseGroup, JCCD.CostType, JCCT.Abbreviation
   
   
        /*insert AP Amount */
        insert into #ContractStatus
               (JCCo, Contract, Job, PhaseGroup,CostType, CTAbbrev,APAmount)
   
        select JCJM.JCCo, JCJM.Contract, JCJM.Job, APTL.PhaseGroup, APTL.JCCType, JCCT.Abbreviation,
               sum(APTD.Amount)
        from JCJM
        join APTL on APTL.JCCo=JCJM.JCCo and APTL.Job=JCJM.Job
        join APTD on APTD.APCo=APTL.APCo and APTD.Mth=APTL.Mth and APTD.APTrans=APTL.APTrans and APTL.APLine=APTD.APLine
        join JCCT on APTL.JCCType=JCCT.CostType and APTL.PhaseGroup=JCCT.PhaseGroup 
   
        where   JCJM.JCCo=@JCCo and JCJM.Contract>=@BeginContract and JCJM.Contract<=@EndContract
             --and (APTD.PaidMth>@EndDate or APTD.Status<3)
   	and ( (APTD.Mth <=@ThroughMth and  APTD.PaidMth>@ThroughMth) or (APTD.Mth <= @ThroughMth and APTD.PaidMth is null ))
   	
   	
   
        GROUP BY
        	JCJM.JCCo, JCJM.Contract, JCJM.Job, APTL.PhaseGroup, APTL.JCCType,
                JCCT.Abbreviation
   
    	/* select the results */  
   
       select JCCM.JCCo, JCCM.Contract, ContDesc=JCCM.Description, a.Job, 
            ProjectMgr=(select top 1 JCMP.Name from JCMP,JCJM
                where  JCJM.JCCo=a.JCCo and JCJM.Job=a.Job
                       and  JCMP.JCCo=JCJM.JCCo and JCMP.ProjectMgr=JCJM.ProjectMgr),
            a.PhaseGroup,
            CostType=a.CostType,
            CTAbbrev=a.CTAbbrev,
            Customer=JCCM.Customer,
            CustName=ARCM.Name,
            ProjCloseDate=JCCM.ProjCloseDate,
            ContractDays=JCCM.CurrentDays,
            OrigContractAmt=(a.OrigContractAmt),
            CurrContractAmt=(a.CurrContractAmt),
            BilledAmt=(a.BilledAmt),
            CurrRetainAmt=(a.CurrRetainAmt),
            BilledTax=(a.BilledTax),
            ReceivedAmt=(a.ReceivedAmt),
            OrigEstCost=(a.OrigEstCost),
            CurrEstCost=(a.CurrEstCost),
            ActualCost=(a.ActualCost),
            ProjCost=(a.ProjCost),
            --PaidToDate=IsNull(a.SourceAPAmt,0)-(IsNull(a.APAmount,0)),
           UnPaid = a.APAmount,
           a.SourceAPAmt,
           
          CoName=HQCO.Name,
          ThroughMth=@ThroughMth,
          EndDate=@EndDate,
          BeginContract=@BeginContract,
          EndContract=@EndContract,
          ContractStatus=JCCM.ContractStatus,
          JCCM.Notes
   
         from #ContractStatus a/*,JCCM,ARCM,JCJM,JCMP,HQCO
           where JCCM.JCCo=a.JCCo and JCCM.Contract=a.Contract and
           JCCM.CustGroup*=ARCM.CustGroup and JCCM.Customer*=ARCM.Customer and
          JCCM.JCCo*=JCJM.JCCo and JCCM.Contract*=JCJM.Contract and
          JCJM.JCCo=JCMP.JCCo and JCJM.ProjectMgr=JCMP.ProjectMgr and
         HQCO.HQCo=JCCM.JCCo and
    JCCM.JCCo=@JCCo and JCCM.Contract>=@BeginContract and JCCM.Contract<=@EndContract
          and a.JCCo=@JCCo and a.Contract>=@BeginContract and a.Contract<=@EndContract
          and HQCO.HQCo=@JCCo*/
        JOIN JCCM on JCCM.JCCo=a.JCCo and JCCM.Contract=a.Contract
            Left Join ARCM on ARCM.CustGroup=JCCM.CustGroup and ARCM.Customer=JCCM.Customer
   
            Join HQCO on HQCO.HQCo=JCCM.JCCo
        where JCCM.JCCo=@JCCo and JCCM.Contract>=@BeginContract and JCCM.Contract<=@EndContract
          and a.JCCo=@JCCo and a.Contract>=@BeginContract and a.Contract<=@EndContract
          and HQCO.HQCo=@JCCo

GO
GRANT EXECUTE ON  [dbo].[brptContractStatus] TO [public]
GO
