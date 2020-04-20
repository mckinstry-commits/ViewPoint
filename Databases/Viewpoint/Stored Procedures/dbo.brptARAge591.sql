SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.brptARAge591    Script Date: 8/28/99 9:32:27 AM ******/
   --Drop  proc brptARAge591
/* jim is currently working on */
CREATE   proc dbo.brptARAge591 
	(@Company bCompany=1, @Month bMonth='1/1/2049', @AgeDate bDate='1/1/2049',
       	@BegCust bCustomer=0, @EndCust bCustomer=99999999, @RecType varchar(200)=null,
	@IncludeInvoicesThrough bDate='1/1/2049',  @IncludeAdjPayThrough bDate='1/1/2049',
	@AgeOnDueorInv char(1)='D', @LevelofDetail char(1)='I', @DeductDisc char(1)='Y', 
	@DaysBetweenCols tinyint=30,@AgeOpenCredits char(1)='N', 
	@BegCustName varchar(15)=' ', @EndCustName varchar(15)='zzzzzzzzzzzzzzz',@Sort char(1)='S')
    
With Recompile 
as
/* 
Mod 6/28/99 TF 
Mod 6/29/99 JE 
Mod 3/21/02 CR Added new field OpenYN - this field will check to see if a customer has an open amount
Mod 11/12/02 CR Added another clause to the OpenYN formula, it was not checking within the Month parameters
Mod 12/11/02 CR Added B/E Customer SortName parameters. Issue 19160
Mod 1/21/03 CR Added @Sort, Sort and Order by Sort. Issue 19160
Mod 4/2/03 E.T. fixed to make ansii standard for Crystal 9.0 fixed : =Null, Contcatination & notes. Issue #20721 
   Mod 7/21/03  issue not created yet....added NOLOCKS to the From Clause CR
   Mod 8/8/03 DH Issue 22103.  Added With Recompile and remmed out order by clause 
   Mod 12/16/03 CR Issue 22977  removed the OPENYN field and added a Join select stmt to return only open transactions 
*/
-- add index biARTHCustomer on bARTH (ARCo,Customer,Mth,ARTrans)

set nocount on

declare @hqcoinfo as varchar(132)


-- read co info only once - eliminates an extra join 

select @hqcoinfo=convert(varchar(3),HQCO.HQCo)+' '+IsNull(HQCO.Name,'')
	from HQCO with (nolock)
	where HQCo=@Company

-- reset the receivable type to be used for a charindex
-- ensure each value is surrounded by commas for example 1,2,3  becomes ,1,2,3,
if @RecType in (null,'')
begin
	select @RecType = null
end
else
begin
	select @RecType = ',' + @RecType + ','
end
    
set nocount off 

-- select the data
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
AgeAmount=sum(Case when @DeductDisc='Y' then isnull(ARTL.Amount,0)-isnull(ARTL.DiscOffered,0)-isnull(ARTL.Retainage,0)
	else isnull(ARTL.Amount,0)-isnull(ARTL.Retainage,0) end)-0,
Amount=sum(isnull(ARTL.Amount,0)-0),
Retainage=sum(isnull(ARTL.Retainage,0)-0),
DiscOffered=sum(ARTL.DiscOffered-0),
ARTL.ApplyMth, ARTL.ApplyTrans, 
ARTH.ARCo, ARTH.ARTrans, ARTH.ARTransType,ARTH.CustGroup, ARTH.Customer, ARTH.RecType,ARTH.TransDate, 
Description=Max(ARTH.Description), ARTH.AppliedTrans, InvoiceARTransType=ARTH1.ARTransType,
InvoiceContract=isnull(ARTH1.Contract,ARTL.Contract), 
ARTH1.Invoice, 
InvoiceTransDate=ARTH1.TransDate, InvoiceDueDate=ARTH1.DueDate,
InvoiceDiscDate=ARTH1.DiscDate, 
InvoiceDesc=Max(ARTH1.Description), 
Name=Max(ARCM.Name),SortName=Max(ARCM.SortName), Phone=Max(ARCM.Phone),
Contact=Max(ARCM.Contact), StmntPrint=Max(ARCM.StmntPrint),
    
DateDesc=case when @AgeOnDueorInv='D' then 'Due Date' else  'Inv Date' end,
LineDateDesc=case when @AgeOnDueorInv='D' and @LevelofDetail='I' then 'Due Date'
	when @AgeOnDueorInv='I' and @LevelofDetail='I' then 'Inv Date'
	else 'Tran Date' end,
