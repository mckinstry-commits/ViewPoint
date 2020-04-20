USE [Viewpoint]
GO

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='PROCEDURE' and ROUTINE_NAME='msp_brptARAge')
begin
	print 'DROP PROCEDURE mers.msp_brptARAge'
	DROP PROCEDURE mers.msp_brptARAge
end
go

print 'CREATE PROCEDURE mers.msp_brptARAge'
go

CREATE  proc mers.msp_brptARAge 
(
	@Company bCompany=1
,	@Month bMonth='1/1/2049'
,	@AgeDate bDate='1/1/2049'
,	@BegCust bCustomer=0
,	@EndCust bCustomer=99999999
,	@RecType varchar(200)=NULL    
,	@IncludeInvoicesThrough bDate='1/1/2049'
,	@IncludeAdjPayThrough bDate='1/1/2049'
,	@AgeOnDueorInv char(1)='D'
,	@LevelofDetail char(1)='I'
,	@DeductDisc char(1)='Y'
,	@DaysBetweenCols tinyint=30
,	@AgeOpenCredits char(1)='N'
,	@BegCustName varchar(15)=' '
,	@EndCustName varchar(15)='zzzzzzzzzzzzzzz'
,	@Sort char(1)='S'
)    
as    
/* Mod 6/28/99 TF */    
	/* Mod 6/29/99 JE */    
	/* Mod 3/21/02 CR Added new field OpenYN - this field will check to see if a customer has an open amount*/    
	/* Mod 11/12/02 CR Added another clause to the OpenYN formula, it was not checking within the Month parameters */    
	/* Mod 12/11/02 CR Added B/E Customer SortName parameters. Issue 19160 */    
	/* Mod 1/21/03 CR Added @Sort, Sort and Order by Sort. Issue 19160 */    
	/* Mod 4/2/03 E.T. fixed to make ansii standard for Crystal 9.0 fixed : =Null, Contcatination & notes. Issue #20721     
	Mod 7/21/03  issue not created yet....added NOLOCKS to the From Clause CR    
	Mod 8/8/03 DH Issue 22103.  Added With Recompile and remmed out order by clause     
	Mod 12/16/03 CR Issue 22977  removed the OPENYN field and added a Join select stmt to return only open transactions */    
	/* Issue 25859 add with (nolock) DW 10/22/04    
	Mod 2/23/05 CR Issue 26960  added Company to the LastCheckDate sub query       
	Mod 3/22/06 CR Issue 120491 removed ARTH from #CN2 temp table       
	Mod 10/18/07 cr ISSUE 125713 added new RecType derived table    
	Mod 4/28/09  DH ISSUE 128663.  Added temp table for receivable types and open trans only    
	Mod 08/30/2012 ScottAlvey CL-###### / V1-B-10810 AR Customer and Aging Reports - not showing SM    Invoice description / added cte to get just Invoiced invoices from SM and the left joined it twice   ,once to ARTH and another to ARTH1.    
	Mod 09/10/2013 DML - Added HQCO.DefaultCountry, ARCO.TaxRetg and ARCO.SeparateRetgTax to select statement. 
	JayR 11/20/2013 Add in a drop before creation.    
*/    
    
set nocount on  

--COLLECTION NOTES - Non-Invocie  
create table #CN1    
(
	CustGroup tinyint null    
,	Customer int null
,	NonInvCN int NULL
)    

Insert into #CN1    
(
	CustGroup
,	Customer
,	NonInvCN
)    
Select 
	ARCM.CustGroup
,	ARCM.Customer
,	Count(ARCN.Customer)    
From 
	ARCM ARCM with(nolock)    
	Inner Join ARCN with(nolock) On 
	ARCM.CustGroup = ARCN.CustGroup 
and ARCM.Customer = ARCN.Customer    
Where 
	ARCN.Invoice is Null or ARCN.Invoice = ''    
Group By 
	ARCM.CustGroup
,	ARCM.Customer    
       
create clustered index btCN1 on #CN1 (CustGroup, Customer)    
 
 
--COLLECTION NOTES - Invocie       
create table #CN2    
(
	CustGroup tinyint NULL
,	Customer int NULL
,   Invoice Char(10) NULL
,   InvCN int NULL
)
    
