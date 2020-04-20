SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE               proc [dbo].[brptJCCostRev]
       (@JCCo bCompany,  @BeginContract bContract ='', @EndContract bContract= 'zzzzzzzzz', @ThroughMth bDate,
        @BegMth bDate,@BegDept bDept='', @EndDept bDept='zzzzzzzzzz', @Status char(1)='A', @BegMthClosed bDate, 
        @EndMthClosed bDate)
     
    /*Add Beg Month for month range - also suggested to use no dates and change the JCID to JCIP and JCCD to JCCP, but this has not been done yet*/ 
    /* Get Cost Type Descriptions - even if no records exist in detail*/
       /* created 5/5/97 Not updated for security*/
       /* fixed 12/21/99 bad join for JCJM caused double contract and job amounts when multiple jobs per contract*/
       /*fixed 08/31/00 by Hong-Soo, CT header uses the subquery*/
       /* JRE changed how to get JCCT Abbreviations */
       /* JRE 9/17/02  Issue #18589  re-wrote stored procedure for effeciency
          DH 5/23/03  Issue 20993 - Recompiled stored procedure, used to be ContAmtsCTDesc 
          DH 6/12/03  Issue 20993 - Removed Notes Field
          DH 8/15/03  Added NoLocks and With Recompile
          NF 12/18/03 Issue 23312 Added Department Description from JCDM 
          DH 8/10/10  Issue 137110 Added CTE to restrict contracts by status based on MonthClosed
          HH 2/8/12	Issue 142699 / TK-12290 Changed open/soft-closed/hard-closed conditions to: 
				Contracts with the following statuses (JCCM.ContractStatus) should show under the following conditions of the Open, Open/Soft Closed, Closed parameter:
				- Open 
						Contract Status = 1 (regardless of JCCM.MonthClosed value) 
						Contract Status = 2 if MonthClosed > @EndMonth (@ThroughMth) 
						Contract Status = 3 if MonthClosed > @EndMonth (@ThroughMth)
				- Soft Closed 
						Contract Status = 2 if MonthClosed <= @EndMonth (@ThroughMth)
				- Closed 
						Contract Status = 3 where MonthClosed is between Beginning Closed Month and Ending Closed Month parameters.
		  HH 4/11/12 Issue 143382 removed pending/non-interfaced PM Contracts (JCCM.ContractStauts = 0) for 'All Contracts'-option
          
        */  
   
    With Recompile   
   as
     set nocount on
     
 
   --
     declare @CT1Desc varchar(10), @CT2Desc varchar(10), @CT3Desc varchar(10),
     	@CT4Desc varchar(10), @CT5Desc varchar(10), @CT6Desc varchar(10),
     	@CT7Desc varchar(10), @CT8Desc varchar(10), @CT9Desc varchar(10)
   
    select @CT1Desc=JCCT.Abbreviation 
    		     from HQCO
                join JCCT WITH (NOLOCK) on HQCO.PhaseGroup=JCCT.PhaseGroup 
                Where HQCO.HQCo=@JCCo and JCCT.CostType=1
    select @CT2Desc=JCCT.Abbreviation 
    		     from HQCO
                join JCCT WITH (NOLOCK) on HQCO.PhaseGroup=JCCT.PhaseGroup 
                Where HQCO.HQCo=@JCCo and JCCT.CostType=2
    select @CT3Desc=JCCT.Abbreviation 
    		     from HQCO
                join JCCT WITH (NOLOCK) on HQCO.PhaseGroup=JCCT.PhaseGroup 
                Where HQCO.HQCo=@JCCo and JCCT.CostType=3
    select @CT4Desc=JCCT.Abbreviation 
    		     from HQCO
                join JCCT WITH (NOLOCK) on HQCO.PhaseGroup=JCCT.PhaseGroup 
                Where HQCO.HQCo=@JCCo and JCCT.CostType=4
    select @CT5Desc=JCCT.Abbreviation 
    		     from HQCO
                join JCCT WITH (NOLOCK) on HQCO.PhaseGroup=JCCT.PhaseGroup 
                Where HQCO.HQCo=@JCCo and JCCT.CostType=5
    select @CT6Desc=JCCT.Abbreviation 
    		     from HQCO
                join JCCT WITH (NOLOCK) on HQCO.PhaseGroup=JCCT.PhaseGroup 
                Where HQCO.HQCo=@JCCo and JCCT.CostType=6
     select @CT7Desc=JCCT.Abbreviation 
    		     from HQCO
                join JCCT WITH (NOLOCK) on HQCO.PhaseGroup=JCCT.PhaseGroup 
                Where HQCO.HQCo=@JCCo and JCCT.CostType=7
     select @CT8Desc=JCCT.Abbreviation 
    		     from HQCO
                join JCCT WITH (NOLOCK) on HQCO.PhaseGroup=JCCT.PhaseGroup 
                Where HQCO.HQCo=@JCCo and JCCT.CostType=8
    select @CT9Desc=JCCT.Abbreviation 
    		     from HQCO
                join JCCT WITH (NOLOCK) on HQCO.PhaseGroup=JCCT.PhaseGroup 
                Where HQCO.HQCo=@JCCo and JCCT.CostType=9
                
                
   
   set nocount off;
   
