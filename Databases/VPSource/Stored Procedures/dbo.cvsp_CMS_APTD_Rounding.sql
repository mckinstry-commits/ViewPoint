SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE proc  [dbo].[cvsp_CMS_APTD_Rounding] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as


/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		AP Transaction Detail (APTD) - Adjust for rounding
	Created:	10.13.09
	Created by: JJH    

	Notes:		Part 1 - Since CMS doesn't store partial payments by line, the partial payments are allocated to each line.
					This can cause some rounding variances.
					This stored procedure spins through the APTD records to find any checks where the total in APTD
						does not equal the total check amount from CMS.
					If there is a difference it adjusts the minimum transaction, minimum line in APTD by the rounding
						difference.		

				Part 2 - The following inserts the adjusting records when a transaction's balance 
						has been "written off" in CMS
					These are invoices that have been partially paid and the balance has a FRCCD 
						record type of 4 that removes the remaining balance

				Part 3 - There is one transaction that has different amounts in the header in CMS
						than it does in the lines.  It's the only transaction like this in their
						system.  Manually fixing this one transaction since all others work.

				Part 4 - This clears the entries from part 2.  

				Part 5 - Some transactions are coming over split between CM Accounts.
					They need to all point to the same CM Account.  Then, there are other transactions
					that were paid with the same check that were on 2 accounts.
					This piece updates transactions to be in the same CM Account.

				Part 6 - resolves rounding differences between APTD and APTL
				
	Revisions:	1. 10/26/2012 BTC - Added code to correct zero net transactions with no partial payment records.
					APTL and APTD were not balancing for these records.
				2. 10/26/2012 BTC - Added Sales Tax into APTL to APTD rounding fix
*/


--get defaults from HQCO
declare @VendorGroup tinyint;
select @VendorGroup=VendorGroup from bHQCO where HQCo=@toco;


--Update APTD to correct transactions where the invoice nets to zero and there is one APTD record per line.
--These transactions to this point are converted with zero amounts in APTD but the offsetting amounts exist in APTL.
alter table bAPTD disable trigger all;

update bAPTD set Amount = tl.GrossAmt + case when tl.TaxType=1 then tl.TaxAmt else 0 end
--select *
from bAPTD d
join bAPTL tl
	on tl.APCo=d.APCo and tl.Mth=d.Mth and tl.APTrans=d.APTrans and tl.APLine=d.APLine
join (select APCo, Mth, APTrans, APLine, COUNT(1) as RecordCount, SUM(Amount) as Amount,
			MIN(CMRef) as MinCheck, MAX(CMRef) as MaxCheck from bAPTD
		group by APCo, Mth, APTrans, APLine having COUNT(1)=1 and SUM(Amount)=0 
			and isnull(MIN(CMRef),0) = ISNULL(max(CMRef),0) ) td
	on td.APCo=tl.APCo and td.Mth=tl.Mth and td.APTrans=tl.APTrans and td.APLine=tl.APLine
where tl.GrossAmt + case when tl.TaxType=1 then tl.TaxAmt else 0 end <> td.Amount
	and tl.APCo=@toco;
	
alter table bAPTD enable trigger all;


--rounding adjustments
with rnd as
(
select APTD.APCo, APTD.Vendor, APTD.CMRef, APTD.TotalChk, c.Amt, NewAmt=APTD.TotalChk-c.Amt, a.MinTrans, a.MinLine
from
	(Select APTD.APCo, APTH.Vendor, APTD.CMRef, PaidMth=max(APTD.PaidMth), TotalChk=sum(APTD.Amount)
		from bAPTD APTD
			join bAPTH APTH on APTD.APCo=APTH.APCo and APTD.Mth=APTH.Mth and APTD.APTrans=APTH.APTrans
		where APTD.APCo=@toco
		group by APTD.APCo, APTH.Vendor, APTD.CMRef)
	as APTD
	left join (select APCo=@toco, VENDORNUMBER, CHECKNUMBER, Amt=sum(CHECKAMT)
			from CV_CMS_SOURCE.dbo.APTHCK
			where COMPANYNUMBER=@fromco
			group by COMPANYNUMBER, VENDORNUMBER, CHECKNUMBER) 
			as c
			on APTD.APCo=c.APCo and APTD.Vendor=c.VENDORNUMBER and ltrim(APTD.CMRef)=c.CHECKNUMBER
	left join (select APTD.APCo, APTH.Vendor, APTD.CMRef, APTD.PaidMth, MinTrans=min(APTD.APTrans), 
			MinLine=(select min(a.APLine)
						from bAPTD a 
						where a.APCo=@toco
							and a.APCo=APTD.APCo 
							and a.PaidMth=APTD.PaidMth 
							and a.CMRef=APTD.CMRef
							and a.APTrans=min(APTD.APTrans))
			from bAPTD APTD
				join bAPTH APTH on APTD.APCo=APTH.APCo and APTD.Mth=APTH.Mth and APTD.APTrans=APTH.APTrans
			where APTD.APCo=@toco
			group by APTD.APCo, APTH.Vendor, APTD.CMRef, APTD.PaidMth)
		as a
		on APTD.APCo=a.APCo and APTD.Vendor=a.Vendor and APTD.CMRef=a.CMRef and APTD.PaidMth=a.PaidMth
where APTD.TotalChk<>c.Amt
	and abs(APTD.TotalChk-c.Amt)<=1
)



