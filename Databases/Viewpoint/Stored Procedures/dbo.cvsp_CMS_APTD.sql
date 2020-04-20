
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE proc [dbo].[cvsp_CMS_APTD] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as



/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		AP Transaction Detail (APTD)
	Created:	10.12.09
	Created by:	JJH    
	Revisions:	1. None
				2.  Added Discount Taken, only used once 
	Notes:		For partial payments, it creates multiple sequences in APTD and flags as paid.
				CMS doesn't detail the partial payments by line so the amounts are allocated by line in order to record
				the payments properly in APTD.
				At the end, the amounts are adjusted for any rounding errors that may occur 
				in separating totals into line amounts.
				Separate stored procedure runs after this to insert a record into APTD for all unpaid invoices.
**/



set @errmsg=''
set @rowcount=0


-- get vendor group from HQCO
declare @VendorGroup smallint
select @VendorGroup=VendorGroup from bHQCO where HQCo=@toco

--get defaults from APCO
declare @exppaytype tinyint, @jobpaytype tinyint, @subpaytype tinyint,@CMCo tinyint, @CMAcct int
select @exppaytype=ExpPayType, @jobpaytype=JobPayType, @subpaytype=SubPayType,
	@CMCo=CMCo, @CMAcct=CMAcct
from bAPCO where APCo=@toco;

ALTER Table bAPTD disable trigger all;

-- delete existing trans
BEGIN tran
delete from bAPTD where APCo=@toco
	--and udConv = 'Y';
COMMIT TRAN;

-- add new trans
BEGIN TRAN
BEGIN TRY


insert into bAPTD(APCo, Mth, APTrans, APLine, APSeq, PayType, Amount, DiscOffer,
	DiscTaken, DueDate, Status, PaidMth, PaidDate, CMCo, CMAcct, PayMethod, CMRef, CMRefSeq,
	EFTSeq, VendorGroup, Supplier, PayCategory, TotTaxAmount, udYSN, 
	udRCCD, udTotalChkAmt, udMultiPay, udRetgHistory,udSource,udConv,udCGCTable,udCGCTableID)

select APCo=@toco
	,Mth=l.udMth
		--isnull(substring(convert(nvarchar(max),h.JOURNALDATE),5,2) + '/01/' +  substring(convert(nvarchar(max),h.JOURNALDATE),1,4),
		--substring(convert(nvarchar(max),l.JOURNALDATE),5,2) + '/01/' +  substring(convert(nvarchar(max),l.JOURNALDATE),1,4))
	,APTrans=l.udAPTrans
		--convert(nvarchar(max),l.PAYMENTSELNO) + convert(nvarchar(max),l.RECORDCODE) 
	,APLine=l.SEQUENCENO03
	,APSeq=ROW_NUMBER() OVER (PARTITION BY l.COMPANYNUMBER, l.DIVISIONNUMBER, l.VENDORNUMBER, l.PAYMENTSELNO, l.SEQUENCENO03, l.RECORDCODE
			ORDER BY l.COMPANYNUMBER, l.DIVISIONNUMBER, l.VENDORNUMBER, l.PAYMENTSELNO)
	,PayType=case when l.JOBNUMBER='' then @exppaytype 
				when l.JOBNUMBER<>'' and l.CONTRACTNO<>0 then @subpaytype 
				else @jobpaytype end
	,Amount=round(case when isnull(t.ChkCount,0)=1 then 
					case when l.STATUSCODE='A' and linecnt.TotalAmt>0 then l.PARTPAYAMTTD else 
							--eliminate counting check 2x on where FSTAT=A with unpaid lines.
						case when l.PARTPAYAMTTD=0 and l.GROSSAMT<>0 then 
								case when h.RECORDCODE=4 then l.GROSSAMT else h.PARTPAYAMTTD end
						else l.PARTPAYAMTTD end 
					end
			else l.PARTPAYAMTTD*isnull(d.Pct,1) end,2)
	,DiscOffer=disc.DISCtaken
	,DiscTaken=disc.DISCtaken
	,DueDate=isnull(substring(convert(nvarchar(max),h.DUEDATE),5,2) + '/' +  substring(convert(nvarchar(max),h.DUEDATE),7,2) + '/' + 
		substring(convert(nvarchar(max),h.DUEDATE),1,4),
		substring(convert(nvarchar(max),l.JOURNALDATE),5,2) + '/' +  substring(convert(nvarchar(max),l.JOURNALDATE),7,2) + '/' + 
		substring(convert(nvarchar(max),l.JOURNALDATE),1,4))
	,Status=3 --1=open, 2=Hold, 3=Paid= 4=Clear
	,PaidMth=substring(convert(nvarchar(max),d.CHECKDATE),5,2) + '/01/' +  
		substring(convert(nvarchar(max),d.CHECKDATE),1,4)
	,PaidDate=substring(convert(nvarchar(max),d.CHECKDATE),5,2) + '/' +  substring(convert(nvarchar(max),d.CHECKDATE),7,2) + '/' + 
		substring(convert(nvarchar(max),d.CHECKDATE),1,4)
	,CMCo=@CMCo
	,CMAcct=@CMAcct
	,PayMethod='C'
	,CMRef=space(10-datalength(rtrim(d.CHECKNUMBER))) + rtrim(d.CHECKNUMBER) 
	,CMRefSeq=0
	,EFTSeq=0
	,@VendorGroup
	,Supplier= case when d.Supp=0 then Null else d.Supp end
	,PayCategory=null 
	,TotTaxAmount=0
	,udYSN=d.PAYMENTSELNO
	,udRCCD=d.RECORDCODE
	,udTotalChkAmt=d.Amt
	,udMultiPay=case when d.Pct<>1 then 'Y' else 'N' end
	,udRetgHistory='N'
	,'APTD'
	, udConv='Y'
	,udCGCTable='APTOPD'
	,udCGCTableID=l.APTOPDID
