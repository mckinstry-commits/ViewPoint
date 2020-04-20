SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************        
Used By:        
AR AGing by Contract and        
AR Aging by PM        
***********************/        
        
/****** Object:  Stored Procedure dbo.brptARAgePM    Script Date: 8/28/99 9:32:28 AM ******/        
CREATE proc [dbo].[brptARAgePM] (@Company bCompany, @Month bMonth, @AgeDate bDate, @BegCust bCustomer=0, @EndCust bCustomer=999999, @RecType varchar(20),        
    @IncludeInvoicesThrough bDate,  @IncludeAdjPayThrough bDate,  @AgeOnDueorInv char(1)='D',        
    @LevelofDetail char(1)='I', @DeductDisc char(1)='Y', @DaysBetweenCols tinyint=30,        
    @AgeOpenCredits char(1)='N',@BegPM bigint=0, @EndPM bigint=9999999999, @BegContract bContract, @EndContract bContract )        
        
With Recompile        
as        
/* Mod 6/28/99 TF */        
/* Mod 6/29/99 JE */        
/* Mod 4/4/00 JE increased RecType to 20 chars */        
/* Mod 6/13/00 JRE changed Project Manager where clause -- if @BegPM=0 then include all AR even if PM is null */        
/* Mod 3/21/02 CR Added new field OpenYN - this field will check to see if a customer has an open amount*/        
/* Mod 9/6/02 CR added 'InvoiceJCCo=isnull(ARTH1.JCCo,ARTL.JCCo)'  for JCCo grouping on Aging by Contract */        
/* Mod 11/12/02 CR Added another clause to the OpenYN formula, it was not checking within the Month parameters */        
/* Mod 4/2/03 E.T. fixed to make ansii standard for Crystal 9.0 fixed : Concatination & notes. Issue #20721 */        
/* Mod 7/21/03  issue not created yet....added NOLOCKS to the From Clause CR */
/* Mod 8/8/03 DH Issue 22103.  Added With Recompile */
/* Mod 9/30/04 CR Issue 24596 Added new field "last check date"  */        
/* Mod 07/13/06 JE Issue 125053 Performance Improvements - combined tables into join select */
/* Mod 7/18/07 CR Issue 125713 added derived table for RecType */
/* Mod 12/26/07 SS Issue 126594 add isnull to where...JCJM.ProjectMgr */
/* Mod 06/20/08 - JH - Call #1376748 - moved Rec Types and Open trans to temp table to speed it up */
/* Mod 1/5/09 MB Issue 128762 */
/* Mod 6/24/10 HH Issue 138699 */
/* Mod 6/24/10 HH Issue 138700 */
        
if @RecType in (null,'')        
    begin        
        select @RecType = null        
    End        
    Else        
    begin        
        select @RecType = ',' + @RecType + ','        
    End        
        

create table #Open      
 (ARCo   tinyint  null,        
 ApplyMth smalldatetime null,        
 ApplyTrans int  null)        
        

create table #RT     
 (ARCo  tinyint  null,        
 RecType int  null)        
         

create table #Job    
 (JCCo  tinyint null,        
 Contract varchar(60) null,        
 ContractDesc varchar(60)  null,        
 Job  varchar (10) null)      


        
insert into #Job (JCCo, Contract, ContractDesc, Job)        
select JCCM.JCCo, JCCM.Contract, ContractDesc=isnull(min(JCCM.Description), ''),        
           Job=isnull(min(Job),'')        
        from JCCM with (NOLOCK)         
        Left Join JCJM with (NOLOCK) on JCCM.JCCo=JCJM.JCCo and JCJM.Contract=JCCM.Contract        
        where JCCM.Contract between @BegContract and @EndContract        
        group by JCCM.JCCo, JCCM.Contract        
        
        
        
insert into #Open (ARCo, ApplyMth, ApplyTrans)        
Select ARTL.ARCo, ApplyMth, ApplyTrans From ARTL        
             Join ARTH on ARTH.ARCo=ARTL.ARCo and ARTH.Mth=ARTL.Mth and ARTH.ARTrans=ARTL.ARTrans        
             Where        
             ARTL.ARCo=@Company and        
             ARTL.Mth<=@Month and ARTH.TransDate <= case when ARTH.ARTransType='I' then @IncludeInvoicesThrough  else @IncludeAdjPayThrough end        
             Group By ARTL.ARCo, ApplyMth, ApplyTrans having sum(ARTL.Retainage)<>0 or sum(ARTL.Amount)<>0        
        
        
        
insert into #RT (ARCo, RecType)        
select ARRT.ARCo, ARRT.RecType from ARRT with (nolock)        
                          where ARRT.ARCo = @Company and (@RecType is null or CHARINDEX(','+convert(varchar(3),ARRT.RecType)+',',@RecType)>0)        
        
        
        SELECT        
ARTL.Mth, ARTL.ARTrans, ARTL.RecType,        
AgeDate=case when @AgeOnDueorInv='I' then ARTH1.TransDate else isnull(ARTH1.DueDate,ARTH1.TransDate) end,      
DaysFromAge= case when @AgeOnDueorInv='I' then        
      DATEDIFF(day, ARTH1.TransDate, @AgeDate)        
    Else        
      DATEDIFF(day,isnull(ARTH1.DueDate,ARTH1.TransDate), @AgeDate)        
    end,        
