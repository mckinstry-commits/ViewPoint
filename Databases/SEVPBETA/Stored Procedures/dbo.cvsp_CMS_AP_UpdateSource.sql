SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
=========================================================================
Copyright © 2012 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		Update CMS source tables - AP
	Created:	10.15.09
	Created by:	Viewpoint Technical Services - JJH
	Revisions:	
			1. 03/19/2012 BBA - 
*/


CREATE proc [dbo].[cvsp_CMS_AP_UpdateSource] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as

set @errmsg='';
set @rowcount=0;

-- add new trans
BEGIN TRAN
BEGIN TRY

update CV_CMS_SOURCE.dbo.APTOPD 
set udMth =
convert(smalldatetime,(substring(convert(nvarchar(max),JOURNALDATE),1,4)+'/'+
substring(convert(nvarchar(max),JOURNALDATE),5,2) +'/01'))
where JOURNALDATE<> 0;


update CV_CMS_SOURCE.dbo.APTOPC 
set udMth =
convert(smalldatetime,(substring(convert(nvarchar(max),JOURNALDATE),1,4)+'/'+
substring(convert(nvarchar(max),JOURNALDATE),5,2) +'/01'))
where JOURNALDATE<> 0;

update CV_CMS_SOURCE.dbo.APTCSD 
set udMth =
convert(smalldatetime,(substring(convert(nvarchar(max),PURCHJRNLDATE),1,4)+'/'+
substring(convert(nvarchar(max),PURCHJRNLDATE),5,2) +'/01'))
where PURCHJRNLDATE <> 0;


update CV_CMS_SOURCE.dbo.APTCNS 
set udMth =
convert(smalldatetime,(substring(convert(nvarchar(max),ENTEREDDATE),1,4)+'/'+
substring(convert(nvarchar(max),ENTEREDDATE),5,2) +'/01'))
where ENTEREDDATE<> 0;



--Bad Dates for Transactions
update CV_CMS_SOURCE.dbo.APTOPC set JOURNALDATE=TRANSACTIONDATE where JOURNALDATE=0

--update Paid Month on Outstanding Check File
--update CV_CMS_SOURCE.dbo.APPCHK
-- set PaidMth = substring(convert(nvarchar(max),JDTCK),5,2) 
--+ '/01/' +  
--substring(convert(nvarchar(max),JDTCK),1,4)
--from CV_CMS_SOURCE.dbo.APPCHK

-- Update APTOPD with new Vendor
update CV_CMS_SOURCE.dbo.APTOPD
set udNewVendor = x.NewVendorID
from CV_CMS_SOURCE.dbo.APTOPD d
join Viewpoint.dbo.budxrefAPVendor x 
	on x.OldVendorID=d.VENDORNUMBER
	
-- Update APTOPD with PO Number from APTOPC
update CV_CMS_SOURCE.dbo.APTOPD
set udPONumber = c.PONUMBER
from CV_CMS_SOURCE.dbo.APTOPD d
join CV_CMS_SOURCE.dbo.APTOPC c
	on c.COMPANYNUMBER = d.COMPANYNUMBER 
	and c.VENDORNUMBER = d.VENDORNUMBER 
	and c.PAYMENTSELNO = d.PAYMENTSELNO
	and   c.RECORDCODE = d.RECORDCODE;


-- update APTOPC with AP Trans number
update CV_CMS_SOURCE.dbo.APTOPC 
set udAPTrans = t.APTrans
from CV_CMS_SOURCE.dbo.APTOPC pc
	join (select COMPANYNUMBER, VENDORNUMBER, PAYMENTSELNO, RECORDCODE, JOURNALDATE,
			ROW_NUMBER () over (partition by COMPANYNUMBER, udMth
							order by COMPANYNUMBER, VENDORNUMBER, PAYMENTSELNO, RECORDCODE, udMth) as APTrans
		  from CV_CMS_SOURCE.dbo.APTOPC) t
	on t.COMPANYNUMBER=pc.COMPANYNUMBER 
	and t.VENDORNUMBER=pc.VENDORNUMBER 
	and t.PAYMENTSELNO=pc.PAYMENTSELNO
	and t.RECORDCODE=pc.RECORDCODE
	and t.JOURNALDATE=pc.JOURNALDATE;
	
-- udpate APTOPD with AP Trans number
update CV_CMS_SOURCE.dbo.APTOPD 
set udAPTrans = pc.udAPTrans
from CV_CMS_SOURCE.dbo.APTOPD pd
join CV_CMS_SOURCE.dbo.APTOPC pc
	on  pc.COMPANYNUMBER=pd.COMPANYNUMBER 
	and pc.VENDORNUMBER=pd.VENDORNUMBER 
	and pc.PAYMENTSELNO=pd.PAYMENTSELNO
	and pc.RECORDCODE=pd.RECORDCODE
	--and pc.JOURNALDATE=pd.JOURNALDATE
	and pc.udMth = pd.udMth;


COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;


return @@error

GO
