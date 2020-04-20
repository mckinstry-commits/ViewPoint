SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE proc [dbo].[cvsp_CMS_AP1099](@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as


/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		AP 1099 Information (APFT)
	Created:	09.10.09
	Created by: JJH      
	Revisions:	1. None
**/


set @errmsg=''
set @rowcount=0


--get defaults from HQCO
declare @VendGroup varchar(10);
select @VendGroup=VendorGroup from bHQCO where HQCo=@toco;


ALTER Table bAPTH disable trigger all; 
ALTER table bAPFT disable trigger all; 
ALTER table bAPVM disable trigger all; 

--delete records
delete bAPFT where APCo=@toco


-- add new trans
BEGIN TRAN
BEGIN TRY

-- clean up 1099 types
update bAPVM set V1099Type=null, V1099Box=null
where V1099YN='N' and (V1099Type is not null or V1099Box is not null)
	and VendorGroup=@VendGroup;


--Set 1099 Information on header
Update bAPTH Set V1099YN='Y', 
	V1099Type=case when Line1099Type is not null then 'MISC' else null end, 
	V1099Box=Line1099Box
from bAPTH h 
	join (select APCo, Mth, APTrans, Line1099Type=max(ud1099Type),
				Line1099Box=case max(ud1099Type) 
						when '3' then 14 
						when '2' then 1 
						when '1' then 7 
					else null end 
			from bAPTL
			where ud1099Type is not null 
			group by APCo, Mth, APTrans) 
			as l 
			on h.APCo=l.APCo and h.Mth=l.Mth and h.APTrans=l.APTrans
where h.APCo=@toco;




--Update 1099 Totals Table 
insert bAPFT (APCo, VendorGroup, Vendor, YEMO, V1099Type, Box1Amt, Box2Amt, Box3Amt, 
	Box4Amt, Box5Amt, Box6Amt, Box7Amt,Box8Amt, Box9Amt, Box10Amt,Box11Amt, 
	Box12Amt,Box13Amt, AuditYN, Box14Amt, Box15Amt, Box16Amt, Box17Amt, Box18Amt, TIN2) 
select APTH.APCo
	, APTH.VendorGroup
	, APTH.Vendor
	, YEMO=cast('12/01/' + convert(varchar(4),datepart(yy,APTD.PaidMth)) as smalldatetime)
	, APTH.V1099Type
	, Box1Amt=sum(case when APTH.V1099Box=1 then APTD.Amount-APTD.DiscTaken  else 0 end) 
	, Box2Amt=sum(case when APTH.V1099Box=2 then APTD.Amount-APTD.DiscTaken  else 0 end) 
	, Box3Amt=sum(case when APTH.V1099Box=3 then APTD.Amount-APTD.DiscTaken  else 0 end) 
	, Box4Amt=sum(case when APTH.V1099Box=4 then APTD.Amount-APTD.DiscTaken  else 0 end) 
	, Box5Amt=sum(case when APTH.V1099Box=5 then APTD.Amount-APTD.DiscTaken  else 0 end) 
	, Box6Amt=sum(case when APTH.V1099Box=6 then APTD.Amount-APTD.DiscTaken  else 0 end) 
	, Box7Amt=sum(case when APTH.V1099Box=7 then APTD.Amount-APTD.DiscTaken  else 0 end) 
	, Box8Amt=sum(case when APTH.V1099Box=8 then APTD.Amount-APTD.DiscTaken  else 0 end) 
	, Box9Amt=sum(case when APTH.V1099Box=9 then APTD.Amount-APTD.DiscTaken  else 0 end) 
	, Box10Amt=sum(case when APTH.V1099Box=10 then APTD.Amount-APTD.DiscTaken  else 0 end) 
	, Box11Amt=sum(case when APTH.V1099Box=11 then APTD.Amount-APTD.DiscTaken  else 0 end) 
	, Box12Amt=sum(case when APTH.V1099Box=12 then APTD.Amount-APTD.DiscTaken  else 0 end) 
	, Box13Amt=sum(case when APTH.V1099Box=13 then APTD.Amount-APTD.DiscTaken  else 0 end) 
	, AuditYN='N'
	, Box14Amt=sum(case when APTH.V1099Box=14 then APTD.Amount-APTD.DiscTaken  else 0 end) 
	, Box15Amt=sum(case when APTH.V1099Box=15 then APTD.Amount-APTD.DiscTaken  else 0 end) 
	, Box16Amt=sum(case when APTH.V1099Box=16 then APTD.Amount-APTD.DiscTaken  else 0 end) 
	, Box17Amt=sum(case when APTH.V1099Box=17 then APTD.Amount-APTD.DiscTaken  else 0 end) 
	, Box18Amt=sum(case when APTH.V1099Box=18 then APTD.Amount-APTD.DiscTaken  else 0 end) 
	, TIN2='N'
from bAPTH APTH 
	join bAPTD APTD on APTH.APCo=APTD.APCo and APTH.Mth=APTD.Mth and APTH.APTrans=APTD.APTrans
where APTH.APCo=@toco 
	and APTH.V1099YN='Y' 
	and APTH.V1099Type = 'MISC' 
	and APTD.PaidMth is not null
group by APTH.APCo, APTH.VendorGroup, Year(PaidMth),
	cast('12/01/' + convert(varchar(4),datepart(yy,APTD.PaidMth)) as smalldatetime)
	,APTH.Vendor, APTH.V1099Type
order by APTH.APCo, APTH.VendorGroup, Year(PaidMth),
       cast('12/01/' + convert(varchar(4),datepart(yy,APTD.PaidMth)) as smalldatetime)
       ,APTH.Vendor,APTH.V1099Type




select @rowcount=@@rowcount;

COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;


ALTER table bAPFT enable trigger all;
ALTER Table bAPTH enable trigger all;
ALTER Table bAPVM enable trigger all;

return @@error

GO