/*****CTE  Selects contracts based on the Contract Status parameter input by the user.  CTE is then joined in final 
		Select to limit contracts based on user input selection

Contracts with the following statuses (JCCM.ContractStatus) should show under the following conditions of the Open, Open/Soft Closed, Closed parameter:
- Open 
		Contract Status = 1 (regardless of JCCM.MonthClosed value) 
		Contract Status = 2 if MonthClosed > @EndMonth (@ThroughMth)
		Contract Status = 3 if MonthClosed > @EndMonth (@ThroughMth)
- Soft Closed 
		Contract Status = 2 if MonthClosed <= @EndMonth (@ThroughMth)
- Closed 
		Contract Status = 3 where MonthClosed is between Beginning Closed Month and Ending Closed Month parameters.

*******/    
   
With Contracts (JCCo, Contract) 
       as (select JCCo, 
                  Contract 
           From   JCCM 
           Where  JCCo = @JCCo 
                  and ( 
                      ------------------------ 
                      /*Open*/ 
                      case @Status 
                        when 'O' then ContractStatus 
                      end = 1 
                       or /*Open*/ 
                      case @Status 
                        when 'O' then ContractStatus 
                      end = 2 
                      and MonthClosed > @ThroughMth 
                       or /*Open*/ 
                      case @Status 
                        when 'O' then ContractStatus 
                      end = 3 
                      and MonthClosed > @ThroughMth 
                       ------------------------ 
                       or /*Soft-Closed/Open*/ 
                      case @Status 
                        when 'S' then ContractStatus 
                      end = 2 
                      and MonthClosed <= @ThroughMth 
                       or /*Soft-Closed/Open*/ 
                      case @Status 
                        when 'S' then ContractStatus 
                      end = 1 
                       or /*Soft-Closed/Open*/ 
                      case @Status 
                        when 'S' then ContractStatus 
                      end = 2 
                      and MonthClosed > @ThroughMth 
                       or /*Soft-Closed/Open*/ 
                      case @Status 
                        when 'S' then ContractStatus 
                      end = 3 
                      and MonthClosed > @ThroughMth 
                       ------------------------ 
                       or /*Hard-Closed*/ 
                      case @Status 
                        when 'C' then ContractStatus 
                      end = 3 
                      and MonthClosed between @BegMthClosed and @EndMthClosed 
                       ------------------------   
                       or /*All (without pending or non-interfaced from PM which is ContractStatus 0)*/ 
                      case @Status 
                        when 'A' then ContractStatus 
                      end <> 0 )
	) --End CTE 
   
   
       Select 'CT1Desc'=@CT1Desc, 'CT2Desc'=@CT2Desc, 'CT3Desc'=@CT3Desc,'CT4Desc'=@CT4Desc, 
              'CT5Desc'=@CT5Desc,'CT6Desc'= @CT6Desc,	'CT7Desc'=@CT7Desc, 'CT8Desc'=@CT8Desc,'CT9Desc'=@CT9Desc,
     
               JCCM.JCCo, JCCM.Contract, ContDesc=JCCM.Description, JCCM.ContractStatus,
              JCCI.Department,
   	   DeptDesc = JCDM.Description,
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
       
   	BegMth=@BegMth/*,
        JCCM.Notes*/
   
       FROM JCCI WITH (NOLOCK) 
       JOIN JCCM WITH (NOLOCK) on JCCM.JCCo=JCCI.JCCo and JCCM.Contract=JCCI.Contract
       JOIN Contracts on JCCM.JCCo=Contracts.JCCo and JCCM.Contract = Contracts.Contract /**CTE with Contracts filtered by Status**/
       Join JCDM WITH (NoLock) on JCDM.JCCo=JCCI.JCCo and JCDM.Department = JCCI.Department
       Join HQCO WITH (NOLOCK) on HQCO.HQCo=JCCI.JCCo
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
           join JCJP WITH (NOLOCK) on JCJP.JCCo=JCCP.JCCo and JCJP.Job=JCCP.Job and JCJP.PhaseGroup=JCCP.PhaseGroup
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
GRANT EXECUTE ON  [dbo].[brptJCCostRev] TO [public]
GO