Insert into #CN2    
(
	CustGroup
	,Customer
	,Invoice
	,InvCN
)    
Select 
	ARCN.CustGroup
,	ARCN.Customer
,	ARCN.Invoice
,	Count(ARCN.Customer)    
From 
	ARCN with(nolock)    
--Inner Join ARCN with(nolock) On ARTH.CustGroup = ARCN.CustGroup and ARTH.Customer = ARCN.Customer and ARTH.Invoice = ARCN.Invoice    
Where 
	ARCN.Invoice Is Not Null   --and ARTH.Contract Is Not Null       
Group By 
	ARCN.CustGroup
,	ARCN.Customer
,	ARCN.Invoice    
          
create clustered index btCN2 on #CN2 (CustGroup,Customer,Invoice)    
             

if @RecType in (null,'')    
begin    
	select @RecType = null    
end    
else    
begin    
	select @RecType = ',' + @RecType + ','    
    --select @RecType =  @RecType + ','    
end    
   
/*Temp Table to store selected receivable types    
Temp Table joined to main select statement    
*/    
create table #RT    
(
	ARCo  tinyint  null 
,	RecType int  NULL
)    
    
/*Temp Table to store open transactions.  Joined to main select statement*/    
    
create table #Open    
(
	ARCo   tinyint  null   
,	ApplyMth smalldatetime null 
,	ApplyTrans int  NULL
)    
    
    
/*Insert receivable types selected by user at runtime*/    
    
insert into #RT 
(
	ARCo
,	RecType
)    
select 
	ARRT.ARCo
,	ARRT.RecType /*into RT*/     
from 
	ARRT with (nolock)    
where ARRT.ARCo = @Company and (@RecType is null or CHARINDEX(','+convert(varchar(3),ARRT.RecType)+',',@RecType)>0)    

    
insert into #Open 
(	
	ARCo
,	ApplyMth
,	ApplyTrans
)    
Select 
	ARTL.ARCo
,	ApplyMth
,	ApplyTrans 
From 
	ARTL     
	Join ARTH on 
	ARTH.ARCo=ARTL.ARCo 
and ARTH.Mth=ARTL.Mth 
and ARTH.ARTrans=ARTL.ARTrans    
Where 
	ARTL.Mth<=@Month 
and ARTH.TransDate <= case when ARTH.ARTransType='I' then @IncludeInvoicesThrough  else @IncludeAdjPayThrough end    
Group By 
	ARTL.ARCo
,	ApplyMth
,	ApplyTrans 
having sum(ARTL.Retainage)<>0 or sum(ARTL.Amount)<>0    
    
        
set nocount off;    
       
-- start V1-B-10810    
       
with cte_SMInvoiceList    
as    

(    
	select    
		ARCo     
	,	ARPostedMth     
	,	ARTrans     
	,	DescriptionOfWork    
	,	InvoiceStatus    
	from    
		SMInvoiceList    
	where    
	InvoiceStatus = 'Invoiced'    
)        
    
-- end V1-B-10810    
       
       
SELECT    
	ARTL.Mth
,	ARTL.ARTrans
,	ARTL.RecType    
,	AgeDate=
		case 
			when @AgeOnDueorInv='I' then ARTH1.TransDate 
			else isnull(ARTH1.DueDate,ARTH1.TransDate) 
		END
,   DaysFromAge= 
		case 
			when @AgeOnDueorInv='I' then DATEDIFF(day, ARTH1.TransDate, @AgeDate) 
			else DATEDIFF(day,isnull(ARTH1.DueDate,ARTH1.TransDate), @AgeDate) 
		END
,   OpenPaymentFlag=
		case 
			when		@AgeOpenCredits='Y' 
					and ((ARTH.ARTransType='P' and ARTL.Mth=ARTL.ApplyMth and  ARTL.ARTrans=ARTL.ApplyTrans) 
					or ARTH1.ARTransType='P') then  1 
		else 0 
		end    
,	AgeAmount=
		(Case 
			when @DeductDisc='Y' then isnull(ARTL.Amount,0)-isnull(ARTL.DiscOffered,0)-isnull(ARTL.Retainage,0)    
			else isnull(ARTL.Amount,0)-isnull(ARTL.Retainage,0) 
		end)-0
