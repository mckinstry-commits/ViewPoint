SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE proc [dbo].[cvsp_CMS_APPH] 
	( @fromco1 smallint
	, @fromco2 smallint
	, @fromco3 smallint
	, @toco smallint
	, @errmsg varchar(1000) output
	, @rowcount bigint output
	) 
as


/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		AP Payment Header (APPH)
	Created:	10.13.09
	Created by: JJH  
	Revisions:	1. None
**/

set @errmsg=''
set @rowcount=0


--get Customer defaults
--Country
declare @defaultCountry varchar(2)
select @defaultCountry=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@toco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='Country' and a.TableName='bAPPH';

ALTER Table bAPPH disable trigger ALL;
ALTER Table bCMDT disable trigger ALL;

-- delete existing trans
BEGIN tran
delete from bAPPH where APCo=@toco
	and udConv = 'Y'
--Delete checks out of CM since it uses it to determine next seq #
delete from bCMDT where CMCo=@toco and Source='AP Payment' 
	and udConv = 'Y';
COMMIT TRAN;

-- add new trans
BEGIN TRY
BEGIN TRAN



insert bAPPH (APCo, CMCo, CMAcct, PayMethod, CMRef, CMRefSeq, EFTSeq, 
		VendorGroup, Vendor, Name, Address, City, State, Zip, 
		ChkType, PaidMth, PaidDate, Amount, Supplier, VoidYN,
		VoidMemo, InUseMth, InUseBatchId, PurgeYN, BatchId, AddnlInfo, 
		Country,udSource,udConv)

select APCo=d.APCo
	, CMCo=d.CMCo
	, CMAcct=d.CMAcct
	, PayMethod=d.PayMethod
	, CMRef=d.CMRef
		--CMS has different vendors with the same check number in the same CM Company and CM Account
		--That's not allowed in Viewpoint so the workaround is to change the CM Reference Sequence to get by the index error
		--The normal status of the sequence is zero.  This sets it back to zero if there is only one vendor so the majority
		--will go into Viewpoint very similarly as to if they were originally entered through the front-end.
	, CMRefSeq=max(isnull(c.Seq,0))+case when max(c.Seq)>0 then 
		ROW_NUMBER() OVER (PARTITION BY d.APCo, d.CMCo, d.CMAcct, d.CMRef ORDER BY d.APCo, d.CMCo, d.CMAcct, d.CMRef) 
		else 
		ROW_NUMBER() OVER (PARTITION BY d.APCo, d.CMCo, d.CMAcct, d.CMRef ORDER BY d.APCo, d.CMCo, d.CMAcct, d.CMRef)-1 end
	, EFTSeq=0
	, VendorGroup=max(h.VendorGroup)
	, Vendor=(h.Vendor)
	, Name=max(v.Name)
	, Address=max(v.Address)
	, City=max(v.City)
	, State=max(v.State)
	, Zip=max(v.Zip)
	, ChkType='C'
	, PaidMth=(d.PaidMth)
	, PaidDate=(d.PaidDate)
	, Amount=sum(d.Amount-d.DiscTaken)
	, Supplier=d.Supplier
	, VoidYN='N'
	, VoidMemo=null
	, InUseMth=null
	, InUseBatchId=null
	, PurgeYN='N'
	, BatchId=0
	, AddnlInfo=max(v.AddnlInfo)
	, Country=@defaultCountry
	, udSource ='APPH'
	, udConv='Y'
from bAPTD d
	join bAPTH h on d.APCo=h.APCo and d.Mth=h.Mth and d.APTrans=h.APTrans	
	left join bAPVM v on h.VendorGroup=v.VendorGroup and h.Vendor=v.Vendor
	left join (select CMCo, CMAcct, CMRef, Seq=max(CMRefSeq)
				from bCMDT 
				where CMCo=@toco
				group by CMCo, CMAcct, CMRef) 
				as c on d.CMCo=c.CMCo and d.CMAcct=c.CMAcct and d.CMRef=c.CMRef
where d.CMRef is not null 
	and d.CMRef<>'       Ret' --Check value used if bringing in full retg history 
	and d.CMRef<>'   History' --Check value used if brining in AP from history table in cases where data was purged
	and d.APCo=@toco
group by d.APCo, d.CMCo, d.CMAcct, d.PayMethod, d.CMRef, h.Vendor, d.Supplier,
	d.PaidMth, d.PaidDate

select @rowcount=@@rowcount;


COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

ALTER Table bAPPH enable trigger ALL;
ALTER Table bCMDT enable trigger ALL;
return @@error


GO
