SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[cvsp_CMS_APPD] 
	( @fromco1	SMALLINT 
	, @fromco2	SMALLINT 
	, @fromco3	SMALLINT 
	, @toco		SMALLINT
	, @errmsg	VARCHAR(1000) OUTPUT
	, @rowcount	BIGINT OUTPUT
	)
AS



/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		AP Payment Detail (APPD)
	Created:	10.13.09
	Created by: JJH  
	Revisions:	1. None
**/


set @errmsg=''
set @rowcount=0

--get defaults from APCO
declare @retpaytype tinyint;
select @retpaytype=RetPayType from bAPCO where APCo=@toco;


ALTER table bAPPD disable trigger all;

-- delete existing trans
BEGIN tran
delete from bAPPD where APCo=@toco
	--and udConv = 'Y';
COMMIT TRAN;

-- add new trans
BEGIN TRAN
BEGIN TRY



insert bAPPD (APCo, CMCo, CMAcct, PayMethod, CMRef, CMRefSeq, EFTSeq, Mth,
	APTrans, APRef, InvDate, Gross, Retainage, PrevPaid,
	PrevDiscTaken, Balance, DiscTaken, Description, udSource,udConv)


select APCo=d.APCo
	, CMCo=d.CMCo
	, CMAcct=d.CMAcct
	, PayMethod=d.PayMethod
	, CMRef=d.CMRef
	, CMRefSeq=p.CMRefSeq
	, EFTSeq=0
	, Mth=d.Mth
	, APTrans=d.APTrans
	, APRef=h.APRef
	, InvDate=max(h.InvDate)
	, Gross=sum(d.Amount)
	, Retainage=sum(case when d.PayType=@retpaytype then d.Amount else 0 end)
	, PrevPaid=0
	, PrevDiscTaken=0
	, Balance=0
	, DiscTaken=sum(d.DiscTaken)
	, Dsecription=max(h.Description)
	, udSource ='APPD'
	, udConv='Y'
from bAPTD d 
	join bAPTH h on d.APCo=h.APCo and d.Mth=h.Mth and d.APTrans=h.APTrans
	join bAPPH p on h.APCo=p.APCo and d.CMCo=p.CMCo and d.CMAcct=p.CMAcct	
		and d.CMRef=p.CMRef and h.Vendor=p.Vendor and d.PaidDate=p.PaidDate
where d.CMRef is not null 
	and d.CMRef<>'       Ret'
	and d.CMRef<>'   History'
	and d.APCo=@toco
group by d.APCo, d.CMCo, d.CMAcct, d.PayMethod, d.CMRef, p.CMRefSeq, 
	d.Mth, d.APTrans, h.APRef, h.Vendor

select @rowcount=@@rowcount;

/* Since there can be check numbers used on more than one vendor,
	APPH/APPD CM Reference Sequence might not match existing data
	in APTD.  This code will go back and update APTD to make it match*/

update bAPTD set bAPTD.CMRefSeq=p.CMRefSeq
from bAPTD
	join bAPPH a on bAPTD.APCo=a.APCo and bAPTD.CMCo=a.CMCo and bAPTD.CMAcct=a.CMAcct
		and bAPTD.CMRef=a.CMRef and bAPTD.PaidDate=a.PaidDate
	join bAPTH h on bAPTD.APCo=h.APCo and bAPTD.Mth=h.Mth and bAPTD.APTrans=h.APTrans
	join bAPPD p on bAPTD.APCo=p.APCo and bAPTD.CMCo=p.CMCo and bAPTD.CMAcct=p.CMAcct and bAPTD.CMRef=p.CMRef 
		and bAPTD.PaidMth=p.Mth and bAPTD.APTrans=p.APTrans 
		and bAPTD.PaidDate=a.PaidDate
where bAPTD.CMRef is not null 
	and bAPTD.CMRef<>'       Ret'
	and bAPTD.CMRef<>'   History'
	and bAPTD.CMRefSeq<>p.CMRefSeq
	and bAPTD.APCo=@toco

select @rowcount=@@rowcount;



COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

ALTER table bAPPD enable trigger all;

return @@error



GO