,	Amount=isnull(ARTL.Amount,0)-0
,	Retainage=isnull(ARTL.Retainage,0)-0
,	DiscOffered=ARTL.DiscOffered-0   
,	ARTL.ApplyMth
,	ARTL.ApplyTrans
,	ARTH.ARCo
,	ARTH.ARTrans
,	ARTH.ARTransType
,	ARTH.CustGroup
,	ARTH.Customer
,	ARTH.RecType
,	ARTH.TransDate     
--, ARTH.Description    
,	case --V1-B-10810
		when ARTH.Source = 'SM Invoice' then SMARTH.DescriptionOfWork    
		else ARTH.Description      
	end as Description    
,	ARTH.AppliedTrans
,	InvoiceARTransType=ARTH1.ARTransType
,	InvoiceContract=isnull(ARTH1.Contract,ARTL.Contract)
,	ARTH1.Invoice
,	InvoiceTransDate=ARTH1.TransDate
,	InvoiceDueDate=ARTH1.DueDate   
,	InvoiceDiscDate=ARTH1.DiscDate     
--,	InvoiceDesc=ARTH1.Description    
,	case --V1-B-10810 
		when ARTH1.Source = 'SM Invoice' then SMARTH1.DescriptionOfWork    
		else ARTH1.Description      
		end as InvoiceDesc   
,	ARCM.Name
,	ARCM.SortName
,	ARCM.Phone
,	ARCM.Contact
,	ARCM.StmntPrint
,	ARCM.ContactExt
,	DateDesc=
		case 
			when @AgeOnDueorInv='D' then 'Due Date' 
			else  'Inv Date' 
		end    
,	LineDateDesc=
		case 
			when @AgeOnDueorInv='D' and @LevelofDetail='I' then 'Due Date'    
			when @AgeOnDueorInv='I' and @LevelofDetail='I' then 'Inv Date'    
			else 'Tran Date'
		END    
,	Over1Desc=convert(varchar(3),@DaysBetweenCols+1)+'-'+convert(varchar(3),@DaysBetweenCols*2)
,	Over2Desc=convert(varchar(3),(@DaysBetweenCols*2)+1)+'-'+convert(varchar(3),@DaysBetweenCols*3)
,	Over3Desc='Over '+convert(varchar(3),@DaysBetweenCols*3)
,	LastCheckDate = 
		(
			select 
				Max(a.TransDate) 
			from 
				ARTH a with(nolock) 
			where 
				a.ARTransType = 'P' 
			and a.Customer = ARTH.Customer 
			AND	a.Mth<=@Month 
			and a.TransDate <=@IncludeAdjPayThrough 
			and a.ARCo = ARTH.ARCo
		)

--OpenYN=case when (select sum(I.Amount)+sum(I.Retainage) From ARTL I    
--where I.ARCo=ARTL.ARCo and I.ApplyMth=ARTL.Mth and I.ApplyTrans=ARTL.ARTrans and I.Mth<=@Month    
--and ARTH.TransDate <= case when ARTH.ARTransType='I' then @IncludeInvoicesThrough  else @IncludeAdjPayThrough end) <> 0    
--Then 'Y' Else 'N' end,    

,	Sort=
		case 
			when @Sort = 'N' then Right('000000'+convert(varchar(6),ARTH1.Customer),6)+ARCM.SortName 
			else ARCM.SortName 
		END