from CV_CMS_SOURCE.dbo.APTOPD l
	left join CV_CMS_SOURCE.dbo.APTOPC h on l.COMPANYNUMBER=h.COMPANYNUMBER and l.DIVISIONNUMBER=h.DIVISIONNUMBER 
		and l.VENDORNUMBER=h.VENDORNUMBER and l.PAYMENTSELNO=h.PAYMENTSELNO and l.JOURNALDATE=h.JOURNALDATE
		and l.RECORDCODE=h.RECORDCODE
	--see if a record 4 type exists - used in where clause below
	left join CV_CMS_SOURCE.dbo.APTOPC h2 on l.COMPANYNUMBER=h2.COMPANYNUMBER and l.DIVISIONNUMBER=h2.DIVISIONNUMBER 
		and l.VENDORNUMBER=h2.VENDORNUMBER and l.PAYMENTSELNO=h2.PAYMENTSELNO and l.JOURNALDATE=h2.JOURNALDATE
		and h2.RECORDCODE=4
	--1. Used to figure out which amount to pull on multiple line invoices that are partially paid
	left join (select distinct COMPANYNUMBER, DIVISIONNUMBER, VENDORNUMBER, PAYMENTSELNO, LineCnt=count(SEQUENCENO03), 
					TotalAmt=sum(GROSSAMT)
				from CV_CMS_SOURCE.dbo.APTOPD
				group by COMPANYNUMBER, DIVISIONNUMBER, VENDORNUMBER, PAYMENTSELNO) 
				as linecnt
				on l.COMPANYNUMBER=linecnt.COMPANYNUMBER and l.DIVISIONNUMBER=linecnt.DIVISIONNUMBER 
					and l.VENDORNUMBER=linecnt.VENDORNUMBER and l.PAYMENTSELNO=linecnt.PAYMENTSELNO
	--2. The following is used to allocate partial payments across multiple invoice lines since CMS does not break payments down
		--by line.
	left join (select COMPANYNUMBER, DIVISIONNUMBER, VENDORNUMBER, PAYMENTSELNO, 
				RECORDCODE, CHECKNUMBER, Supp=max(LIENORNUMBER),
				CHECKDATE=CASHDISBDATE, Amt=sum(CHECKAMT),
				Pct=case when (select sum(CHECKAMT) from CV_CMS_SOURCE.dbo.APTHCK x where APTHCK.COMPANYNUMBER=x.COMPANYNUMBER and
							APTHCK.DIVISIONNUMBER=x.DIVISIONNUMBER and APTHCK.VENDORNUMBER=x.VENDORNUMBER 
							and APTHCK.PAYMENTSELNO=x.PAYMENTSELNO and APTHCK.RECORDCODE=x.RECORDCODE)=0 
						then 0 
						else sum(CHECKAMT) / 
							(select sum(CHECKAMT) from CV_CMS_SOURCE.dbo.APTHCK x where APTHCK.COMPANYNUMBER=x.COMPANYNUMBER and
							APTHCK.DIVISIONNUMBER=x.DIVISIONNUMBER and APTHCK.VENDORNUMBER=x.VENDORNUMBER 
							and APTHCK.PAYMENTSELNO=x.PAYMENTSELNO 
							and APTHCK.RECORDCODE=x.RECORDCODE) 
						end
				from CV_CMS_SOURCE.dbo.APTHCK APTHCK
				where COMPANYNUMBER=@fromco
				group by COMPANYNUMBER, DIVISIONNUMBER, VENDORNUMBER, PAYMENTSELNO, RECORDCODE, CHECKNUMBER,CASHDISBDATE)
				as d
				on d.COMPANYNUMBER=l.COMPANYNUMBER and d.DIVISIONNUMBER=l.DIVISIONNUMBER 
					and d.VENDORNUMBER=l.VENDORNUMBER and d.PAYMENTSELNO=l.PAYMENTSELNO
					and (case when d.RECORDCODE=2 then 1 else d.RECORDCODE end)=l.RECORDCODE
	--3. Used to figure out where to pull amounts from.  Combined with the statement (1) above in a case statement
	left join (select distinct COMPANYNUMBER, DIVISIONNUMBER, VENDORNUMBER, PAYMENTSELNO, ChkCount=count(CHECKNUMBER)
				from CV_CMS_SOURCE.dbo.APTHCK 
				where COMPANYNUMBER=@fromco
				group by COMPANYNUMBER, DIVISIONNUMBER, VENDORNUMBER, PAYMENTSELNO)
				as t
				on t.COMPANYNUMBER=l.COMPANYNUMBER and t.DIVISIONNUMBER=l.DIVISIONNUMBER 
					and t.VENDORNUMBER=l.VENDORNUMBER and t.PAYMENTSELNO=l.PAYMENTSELNO
					

	--4.  Used to find Discounts taken  (used at KEG  -- modify DiscountTaken to be disc.DISCtaken )
	
	left join (select COMPANYNUMBER, DIVISIONNUMBER, VENDORNUMBER, PAYMENTSELNO, SEQUENCENO03,
	DISCtaken=sum(DISCOUNTAMT)
	from CV_CMS_SOURCE.dbo.APTOPD
	group by COMPANYNUMBER, DIVISIONNUMBER, VENDORNUMBER, PAYMENTSELNO, SEQUENCENO03)
	as disc
	on l.COMPANYNUMBER=disc.COMPANYNUMBER and l.DIVISIONNUMBER=disc.DIVISIONNUMBER
		and l.VENDORNUMBER=disc.VENDORNUMBER and l.PAYMENTSELNO=disc.PAYMENTSELNO
		and l.SEQUENCENO03 = disc.SEQUENCENO03
	
					
					
					
	join bHQCO HQCO on HQCO.HQCo=@toco
where d.CHECKNUMBER <> 0--is not null -- only pull records that have a payment issued
	and l.COMPANYNUMBER=@fromco
	and (case when h2.RECORDCODE is null then l.GROSSAMT else h.GROSSAMT end)=l.GROSSAMT 
			--record type 4 records affect the amounts in the different tables so this is checking
			--to see if a record type 4 exists.  If so, it's making sure that the amounts match in order to eliminate
			--counting a check 2x for a record with 2 headers.

select @rowcount=@@rowcount;

COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;


ALTER Table bAPTD enable trigger all;

return @@error



GO
