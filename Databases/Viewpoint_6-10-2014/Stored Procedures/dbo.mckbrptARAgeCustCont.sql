SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.brptARAgeCustCont    Original Script Date: 8/28/99 9:32:28 AM     
                                                               Copied From ARAgePM     Copy Date  3/21/02    
           
        Used in Report   ARAgeCustCont.rpt    
       *******/    
CREATE proc [dbo].[mckbrptARAgeCustCont]   
(@Company bCompany, @Month bMonth, @AgeDate bDate, @BegCust bCustomer=0, @EndCust bCustomer=999999, @RecType varchar(20),    
@IncludeInvoicesThrough bDate,  @IncludeAdjPayThrough bDate,  @AgeOnDueorInv char(1)='D',    
@LevelofDetail char(1)='I', @DeductDisc char(1)='Y', @DaysBetweenCols tinyint=30,    
@AgeOpenCredits char(1)='N',@BegPM int=0, @EndPM int=2147483647, @BegContract bContract, @EndContract bContract, @Department varchar(10),@POC int)    
            
        With Recompile    
           as    
          /* Mod 6/28/99 TF */    
          /* Mod 6/29/99 JE */    
         /* Mod 4/4/00 JE increased RecType to 20 chars */    
         /* Mod 6/13/00 JRE changed Project Manager where clause -- if @BegPM=0 then include all AR even if PM is null */    
         /* Mod 3/21/02 CR Added new field OpenYN - this field will check to see if a customer has an open amount*/    
         /* Mod 11/12/02 CR Added another clause to the OpenYN formula, it was not checking within the Month parameters */    
         /* Mod 1/20/03 CR Added clause to remove ARTL.LineType <> 'F'(Finance Charges)      
        reversed and added back in on 2/6/03 CR   */    
         /* Mod 2/6/03 CR changed Where Clause Contract parameters pointing, originally pointing to ARTH1, now ARTL  */    
         /* Mod 4/2/03 E.T. fixed to make ansii standard for Crystal 9.0 fixed : Contcatination & notes. Issue #20721 */    
         /* Mod 6/12/03 DH Removed Notes Field Issue 20993*/    
         /*Mod 7/21/03  issue not created yet....added NOLOCKS to the From Clause CR    
           Mod 8/8/03  Mod 8/8/03 DH Issue 22103.  Added With Recompile       
    Mod 12/18/03 issue 22659 CR remmed out the OPENYN field and added the Join Select stmt in the Join clause    
           Mod 2/23/05 CR Issue 26960  added Company to the LastCheckDate sub query  */    
          /* mod 7/18/07 CR Issue 125877 created derived table for RecType */    
          /* SP modified for call #1358619 - changed to use temp tables to take it from 10 minutes to 1. - JH*/    
          /*    used mod for above call on issue #127001  CR */    
          /*08/30/2012	ScottAlvey	CL-###### / V1-B-10810	AR Customer and Aging Reports - not showing SM Invoice description	
			added cte to get just Invoiced invoices from SM and the left joined it twice, once to ARTH and another to
			ARTH1.*/
    
print @BegPM
print @EndPM
           if @RecType in (null,'')    
            begin    
             select @RecType = null    
            end    
            else    
            begin    
             select @RecType = ',' + @RecType + ','    
            end    
    
create table #Open    
 (ARCo   tinyint  null,    
 ApplyMth smalldatetime null,    
 ApplyTrans int  null)    
    
create table #RT    
 (ARCo  tinyint  null,    
 RecType int  null)    
    
insert into #Open (ARCo, ApplyMth, ApplyTrans)    
Select ARTL.ARCo, ApplyMth, ApplyTrans From ARTL     
                            Join ARTH on ARTH.ARCo=ARTL.ARCo and ARTH.Mth=ARTL.Mth and ARTH.ARTrans=ARTL.ARTrans    
                            Where ARTL.Mth<=@Month and ARTH.TransDate <= case when ARTH.ARTransType='I' then @IncludeInvoicesThrough  else @IncludeAdjPayThrough end    
                            Group By ARTL.ARCo, ApplyMth, ApplyTrans having sum(ARTL.Retainage)<>0 or sum(ARTL.Amount)<>0    
    
    
    