,	CheckDescription=ARTL.Description    
,	PrintCompany= convert(varchar(3),HQCO.HQCo)+' '+IsNull(HQCO.Name,'')   
,	ParamMonth=@Month    
,	ParamAgeDate=@AgeDate    
,	ParamBegCust=Case when @BegCust=0 then 'First' else convert(varchar(8),@BegCust) end    
,	ParamEndCust=Case when @EndCust=99999999 then 'Last' else convert(varchar(8),@EndCust) end    
,	ParamRecType=Case when @RecType is null then 'All' else @RecType end    
,	ParamIncInvoicesThru=@IncludeInvoicesThrough    
,	ParamInclAdjPayThru=@IncludeAdjPayThrough    
,	ParamAgeOnDueorInv=@AgeOnDueorInv    
,	ParamLevelofDetail=@LevelofDetail    
,	ParamDeductDisc=@DeductDisc    
,	ParamDaysBetweenCols=@DaysBetweenCols    
,	ParamAgeOpenCredits=@AgeOpenCredits    
,	ParamBegCustName=Case when @BegCustName=' ' then 'First' else @BegCustName end    
,	ParamEndCustName=Case when @EndCustName='zzzzzzzzzzzzzzz' then 'Last' else @EndCustName end   
,	HQCO.DefaultCountry		--Added DML 09/10/2013 
,	ARCO.TaxRetg			--Added DML 09/10/2013
,	ARCO.SeparateRetgTax	--Added DML 09/10/2013
,	#CN1.NonInvCN    
,	#CN2.InvCN/*    
InvoiceNotes=ARTH1.Notes*/   
,	ARTL.udSMWorkOrderID
,	ARTL.JCCo
,	ARTL.Contract
,	ARTL.Item
,	ARTL.Job 
,	ARTL.PhaseGroup
,	ARTL.Phase
,	ARTL.CostType
FROM    
	ARTL with (NOLOCK)    
	JOIN ARTH ARTH1 with (NOLOCK) ON 
		ARTL.ARCo = ARTH1.ARCo 
	AND ARTL.ApplyMth = ARTH1.Mth 
	AND ARTL.ApplyTrans = ARTH1.ARTrans    
	JOIN ARCO with (NOLOCK) ON 
		ARTL.ARCo=ARCO.ARCo --Added DML 09/10/2013
	JOIN #Open OpenC ON 
		OpenC.ARCo=ARTL.ARCo 
	and OpenC.ApplyMth=ARTL.ApplyMth 
	and OpenC.ApplyTrans=ARTL.ApplyTrans    
	/*JOIN (Select ARTL.ARCo, ApplyMth, ApplyTrans From ARTL with(nolock)    
	Join ARTH with(nolock) on ARTH.ARCo=ARTL.ARCo and ARTH.Mth=ARTL.Mth and ARTH.ARTrans=ARTL.ARTrans    
	Where ARTL.Mth<=@Month and ARTH.TransDate <= case when ARTH.ARTransType='I' then @IncludeInvoicesThrough  else @IncludeAdjPayThrough end    
	Group By ARTL.ARCo, ApplyMth, ApplyTrans having sum(ARTL.Retainage)<>0 or sum(ARTL.Amount)<>0) as OpenC    
	ON OpenC.ARCo=ARTL.ARCo and OpenC.ApplyMth=ARTL.ApplyMth and OpenC.ApplyTrans=ARTL.ApplyTrans*/    
	JOIN HQCO with (NOLOCK) ON 
		ARTL.ARCo = HQCO.HQCo    
	JOIN ARTH with (NOLOCK) ON 
		ARTL.ARCo = ARTH.ARCo 
	AND ARTL.Mth = ARTH.Mth 
	AND ARTL.ARTrans = ARTH.ARTrans    
	JOIN ARCM with (NOLOCK) ON 
		ARTH.CustGroup = ARCM.CustGroup 
	AND ARTH.Customer = ARCM.Customer    
	join #RT RT on 
		RT.ARCo = ARTL.ARCo 
	and RT.RecType = ARTL.RecType    
	Left Join #CN1 On 
		ARTH.CustGroup = #CN1.CustGroup 
	and ARTH.Customer = #CN1.Customer    
	Left Join #CN2 On 
		ARTH.CustGroup = #CN2.CustGroup 
	and ARTH.Customer = #CN2.Customer 
	and ARTH.Invoice = #CN2.Invoice    
	--125713    
	/*inner join (select ARRT.ARCo, ARRT.RecType from ARRT with (nolock)    
	where ARRT.ARCo = @Company and (@RecType is null or CHARINDEX(','+convert(varchar(3),ARRT.RecType)+',',@RecType)>0))    
	as RT on RT.ARCo = ARTL.ARCo and RT.RecType = ARTL.RecType*/    
	--125053 ??    
	--Left Join (select ARCo, Customer, LastCheckDate = Max(TransDate) from ARTH    
	--where ARTH.ARTransType = 'P' and ARTH.ARCo=@Company and    
	--ARTH.Mth<=@Month and ARTH.TransDate <=@IncludeAdjPayThrough    
	--group by ARCo, Customer) a on a.ARCo=ARTH.ARCo and a.Customer = ARTH.Customer    
	-- start V1-B-10810    
	LEFT JOIN cte_SMInvoiceList SMARTH ON     
		ARTH.ARCo=SMARTH.ARCo     
	AND ARTH.Mth=SMARTH.ARPostedMth     
	AND ARTH.ARTrans=SMARTH.ARTrans      
	LEFT JOIN cte_SMInvoiceList SMARTH1 ON     
		ARTH1.ARCo=SMARTH1.ARCo     
	AND ARTH1.Mth=SMARTH1.ARPostedMth     
	AND ARTH1.ARTrans=SMARTH1.ARTrans     
