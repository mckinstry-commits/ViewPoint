SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE proc [dbo].[cvsp_CMS_APTD_Cleared] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as


/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		AP Cleared Detail (APTD)
	Created:	10.12.09
	Author:     JJH    

	Notes:		Runs after the main APTD insert.  
				This picks up any transactions that have been cleared and creates an APTD record.
				This Select statement should always net to zero.
				
	Revisions:	1. 10/26/2012 BTC - Modified to include Sales Tax in APTD Amount
**/



set @errmsg=''
set @rowcount=0



ALTER Table bAPTD disable trigger all;


--no deletes necessary - already made in cvsp_CMS_APTD

-- add new trans
BEGIN TRAN
BEGIN TRY


insert into bAPTD(APCo, Mth, APTrans, APLine, APSeq, PayType, Amount, DiscOffer,
	DiscTaken, DueDate, Status, PaidMth, PaidDate, CMCo, CMAcct, PayMethod, CMRef, CMRefSeq,
	EFTSeq, VendorGroup, Supplier, PayCategory, TotTaxAmount, udYSN, udRCCD,
	udRetgHistory,udSource,udConv)


select l.APCo
	, l.Mth
	, l.APTrans
	, l.APLine
	, Seq=1
	, l.PayType
	, l.GrossAmt + case when l.TaxType=1 then l.TaxAmt else 0 end
	, DiscOffer=0
	, DiscTaken=0
	, a.DueDate
	, Status=4 --1=open, 2=Hold, 3=Paid= 4=Clear
	, PaidMth=h.PaidMth
	, PaidDate=h.PaidDate
	, CMCo=null
	, CMAcct=null
	, PayMethod=null
	, CMRef=null
	, CMRefSeq=null
	, EFTSeq=null
	, VendorGroup=a.VendorGroup
	, Supplier=null
	, PayCategory=null
	, TotTaxAmount=0
	, udYSN=l.udYSN
	, udRCCD=l.udRCCD
	, udRetgHistory='N'
	,'APTD_Cleared'
	, udConv='Y'
from bAPTL l
	left join bAPTD d on d.APCo=l.APCo and d.Mth=l.Mth and d.APTrans=l.APTrans and d.APLine=l.APLine
	join bAPTH a on l.APCo=a.APCo and l.Mth=a.Mth and l.APTrans=a.APTrans
	join (select APCo=@toco, APTOPC.PAYMENTSELNO, TotalInv=sum(APTOPC.GROSSAMT),
				PaidMth=max(substring(convert(nvarchar(max),APTOPC.JOURNALDATE),1,4)+ '/'+
				substring(convert(nvarchar(max),APTOPC.JOURNALDATE),5,2) + '/01'
					),
				PaidDate=max(substring(convert(nvarchar(max),APTOPC.JOURNALDATE),1,4) + '/'+
					+substring(convert(nvarchar(max),APTOPC.JOURNALDATE),5,2) + '/' +  
					substring(convert(nvarchar(max),APTOPC.JOURNALDATE),7,2) 
					)
				from CV_CMS_SOURCE.dbo.APTOPC APTOPC
					left join CV_CMS_SOURCE.dbo.APTOPC c on APTOPC.COMPANYNUMBER=c.COMPANYNUMBER and APTOPC.PAYMENTSELNO=c.PAYMENTSELNO 
						and APTOPC.VENDORNUMBER=c.VENDORNUMBER
						and c.RECORDCODE=4
				where c.COMPANYNUMBER is not null--only pull in records that have been cleared in CMS
					and APTOPC.COMPANYNUMBER=@fromco
				group by APTOPC.COMPANYNUMBER, APTOPC.PAYMENTSELNO
				having sum(APTOPC.GROSSAMT)=0)
				as h 
				on l.APCo=h.APCo and l.udYSN=h.PAYMENTSELNO 
where d.APCo is null --only insert records to APTD that were not picked up previously 
	and l.APCo=@toco

select @rowcount=@@rowcount;


COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

ALTER Table bAPTD enable trigger ALL;

return @@error
GO
