SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






/**
=========================================================================
Copyright © 2012 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		AP Transaction Detail - Insert Open Entries
	Created:	10.13.09
	Created by: JJH    
	Revisions:	1. 03/20/2012 BBA - Changed TaxAmt to GSTtaxAmt which was
					a 6.3.1 change.
	
	Notes:		Inserts unpaid transactions into APTD
				Runs after the main APTD insert and the cleared insert. 
				
	EXEC cvsp_CMS_APTD_Open 20,20,'',0
		
**/


CREATE proc [dbo].[cvsp_CMS_APTD_Open] 
	( @fromco1 smallint
	, @fromco2 smallint
	, @fromco3 smallint
	, @toco smallint
	, @errmsg varchar(1000) output
	, @rowcount bigint output
	) 
as

set @errmsg=''
set @rowcount=0

declare
	@fromco_1 int = @fromco1,
	@fromco_2 int = @fromco2,
	@fromco_3 int = @fromco3,
	@VPtoco int = @toco

ALTER Table bAPTD disable trigger all;

-- add new trans
BEGIN TRY
BEGIN TRAN


insert into bAPTD(APCo, Mth, APTrans, APLine, APSeq, PayType, Amount, DiscOffer,
	DiscTaken, DueDate, Status, PaidMth, PaidDate, CMCo, CMAcct, PayMethod, CMRef, CMRefSeq,
	EFTSeq, VendorGroup, Supplier, PayCategory, GSTtaxAmt, TotTaxAmount, udYSN, udRCCD
	,udRetgHistory,udSource,udConv)

select l.APCo
	, l.Mth
	, l.APTrans
	, l.APLine
	, APSeq=1
	, l.PayType
	, l.GrossAmt
	, DiscOffer=0
	, DiscTaken=0
	, h.DueDate
	, Status=1  --1=open, 2=Hold, 3=Paid= 4=Clear
	, PaidMth=null
	, PaidDate=null
	, CMCo=null
	, CMAcct=null
	, PayMethod=null
	, CMRef=null
	, CMRefSeq=null
	, EFTSeq=null
	, VendorGroup=h.VendorGroup
	, Supplier=null
	, PayCategory=null
	, TaxAmount=0
	, TotTaxAmount=0
	, udYSN=l.udYSN
	, udRCCD=l.udRCCD
	,udRetgHistory='N'
	,'APTD_Open_1'
	, udConv='Y'
from bAPTL l 
	join bAPTH h on l.APCo=h.APCo and l.Mth=h.Mth and l.APTrans=h.APTrans
	join (select distinct APCo=@VPtoco, VENDORNUMBER, PAYMENTSELNO
		from CV_CMS_SOURCE.dbo.APTOPC 
		where COMPANYNUMBER in (@fromco_1,@fromco_2,@fromco_3) and CHECKNUMBER=0 and RECORDCODE<>4) 
		as a
		on l.APCo=a.APCo and h.Vendor=a.VENDORNUMBER and l.udYSN=a.PAYMENTSELNO
	left join APTD d with (nolock) on l.APCo=d.APCo and l.Mth=d.Mth and l.APTrans=d.APTrans and l.APLine=d.APLine
where d.APCo is null --restricts to just those invoices that have not previously been updated
	and l.APCo=@VPtoco; 

select @rowcount=@@rowcount;

--Inserts records into APTD for partial pays
insert into bAPTD(APCo, Mth, APTrans, APLine, APSeq, PayType, Amount, DiscOffer,
	DiscTaken, DueDate, Status, PaidMth, PaidDate, CMCo, CMAcct, PayMethod, CMRef, CMRefSeq,
	EFTSeq, VendorGroup, Supplier, PayCategory, GSTtaxAmt, TotTaxAmount, udYSN, udRCCD
	,udRetgHistory ,udSource, udConv, udCGCTable, udCGCTableID)

select h.APCo 
	, h.Mth
	, h.APTrans
	, l.APLine
	, APSeq=d.MaxSeq+1
	, PayType=l.LinePayType
	, Amount=isnull(l.LineTotal,0)-isnull(d.Amount,0)
	, DiscOffer=isnull(l.LineDiscount,0)-isnull(d.APTDDisc,0)
	, DiscTaken=isnull(l.LineDiscount,0)-isnull(d.APTDDisc,0)
	, DueDate=h.DueDate
	, Status=1
	, PaidMth=null
	, PaidDate=null
	, CMCo=null
	, CMAcct=null
	, PayMethod=null
	, CMRef=null
	, CMRefSeq=null
	, EFTSeq=null
	, VendorGroup=h.VendorGroup
	, Supplier=null
	, PayCategory=null
	, GSTtaxAmt=0	
	, TotTaxAmount=isnull(l.LineTax,0)-isnull(d.APTDTax,0)
	, udYSN=h.udYSN
	, udRCCD=h.udRCCD
	, udRetgHistory='N'
	, udSource='APTD_Open_2'
	, udConv='Y'
	, udCGCTable='APTOPD'
	, udCGCTableID=l.udCGCTableID
		
from bAPTH h 
	join (Select APCo, Mth, APTrans, APLine, max(PayType) as LinePayType, LineTotal=sum(GrossAmt+TaxAmt),
			LineTax=sum(TaxAmt),
			LineDiscount=sum(Discount),
			udCGCTableID=max(udCGCTableID)
			from bAPTL
			where bAPTL.APCo=@VPtoco
			group by APCo, Mth, APTrans, APLine)
			as l
			on h.APCo=l.APCo and h.Mth=l.Mth and h.APTrans=l.APTrans 
	join (select APCo, Mth, APTrans, APLine, Amount=sum(Amount), 
			PdAmt=sum(case when Status=3 then Amount else 0 end),
			APTDTax=sum(TotTaxAmount),
			APTDDisc=sum(DiscTaken),
			MaxSeq=max(APSeq)
			from bAPTD with (nolock)
			where bAPTD.Status<>4
				and bAPTD.APCo=@VPtoco
			group by APCo, Mth, APTrans, APLine)
		as d 
		on h.APCo=d.APCo and h.Mth=d.Mth and h.APTrans=d.APTrans and l.APLine=d.APLine
where l.LineTotal<>d.Amount
	and abs(l.LineTotal-d.Amount)>2--Restrict to just those that aren't rounding errors
	and h.Vendor <>0
	and h.APCo=@VPtoco

select @rowcount=@rowcount+@@rowcount;



COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

ALTER Table bAPTD enable trigger all;

return @@error





GO