-- end V1-B-10810     
WHERE    
	ARTL.ARCo=@Company     
AND	ARTL.Mth <= @Month     
AND	ARTH1.ARCo=@Company     
AND	ARTH1.Customer >= @BegCust     
AND	ARTH1.Customer <= @EndCust     
AND	ARCM.SortName >= @BegCustName     
AND	ARCM.SortName <= @EndCustName --AND    
--(@RecType is null or CHARINDEX(','+convert(varchar(3),ARTL.RecType)+',',@RecType)>0) moved to derived table    
AND ARTH.TransDate <= case when ARTH.ARTransType='I' then @IncludeInvoicesThrough  else @IncludeAdjPayThrough end    
           
/*ORDER BY    
    ARTH1.ARCo ASC,    
    --ARTH1.Customer ASC,    
    case when @Sort = 'N' then Right('000000'+convert(varchar(6),ARTH1.Customer),6) else ARCM.SortName end,     
case when @AgeOpenCredits='Y' and ((ARTH.ARTransType='P' and ARTL.Mth=ARTL.ApplyMth and    
        ARTL.ARTrans=ARTL.ApplyTrans) or ARTH1.ARTransType='P')  then  1 else 0 end,    
    ARTH1.Invoice,    
    ARTH1.Mth,    
    ARTL.ApplyTrans,    
    ARTH.ARTransType*/    
GO

GRANT EXEC ON mers.msp_brptARAge TO PUBLIC
GO


--SELECT artl.ApplyMth , artl.* FROM 
--ARTL artl
--JOIN ARTH ARTH1 with (NOLOCK) ON 
--		artl.ARCo = ARTH1.ARCo 
--	AND artl.ApplyMth = ARTH1.Mth 
--	AND artl.ApplyTrans = ARTH1.ARTrans  
--JOIN ARCO with (NOLOCK) ON 
--		artl.ARCo=ARCO.ARCo
--WHERE udSMWorkOrderID IS  NOT NULL




EXEC mers.msp_brptARAge 
	@Company					=	1
,	@Month						=	'2/1/2015'
,	@AgeDate					=	'2/1/2015'
,	@BegCust					=	0 --201291
,	@EndCust					=	999999 --201291
,	@RecType					=	null    
,	@IncludeInvoicesThrough		=	'2/1/2015'
,	@IncludeAdjPayThrough		=	'2/1/2015'
,	@AgeOnDueorInv				=	'D'
,	@LevelofDetail				=	'I'
,	@DeductDisc					=	'Y'
,	@DaysBetweenCols			=	30
,	@AgeOpenCredits				=	'N'
,	@BegCustName				=	' '
,	@EndCustName				=	'zzzzzzzzzzzzzzz'
,	@Sort						=	'S'


--Open Items
--Select 
--	ARTL.ARCo
--,	ApplyMth
--,	ApplyTrans 
--,	ARTL.udSMWorkOrderID
--From 
--	ARTL     
--	Join ARTH on 
--	ARTH.ARCo=ARTL.ARCo 
--and ARTH.Mth=ARTL.Mth 
--and ARTH.ARTrans=ARTL.ARTrans    
--Where 
--	ARTL.Mth<='2/1/2015' 
--and ARTH.TransDate <= case when ARTH.ARTransType='I' then '2/1/2015'  else '2/1/2015' end    
--Group By 
--	ARTL.ARCo
--,	ApplyMth
--,	ApplyTrans 
--,	ARTL.udSMWorkOrderID
--having sum(ARTL.Retainage)<>0 or sum(ARTL.Amount)<>0   