update bAPTD set Amount=isnull(bAPTD.Amount,0)-isnull(r.NewAmt,0)
from bAPTD
	join bAPTH on bAPTD.APCo=bAPTH.APCo and bAPTD.Mth=bAPTH.Mth and bAPTD.APTrans=bAPTH.APTrans
	join rnd r on bAPTD.APCo=r.APCo and bAPTH.Vendor=r.Vendor and bAPTD.CMRef=r.CMRef 
			and bAPTD.APTrans=r.MinTrans and bAPTD.APLine=r.MinLine
where bAPTD.APCo=@toco




------------------------------------------------------------------------------------

--Cleared balances
alter table bAPTD disable trigger all

insert into bAPTD(APCo, Mth, APTrans, APLine, APSeq, PayType, Amount, DiscOffer,
	DiscTaken, DueDate, Status, PaidMth, PaidDate, CMCo, CMAcct, PayMethod, CMRef, CMRefSeq,
	EFTSeq, VendorGroup, Supplier, PayCategory, TotTaxAmount, udYSN, udRCCD, udTotalChkAmt, udMultiPay
	,udRetgHistory,udSource,udConv,udCGCTable,udCGCTableID)

select @toco
	, Mth=substring(convert(nvarchar(max),h.JOURNALDATE),5,2) + '/01/' +  substring(convert(nvarchar(max),h.JOURNALDATE),1,4)
	, APTrans=convert(nvarchar(max),h.PAYMENTSELNO)+convert(nvarchar(max),h.RECORDCODE)
	, APLine=d.APLine+1
	, APSeq=1
	, PayType=d.PayType
	, Amount=isnull(h.PARTPAYAMTTD,0)-isnull(d.Amt,0)
	, DiscOffer=0
	, DiscTaken=0
	, DueDate=substring(convert(nvarchar(max),h.DUEDATE),5,2) + '/' +  substring(convert(nvarchar(max),h.DUEDATE),7,2) 
			+ '/' + substring(convert(nvarchar(max),h.DUEDATE),1,4)
	, Status=3
	, PaidMth=substring(convert(nvarchar(max),c.CHECKDATE),5,2) + '/01/' +  substring(convert(nvarchar(max),c.CHECKDATE),1,4)
	, PaidDate=substring(convert(nvarchar(max),c.CHECKDATE),5,2) + '/' +  substring(convert(nvarchar(max),c.CHECKDATE),7,2) 
				+ '/' + substring(convert(nvarchar(max),c.CHECKDATE),1,4)
	, CMCo=d.CMCo
	, CMAcct=d.CMAcct
	, PayMethod='C'
	, CMRef=space(10-datalength(rtrim(c.CHECKNUMBER))) + rtrim(c.CHECKNUMBER) 
	, CMRefSeq=0
	, EFTSeq=null
	, VendorGroup=@VendorGroup
	, Supplier=null
	, PayCategory=null
	, TotTaxAmount=0
	, udYSN=h.PAYMENTSELNO
	, udRCCD=h.RECORDCODE
	, udTotalChkAmt=h.PARTPAYAMTTD
	, udMultiPay='N'
	, udRetgHistory='N'
	, udSource='APTD_Rounding'
	, udConv='Y'
	, udCGCTable='APTOPC'
	,udCGCTableID=h.APTOPCID
from CV_CMS_SOURCE.dbo.APTOPC h
	join CV_CMS_SOURCE.dbo.APTOPC h2 on h.COMPANYNUMBER=h2.COMPANYNUMBER and h.VENDORNUMBER=h2.VENDORNUMBER 
			and h.PAYMENTSELNO=h2.PAYMENTSELNO and h2.RECORDCODE=4
	left join (select d.APCo, h.Vendor, d.udYSN, PayType=max(d.PayType), CMCo=max(d.CMCo),
					CMAcct=max(d.CMAcct), Amt=sum(d.Amount), APLine=max(d.APLine)
			from bAPTD d
				join bAPTH h on d.APCo=h.APCo and d.Mth=h.Mth and d.APTrans=h.APTrans
			where d.APCo=@toco
			group by d.APCo, h.Vendor, d.udYSN)
			as d
			on d.APCo=@toco and d.Vendor=h.VENDORNUMBER and d.udYSN=h.PAYMENTSELNO
	left join (select COMPANYNUMBER, VENDORNUMBER, PAYMENTSELNO, CHECKNUMBER=max(CHECKNUMBER), 
					CHECKDATE=max(CHECKDATE)
				from CV_CMS_SOURCE.dbo.APTHCK
				where COMPANYNUMBER=@toco
				group by COMPANYNUMBER, VENDORNUMBER, PAYMENTSELNO ) 
				as  c on h.COMPANYNUMBER=c.COMPANYNUMBER and h.VENDORNUMBER=c.VENDORNUMBER 
					and h.PAYMENTSELNO=c.PAYMENTSELNO
	join bHQCO on bHQCO.HQCo=@toco
