SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     proc [dbo].[brptContAmtsCTDesc]
       (@JCCo bCompany,  @BeginContract bContract ='', @EndContract bContract= 'zzzzzzzzz', @ThroughMth bDate,
        @BegMth bDate,@BegDept bDept='', @EndDept bDept='zzzzzzzzzz')
     
    /*Add Beg Month for month range - also suggested to use no dates and change the JCID to JCIP and JCCD to JCCP, but this has not been done yet*/ 
    /* Get Cost Type Descriptions - even if no records exist in detail*/
       /* created 5/5/97 Not updated for security*/
       /* fixed 12/21/99 bad join for JCJM caused double contract and job amounts when multiple jobs per contract*/
       /*fixed 08/31/00 by Hong-Soo, CT header uses the subquery*/
       /* JRE changed how to get JCCT Abbreviations */
       /* JRE 9/17/02  Issue #18589  re-wrote stored procedure for effeciency */
       as
     set nocount on
   
   --
     declare @CT1Desc varchar(10), @CT2Desc varchar(10), @CT3Desc varchar(10),
     	@CT4Desc varchar(10), @CT5Desc varchar(10), @CT6Desc varchar(10),
     	@CT7Desc varchar(10), @CT8Desc varchar(10), @CT9Desc varchar(10)
   
    select @CT1Desc=JCCT.Abbreviation 
    		     from HQCO
                join JCCT on HQCO.PhaseGroup=JCCT.PhaseGroup 
                Where HQCO.HQCo=@JCCo and JCCT.CostType=1
    select @CT2Desc=JCCT.Abbreviation 
    		     from HQCO
                join JCCT on HQCO.PhaseGroup=JCCT.PhaseGroup 
                Where HQCO.HQCo=@JCCo and JCCT.CostType=2
    select @CT3Desc=JCCT.Abbreviation 
    		     from HQCO
                join JCCT on HQCO.PhaseGroup=JCCT.PhaseGroup 
                Where HQCO.HQCo=@JCCo and JCCT.CostType=3
    select @CT4Desc=JCCT.Abbreviation 
    		     from HQCO
                join JCCT on HQCO.PhaseGroup=JCCT.PhaseGroup 
                Where HQCO.HQCo=@JCCo and JCCT.CostType=4
    select @CT5Desc=JCCT.Abbreviation 
    		     from HQCO
                join JCCT on HQCO.PhaseGroup=JCCT.PhaseGroup 
                Where HQCO.HQCo=@JCCo and JCCT.CostType=5
    select @CT6Desc=JCCT.Abbreviation 
    		     from HQCO
                join JCCT on HQCO.PhaseGroup=JCCT.PhaseGroup 
                Where HQCO.HQCo=@JCCo and JCCT.CostType=6
     select @CT7Desc=JCCT.Abbreviation 
    		     from HQCO
                join JCCT on HQCO.PhaseGroup=JCCT.PhaseGroup 
                Where HQCO.HQCo=@JCCo and JCCT.CostType=7
     select @CT8Desc=JCCT.Abbreviation 
    		     from HQCO
                join JCCT on HQCO.PhaseGroup=JCCT.PhaseGroup 
                Where HQCO.HQCo=@JCCo and JCCT.CostType=8
    select @CT9Desc=JCCT.Abbreviation 
    		     from HQCO
                join JCCT on HQCO.PhaseGroup=JCCT.PhaseGroup 
                Where HQCO.HQCo=@JCCo and JCCT.CostType=9
   
   set nocount off
   
       Select 'CT1Desc'=@CT1Desc, 'CT2Desc'=@CT2Desc, 'CT3Desc'=@CT3Desc,'CT4Desc'=@CT4Desc, 
              'CT5Desc'=@CT5Desc,'CT6Desc'= @CT6Desc,	'CT7Desc'=@CT7Desc, 'CT8Desc'=@CT8Desc,'CT9Desc'=@CT9Desc,
     
               JCCM.JCCo, JCCM.Contract, ContDesc=JCCM.Description, JCCM.ContractStatus,
              JCCI.Department,
              JCIP.BilledAmt,
              JCIP.ReceivedAmt,ActualCost,ACost1,ACost2,ACost3,ACost4,ACost5,ACost6,ACost7,ACost8,ACost9,
              ProjCloseDate=JCCM.ProjCloseDate,
              StartMonth=JCCM.StartMonth,---7/5/02 AA
              MonthClosed=JCCM.MonthClosed,---7/5/02 AA
              ContractDays=JCCM.CurrentDays,
       CoName=HQCO.Name,
       BeginContract=@BeginContract,
       EndContract=@EndContract,
       ThroughMth=@ThroughMth,
       
   	BegMth=@BegMth,
        JCCM.Notes
   
       FROM JCCI WITH (NOLOCK) 
       JOIN JCCM on JCCM.JCCo=JCCI.JCCo and JCCM.Contract=JCCI.Contract
       Join HQCO on HQCO.HQCo=JCCI.JCCo
   --- Revenue   	
       left join (select JCCo, Contract, Item, BilledAmt=sum(JCIP.BilledAmt),ReceivedAmt=sum(JCIP.ReceivedAmt)
           from JCIP
           where JCIP.Mth>=@BegMth and JCIP.Mth<=@ThroughMth
                 and (JCIP.ContractAmt<>0 or JCIP.BilledAmt<>0 or JCIP.ReceivedAmt<>0)
           group by JCCo, Contract, Item) 
           as JCIP on JCIP.JCCo=JCCI.JCCo and JCIP.Contract=JCCI.Contract and JCIP.Item=JCCI.Item
   -- Cost
        left join (select JCJP.JCCo, JCJP.Contract, JCJP.Item,
           ActualCost=sum(case when JCCP.Mth>=@BegMth then ActualCost else 0 end),
           ACost1=sum(case when CostType=1 and JCCP.Mth>=@BegMth then JCCP.ActualCost else 0 end),
   		ACost2=sum(case when CostType=2 and JCCP.Mth>=@BegMth then JCCP.ActualCost else 0 end),
   		ACost3=sum(case when CostType=3 and JCCP.Mth>=@BegMth then JCCP.ActualCost else 0 end),
   		ACost4=sum(case when CostType=4 and JCCP.Mth>=@BegMth then JCCP.ActualCost else 0 end),
   		ACost5=sum(case when CostType=5 and JCCP.Mth>=@BegMth then JCCP.ActualCost else 0 end),
   		ACost6=sum(case when CostType=6 and JCCP.Mth>=@BegMth then JCCP.ActualCost else 0 end),
   		ACost7=sum(case when CostType=7 and JCCP.Mth>=@BegMth then JCCP.ActualCost else 0 end),
   		ACost8=sum(case when CostType=8 and JCCP.Mth>=@BegMth then JCCP.ActualCost else 0 end),
   		ACost9=sum(case when (CostType<1 or CostType>8) and JCCP.Mth>=@BegMth then JCCP.ActualCost else 0 end)
           from JCCP 
           join JCJP on JCJP.JCCo=JCCP.JCCo and JCJP.Job=JCCP.Job and JCJP.PhaseGroup=JCCP.PhaseGroup
                     and JCJP.Phase=JCCP.Phase
           where JCCP.Mth>=@BegMth and JCCP.Mth<=@ThroughMth
             and JCJP.JCCo=@JCCo and JCJP.Contract>=@BeginContract and JCJP.Contract<=@EndContract
   		group by JCJP.JCCo, JCJP.Contract, JCJP.Item) 
           as JCCP on JCCP.JCCo=JCCI.JCCo and JCCP.Contract=JCCI.Contract and JCCP.Item=JCCI.Item
   --- where 
       where JCCI.JCCo=@JCCo and JCCI.Contract>=@BeginContract and JCCI.Contract<=@EndContract
                  and JCCI.Department>=@BegDept and JCCI.Department<=@EndDept 
   
   --- order by 
       order by JCCI.JCCo, JCCI.Department, JCCI.Contract

GO
GRANT EXECUTE ON  [dbo].[brptContAmtsCTDesc] TO [public]
GO