OpenPaymentFlag=case when @AgeOpenCredits='Y' and ((ARTH.ARTransType='P' and ARTL.Mth=ARTL.ApplyMth and        
    ARTL.ARTrans=ARTL.ApplyTrans) or ARTH1.ARTransType='P')  then  1 else 0 end,  AgeAmount=(Case when @DeductDisc='Y' then isnull(ARTL.Amount,0)-isnull(ARTL.DiscOffered,0)-isnull(ARTL.Retainage,0)        
           else isnull(ARTL.Amount,0)-isnull(ARTL.Retainage,0) end)-0,        
Amount=isnull(ARTL.Amount,0)-0, Retainage=isnull(ARTL.Retainage,0)-0, DiscOffered=ARTL.DiscOffered-0,        
ARTL.ApplyMth, ARTL.ApplyTrans, ARTH.ARCo, ARTH.ARTrans, ARTH.ARTransType, ARTH.Customer, ARTH.RecType,        
ARTH.TransDate, ARTH.Description, ARTH.AppliedTrans, InvoiceARTransType=ARTH1.ARTransType,InvoiceJCCo=isnull(ARTH1.JCCo,ARTL.JCCo),        
InvoiceContract=isnull(ARTH1.Contract,ARTL.Contract),/*JobDesc=JCJM.Description*/JobDesc=ContractDesc, JCJM.ProjectMgr,PMName=JCMP.Name,ARTH1.Invoice, InvoiceTransDate=ARTH1.TransDate,        
InvoiceDueDate=ARTH1.DueDate,        
InvoiceDiscDate=ARTH1.DiscDate, InvoiceDesc=ARTH1.Description,        
ARCM.Name,ARCM.SortName, ARCM.Phone, ARCM.Contact, ARCM.StmntPrint,        
        
DateDesc=case when @AgeOnDueorInv='D' then 'Due Date' else  'Inv Date' end,        
LineDateDesc=case when @AgeOnDueorInv='D' and @LevelofDetail='I' then 'Due Date'        
                  when @AgeOnDueorInv='I' and @LevelofDetail='I' then 'Inv Date'        
                  Else 'Tran Date' end,        
Over1Desc=convert(varchar(3),@DaysBetweenCols+1)+'-'+convert(varchar(3),@DaysBetweenCols*2),        
Over2Desc=convert(varchar(3),(@DaysBetweenCols*2)+1)+'-'+convert(varchar(3),@DaysBetweenCols*3),        
Over3Desc='Over '+convert(varchar(3),@DaysBetweenCols*3),        
LastCheckDate,  -- issue 125053         
--old           LastCheckDate = (select Max(a.TransDate) from ARTH a where a.ARTransType = 'P' and a.Customer = ARTH.Customer and   a.Mth<=@Month and a.TransDate <=@IncludeAdjPayThrough and a.ARCo=ARTH.ARCo),        
        
--OpenYN=case when (select sum(I.Amount)+ sum(I.Retainage) From ARTL I        
--where I.ARCo=ARTL.ARCo and I.ApplyMth=ARTL.Mth and I.ApplyTrans=ARTL.ARTrans and I.Mth <= @Month) <> 0        
--Then 'Y' Else 'N' end,        
        
PrintCompany= convert(varchar(3),HQCO.HQCo)+' '+Isnull(HQCO.Name,''),        
ParamMonth=@Month,        
ParamAgeDate=@AgeDate,        
ParamBegPM=@BegPM,        
ParamEndPM=@EndPM,        
ParamBegCust=Case when @BegCust=0 then 'First' else convert(varchar(8),@BegCust) end,        
ParamEndCust=Case when @EndCust=99999999 then 'Last' else convert(varchar(8),@EndCust) end,        
ParamRecType=Case when @RecType is null then 'All' else @RecType end,        
ParamIncInvoicesThru=@IncludeInvoicesThrough,        
ParamInclAdjPayThru=@IncludeAdjPayThrough,        
ParamAgeOnDueorInv=@AgeOnDueorInv,        
ParamLevelofDetail=@LevelofDetail,        
ParamDeductDisc=@DeductDisc,        
ParamDaysBetweenCols=@DaysBetweenCols,        
ParamAgeOpenCredits=@AgeOpenCredits,        
ParamBegContract=@BegContract,        
ParamEndContract=@EndContract        
--, InvoiceNotes=ARTH1.Notes        
        
        
From ARTL with (NOLOCK)        
JOIN ARTH ARTH1 with (NOLOCK) ON ARTL.ARCo = ARTH1.ARCo AND ARTL.ApplyMth = ARTH1.Mth AND        
    ARTL.ApplyTrans = ARTH1.ARTrans        