insert into #RT (ARCo, RecType)    
select ARRT.ARCo, ARRT.RecType /*into RT*/     
from ARRT with (nolock)    
where ARRT.ARCo = @Company and (@RecType is null or CHARINDEX(','+convert(varchar(3),ARRT.RecType)+',',@RecType)>0)    ;

-- start V1-B-10810
   
with

cte_SMInvoiceList

as

(
	select
		ARCo 
		, ARPostedMth 
		, ARTrans 
		, DescriptionOfWork
		, InvoiceStatus
	from
		SMInvoiceList
	where
		InvoiceStatus = 'Invoiced'
)		  

-- end V1-B-10810
    
    
            
            
           SELECT    
               ARTL.Mth, ARTL.ARTrans, ARTL.RecType,    
               AgeDate=case when @AgeOnDueorInv='I' then ARTH1.TransDate else isnull(ARTH1.DueDate,ARTH1.TransDate) end,    
               DaysFromAge= case when @AgeOnDueorInv='I' then    
                 DATEDIFF(day, ARTH1.TransDate, @AgeDate)    
               else    
                 DATEDIFF(day,isnull(ARTH1.DueDate,ARTH1.TransDate), @AgeDate)    
       end,    
               OpenPaymentFlag=case when @AgeOpenCredits='Y' and ((ARTH.ARTransType='P' and ARTL.Mth=ARTL.ApplyMth and    
                   ARTL.ARTrans=ARTL.ApplyTrans) or ARTH1.ARTransType='P')  then  1 else 0 end,    
                AgeAmount=(Case when @DeductDisc='Y' then isnull(ARTL.Amount,0)-isnull(ARTL.DiscOffered,0)-isnull(ARTL.Retainage,0)    
                          else isnull(ARTL.Amount,0)-isnull(ARTL.Retainage,0) end)-0,    
                Amount=isnull(ARTL.Amount,0)-0, Retainage=isnull(ARTL.Retainage,0)-0, DiscOffered=ARTL.DiscOffered-0,    
                ARTL.ApplyMth, ARTL.ApplyTrans, ARTH.ARCo, 
                --ARTH.ARTrans, 
                ARTH.ARTransType,ARTH.Customer, 
                --ARTH.RecType,    
                ARTH.TransDate, 
                	--, ARTH.Description
			  case when ARTH.Source = 'SM Invoice'   --V1-B-10810  
				then SMARTH.DescriptionOfWork
				else ARTH.Description  
			  end as Description,
			   ARTH.AppliedTrans, InvoiceARTransType=ARTH1.ARTransType,InvoiceJCCo=isnull(ARTH1.JCCo,ARTL.JCCo),    
                InvoiceContract=isnull(ARTH1.Contract,ARTL.Contract),/*JobDesc=JCJM.Description*/JobDesc=JCCM.Description, JCJM.ProjectMgr,PMName=JCMP.Name,ARTH1.Invoice, InvoiceTransDate=ARTH1.TransDate,    
 InvoiceDueDate=ARTH1.DueDate,    
               InvoiceDiscDate=ARTH1.DiscDate, 
               --InvoiceDesc=ARTH1.Description, 
			  case when ARTH1.Source = 'SM Invoice'  --V1-B-10810   
				then SMARTH1.DescriptionOfWork
				else ARTH1.Description  
			  end as InvoiceDesc,     
               ARCM.Name,ARCM.SortName, ARCM.Phone, ARCM.Contact, ARCM.StmntPrint,    
            
               DateDesc=case when @AgeOnDueorInv='D' then 'Due Date' else  'Inv Date' end,    
               LineDateDesc=case when @AgeOnDueorInv='D' and @LevelofDetail='I' then 'Due Date'    
                                 when @AgeOnDueorInv='I' and @LevelofDetail='I' then 'Inv Date'    
                                 else 'Tran Date' end,    
               Over1Desc=convert(varchar(3),@DaysBetweenCols+1)+'-'+convert(varchar(3),@DaysBetweenCols*2),    
       
               Over2Desc=convert(varchar(3),(@DaysBetweenCols*2)+1)+'-'+convert(varchar(3),@DaysBetweenCols*3),    
               Over3Desc='Over '+convert(varchar(3),@DaysBetweenCols*3),    
               LastCheckDate = (select Max(a.TransDate) from ARTH a where a.ARTransType = 'P' and a.Customer = ARTH.Customer and     
                 a.Mth<=@Month and a.TransDate <=@IncludeAdjPayThrough and a.ARCo = ARTH.ARCo),    
            
            
        --OpenYN=case when (select sum(I.Amount)+sum(I.Retainage) From ARTL I    
        --where I.ARCo=ARTL.ARCo and I.ApplyMth=ARTL.Mth and I.ApplyTrans=ARTL.ARTrans and I.Mth<=@Month) <> 0    
        --Then 'Y' Else 'N' end,    
               --Added I.Mth <=@Month 11/12/02 CR    
           
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
               ParamEndContract=@EndContract,    
               InvoiceNotes=ARTH1.Notes,    
				
				JCCM.Department,
				JCCM.udPOC ,
				c.Name as CompanyName
            
           FROM    
               ARTL with (NOLOCK)    
               JOIN ARTH ARTH1 with (NOLOCK) ON ARTL.ARCo = ARTH1.ARCo AND ARTL.ApplyMth = ARTH1.Mth AND    
                ARTL.ApplyTrans = ARTH1.ARTrans    