where h.GROSSAMT<>h.PARTPAYAMTTD 
	and d.Amt<>h.PARTPAYAMTTD 
	and h2.RECORDCODE is not null 
	and h.PARTPAYAMTTD<>0
	and h.COMPANYNUMBER=@fromco;

select @rowcount=@@rowcount;

alter table bAPTD enable trigger all;




--------------------------------------------------------------------------------------------


/*Marks any transactions that end in 4 (cleared in CMS) as cleared in Viewpoint.  These 
	entries are not picked up in cvsp_APTD_Cleared since they are partially paid 
	therefore, exist in APTD.*/

update bAPTD set bAPTD.Status=4, bAPTD.PaidMth=a.PaidMth, bAPTD.PaidDate=a.PaidDate, 
		bAPTD.CMCo=null, bAPTD.CMAcct=null, bAPTD.PayMethod=null
from bAPTD 
	join (select APCo=@toco, PAYMENTSELNO, 
				PaidMth=max(substring(convert(nvarchar(max),APTOPC.JOURNALDATE),5,2) + '/01/' +
					substring(convert(nvarchar(max),APTOPC.JOURNALDATE),1,4)),
				PaidDate=max(substring(convert(nvarchar(max),APTOPC.JOURNALDATE),5,2) + '/' +  
					substring(convert(nvarchar(max),APTOPC.JOURNALDATE),7,2) + '/' + 
					substring(convert(nvarchar(max),APTOPC.JOURNALDATE),1,4))
		from CV_CMS_SOURCE.dbo.APTOPC
		where RECORDCODE=4
		group by COMPANYNUMBER, PAYMENTSELNO) as a
		on a.APCo=bAPTD.APCo and a.PAYMENTSELNO=bAPTD.udYSN
where bAPTD.APCo=@toco 
	and Status=1 
	and right(APTrans,1)=4 





-------------------------------------------------------------------------------
--Update APTD so all transactions with the same CM Ref/Vendor use the same CM Account
update bAPTD set bAPTD.CMAcct=c.CMAcct
from bAPTD 
	join APTH h on bAPTD.APCo=h.APCo and bAPTD.Mth=h.Mth and bAPTD.APTrans=h.APTrans
	join (select d.APCo, h.Vendor, d.CMRef, d.CMRefSeq, CMAcct=max(d.CMAcct)
		from bAPTD d
			join bAPTH h on d.APCo=h.APCo and d.Mth=h.Mth and d.APTrans=h.APTrans
		where d.APCo=@toco
		group by d.APCo, h.Vendor, d.CMRef, d.CMRefSeq) 
		as c
		on c.APCo=bAPTD.APCo and c.CMRef=bAPTD.CMRef
				and c.CMRefSeq=bAPTD.CMRefSeq and c.Vendor=h.Vendor
where bAPTD.APCo=@toco and bAPTD.CMAcct<>c.CMAcct 

-------------------------------------------------------------------------------


--Fix rounding differences between APTL and APTD.  Excludes retainage and only fixes
--rounding smaller than dollar.  Other differences exist because of adjustments so the 
--restriction on amount accounts for that.


update bAPTD set bAPTD.Amount=bAPTD.Amount+diff.Diff
from bAPTD
	join (select MinSeq, l.APCo, l.Mth, l.APTrans, l.APLine, LineAmt=sum(l.GrossAmt),
				DetAmt=sum(d.Amount), Diff=sum(l.GrossAmt)-sum(d.Amount), SeqCount=max(SeqCount)
			from bAPTL l
				join bAPTH h on  l.APCo=h.APCo and l.Mth=h.Mth and l.APTrans=h.APTrans
				join (select APCo, Mth, APTrans, APLine, Amount=sum(Amount), SeqCount=count(APSeq), MinSeq=min(APSeq)
						from bAPTD
						where bAPTD.PayType<>2 and bAPTD.APCo=@toco
						group by APCo, Mth, APTrans, APLine)
						as d
						on d.APCo=l.APCo and d.Mth=l.Mth and d.APTrans=l.APTrans and d.APLine=l.APLine
			group by l.APCo, l.Mth, l.APTrans, l.APLine, MinSeq
			having abs(sum(l.GrossAmt + case when l.TaxType=1 then l.TaxAmt else 0 end)-sum(d.Amount))<=1 and 
			abs(sum(l.GrossAmt + case when l.TaxType=1 then l.TaxAmt else 0 end)-sum(d.Amount))<>0)
			as diff
			on bAPTD.APCo=diff.APCo and bAPTD.Mth=diff.Mth and bAPTD.APTrans=diff.APTrans and
				bAPTD.APLine=diff.APLine and bAPTD.APSeq=diff.MinSeq
where bAPTD.APCo=@toco;

--
--COMMIT TRAN
--END TRY
--
--BEGIN CATCH
--select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
--ROLLBACK
--END CATCH;


alter table bAPTD enable trigger all;

--return @@error
GO