join #Open OpenC ON OpenC.ARCo=ARTL.ARCo and OpenC.ApplyMth=ARTL.ApplyMth and OpenC.ApplyTrans=ARTL.ApplyTrans        
/*JOIN (Select ARTL.ARCo, ApplyMth, ApplyTrans From ARTL        
             Join ARTH on ARTH.ARCo=ARTL.ARCo and ARTH.Mth=ARTL.Mth and ARTH.ARTrans=ARTL.ARTrans        
             Where        
             ARTL.ARCo=@Company and        
             ARTL.Mth<=@Month and ARTH.TransDate <= case when ARTH.ARTransType='I' then @IncludeInvoicesThrough  else @IncludeAdjPayThrough end        
             Group By ARTL.ARCo, ApplyMth, ApplyTrans having sum(ARTL.Retainage)<>0 or sum(ARTL.Amount)<>0) as OpenC        
    ON OpenC.ARCo=ARTL.ARCo and OpenC.ApplyMth=ARTL.ApplyMth and OpenC.ApplyTrans=ARTL.ApplyTrans        
*/        
        
        
JOIN HQCO with (NOLOCK) ON ARTL.ARCo = HQCO.HQCo        
JOIN ARTH with (NOLOCK) ON ARTL.ARCo = ARTH.ARCo AND ARTL.Mth = ARTH.Mth AND ARTL.ARTrans = ARTH.ARTrans        
JOIN ARCM with (NOLOCK) ON ARTH.CustGroup = ARCM.CustGroup AND ARTH.Customer = ARCM.Customer        
-- Issue 125053 left join        
Left Join #Job ContMinJob on ARTL.JCCo=ContMinJob.JCCo and ARTL.Contract=ContMinJob.Contract        
/*Left Join (select JCCM.JCCo, JCCM.Contract, ContractDesc=min(JCCM.Description),        
           Job=min(Job)        
        from JCCM with (NOLOCK)         
        Left Join JCJM with (NOLOCK) on JCCM.JCCo=JCJM.JCCo and JCJM.Contract=JCCM.Contract        
        where JCCM.Contract between @BegContract and @EndContract        
        group by JCCM.JCCo, JCCM.Contract)        
        as ContMinJob on ARTL.JCCo=ContMinJob.JCCo and ARTL.Contract=ContMinJob.Contract*/        
Left Join JCJM with (NOLOCK) on JCJM.JCCo=ContMinJob.JCCo and JCJM.Job=ContMinJob.Job        
Left Join JCMP with (NOLOCK) on JCMP.JCCo=JCJM.JCCo and JCMP.ProjectMgr=JCJM.ProjectMgr        
        
-- Issue 125053 left join
-- Issue 138699 comparison from ARTH.TransDate =@IncludeAdjPayThrough to ARTH.TransDate<=@IncludeAdjPayThrough
Left Join (select ARCo, Customer, LastCheckDate = Max(TransDate) from ARTH        
   where ARTH.ARTransType = 'P' and ARTH.ARCo=@Company and        
      ARTH.Mth<=@Month and ARTH.TransDate<=@IncludeAdjPayThrough        
   group by ARCo, Customer) a on a.ARCo=ARTH.ARCo and a.Customer = ARTH.Customer        
join #RT RT on RT.ARCo = ARTL.ARCo and RT.RecType = ARTL.RecType        
/*join (select ARRT.ARCo, ARRT.RecType from ARRT with (nolock)        
                          where ARRT.ARCo = @Company and (@RecType is null or CHARINDEX(','+convert(varchar(3),ARRT.RecType)+',',@RecType)>0))        
                          as RT on RT.ARCo = ARTL.ARCo and RT.RecType = ARTL.RecType        
HH JH */        
Where        
    ARTL.ARCo=@Company         
    AND ARTL.Mth <= @Month        
    AND ARTH1.ARCo=@Company        
    AND ARTH1.Customer >= @BegCust        
    AND ARTH1.Customer <= @EndCust        
    --AND (@RecType is null or CHARINDEX(','+convert(varchar(3),ARTL.RecType)+',',@RecType)>0)        
    AND isnull(JCJM.ProjectMgr,0) between @BegPM and @EndPM        
    AND (ARTH.TransDate <= case when ARTH.ARTransType='I' then @IncludeInvoicesThrough  else @IncludeAdjPayThrough end)        
    AND (ARTL.Contract >= @BegContract and ARTL.Contract <= @EndContract)        
    --and isnull(ARTL.Contract,'1') = case when ARTL.Contract Is Not Null then JCCM.Contract else '1' end        
        
Order By        
    ARTH1.ARCo ASC,        
    isnull(ARTH1.Contract,ARTL.Contract) ASC,        
    ARTH1.Customer ASC,        
    case when @AgeOpenCredits='Y' and ((ARTH.ARTransType='P' and ARTL.Mth=ARTL.ApplyMth and        
        ARTL.ARTrans=ARTL.ApplyTrans) or ARTH1.ARTransType='P')  then  1 else 0 end,        
    ARTH1.Invoice,        
    ARTH1.Mth,        
    ARTL.ApplyTrans,        
    ARTH.ARTransType 

GO
GRANT EXECUTE ON  [dbo].[brptARAgePM] TO [public]
GO