JOIN #Open OpenC    
                     ON OpenC.ARCo=ARTL.ARCo and OpenC.ApplyMth=ARTL.ApplyMth and OpenC.ApplyTrans=ARTL.ApplyTrans--changed from select statement 127001    
       
               JOIN HQCO with (NOLOCK) ON ARTL.ARCo = HQCO.HQCo    
               JOIN ARTH with (NOLOCK) ON ARTL.ARCo = ARTH.ARCo AND ARTL.Mth = ARTH.Mth AND ARTL.ARTrans = ARTH.ARTrans    
               JOIN ARCM with (NOLOCK) ON ARTH.CustGroup = ARCM.CustGroup AND ARTH.Customer = ARCM.Customer    
               Left Join JCJM with (NOLOCK) on ARTL.JCCo=JCJM.JCCo and ARTL.Contract=JCJM.Contract and    
						(JCJM.Job=(select min(x.Job) from JCJM x where x.JCCo=ARTL.JCCo and x.Contract=ARTL.Contract))    
               Left Join JCMP with (NOLOCK) on JCMP.JCCo=JCJM.JCCo and JCMP.ProjectMgr=JCJM.ProjectMgr    
               Left Join JCCM with (NOLOCK) on JCCM.JCCo=ARTL.JCCo and ARTL.Contract=JCCM.Contract    
					join #RT RT on RT.ARCo = ARTL.ARCo and RT.RecType = ARTL.RecType--changed from select statement 127001    
      		-- start V1-B-10810
				LEFT JOIN cte_SMInvoiceList SMARTH ON ARTH.ARCo=SMARTH.ARCo AND ARTH.Mth=SMARTH.ARPostedMth AND ARTH.ARTrans=SMARTH.ARTrans  
				LEFT JOIN cte_SMInvoiceList SMARTH1 ON ARTH1.ARCo=SMARTH1.ARCo AND ARTH1.Mth=SMARTH1.ARPostedMth AND ARTH1.ARTrans=SMARTH1.ARTrans 
				LEFT JOIN HQCO c on c.HQCo = ARTL.ARCo  
		-- end V1-B-10810 
         WHERE    
             ARTL.ARCo=@Company AND    
               ARTL.Mth <= @Month AND    
               ARTH1.ARCo=@Company AND    
               ARTH1.Customer >= @BegCust AND    
               ARTH1.Customer <= @EndCust AND    
				isnull(JCJM.ProjectMgr,0) >= @BegPM and    
				isnull(JCJM.ProjectMgr,2147483647) <= @EndPM    
				AND (ARTH.TransDate <= case when ARTH.ARTransType='I' then @IncludeInvoicesThrough  else @IncludeAdjPayThrough end)    
				AND JCCM.Department in (@Department)
           ORDER BY    
               ARTH1.ARCo ASC,    
               ARCM.SortName ASC,    
               case when @AgeOpenCredits='Y' and ((ARTH.ARTransType='P' and ARTL.Mth=ARTL.ApplyMth and    
                   ARTL.ARTrans=ARTL.ApplyTrans) or ARTH1.ARTransType='P')  then  1 else 0 end,    
            
               ARTH1.Invoice,    
               ARTH1.Mth,    
               ARTL.ApplyTrans,    
               ARTH.ARTransType 
GO