Over1Desc=convert(varchar(3),@DaysBetweenCols+1)+'-'+convert(varchar(3),@DaysBetweenCols*2),
Over2Desc=convert(varchar(3),(@DaysBetweenCols*2)+1)+'-'+convert(varchar(3),@DaysBetweenCols*3),
Over3Desc='Over '+convert(varchar(3),@DaysBetweenCols*3),
Sort=case when @Sort = 'N' then Right('000000'+convert(varchar(6),ARTH1.Customer),6)+ARCM.SortName else ARCM.SortName end,
PrintCompany= @hqcoinfo,
ParamMonth=@Month,
ParamAgeDate=@AgeDate,
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
ParamBegCustName=Case when @BegCustName=' ' then 'First' else @BegCustName end,
ParamEndCustName=Case when @EndCustName='zzzzzzzzzzzzzzz' then 'Last' else @EndCustName end,
NonInvCN=max(CN1.NonInvCN),
InvCN=max(CN2.InvCN)
   

FROM
	ARTL with (NOLOCK)
	JOIN ARTH ARTH1 with (NOLOCK)ON ARTL.ARCo = ARTH1.ARCo AND ARTL.ApplyMth = ARTH1.Mth AND
          	 ARTL.ApplyTrans = ARTH1.ARTrans
	JOIN (Select ARTL.ARCo, ApplyMth, ApplyTrans From ARTL with (NOLOCK)
		Join ARTH on ARTH.ARCo=ARTL.ARCo and ARTH.Mth=ARTL.Mth and ARTH.ARTrans=ARTL.ARTrans
		Where ARTL.Mth<=@Month and ARTH.TransDate <= case when ARTH.ARTransType='I' then @IncludeInvoicesThrough  else @IncludeAdjPayThrough end
		Group By ARTL.ARCo, ApplyMth, ApplyTrans having sum(ARTL.Retainage)<>0 or sum(ARTL.Amount)<>0) as OpenC
		ON OpenC.ARCo=ARTL.ARCo and OpenC.ApplyMth=ARTL.ApplyMth and OpenC.ApplyTrans=ARTL.ApplyTrans
	--JOIN HQCO with (NOLOCK) ON ARTL.ARCo = HQCO.HQCo
	JOIN ARTH with (NOLOCK) ON ARTL.ARCo = ARTH.ARCo AND ARTL.Mth = ARTH.Mth AND ARTL.ARTrans = ARTH.ARTrans
	JOIN ARCM with (NOLOCK) ON ARTH.CustGroup = ARCM.CustGroup AND ARTH.Customer = ARCM.Customer

/* get customer notes */
   	Left Join (Select ARCN.CustGroup,ARCN.Customer,NonInvCN=Count(ARCN.Customer)
  		 From ARCN with (NOLOCK)
		 Where isnull(ARCN.Invoice,'')= ''
   		 Group By ARCN.CustGroup,ARCN.Customer) CN1
                 On ARTH.CustGroup = CN1.CustGroup and ARTH.Customer =CN1.Customer


   	Left Join (Select ARCN.CustGroup,ARCN.Customer,ARCN.Invoice,InvCN=Count(ARCN.Customer)
		From ARCN with (NOLOCK)
		Where ARCN.Invoice Is Not Null -- and ARTH.Contract Is Not Null   --JF Test
		Group By ARCN.CustGroup,ARCN.Customer,ARCN.Invoice) CN2 
		On ARTH.CustGroup=CN2.CustGroup and ARTH.Customer=CN2.Customer and ARTH.Invoice=CN2.Invoice

/* Where */
WHERE
	ARTL.ARCo=@Company
	AND ARTL.Mth <= @Month
	AND ARTH1.ARCo=@Company
	AND ARTH1.Customer >= @BegCust
	AND ARTH1.Customer <= @EndCust
	AND ARCM.SortName >= @BegCustName
	AND ARCM.SortName <= @EndCustName
           /* ARCM.StmntPrint = 'Y' AND */
	AND (@RecType is null or CHARINDEX(','+convert(varchar(3),ARTL.RecType)+',',@RecType)>0)
	AND ARTH.TransDate <= case when ARTH.ARTransType='I' then @IncludeInvoicesThrough  else @IncludeAdjPayThrough end
    
group by ARTL.Mth, ARTL.ARTrans, ARTL.RecType,
	ARTH1.TransDate,ARTH1.DueDate,
	ARTH.ARTransType,ARTL.ApplyMth ,ARTL.ApplyTrans,
	ARTH.ARCo, ARTH.ARTrans, ARTH.ARTransType,ARTH.CustGroup, ARTH.Customer, ARTH.RecType,
	ARTH.TransDate, ARTH.AppliedTrans, ARTH1.ARTransType,
	isnull(ARTH1.Contract,ARTL.Contract), ARTH1.Invoice, ARTH1.TransDate, ARTH1.DueDate,
	ARTH1.DiscDate,	ARTH1.Customer, ARCM.SortName
GO
GRANT EXECUTE ON  [dbo].[brptARAge591] TO [public]
GO
