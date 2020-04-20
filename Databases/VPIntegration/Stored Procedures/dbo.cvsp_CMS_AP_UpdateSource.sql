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

--Bad Dates for some of Western Builders' Transactions
update CV_CMS_SOURCE.dbo.APTOPC set JOURNALDATE=TRANSACTIONDATE where JOURNALDATE=0
--update CV_CMS_SOURCE.dbo.APTOPC set INVOICEDATE=20070111 where INVOICEDATE =19070111
--update CV_CMS_SOURCE.dbo.APTOPC set DUEDATE=INVOICEDATE where DUEDATE=20500101
--update CV_CMS_SOURCE.dbo.APTOPC set INVOICEDATE=JOURNALDATE where INVOICEDATE=20900620
--update CV_CMS_SOURCE.dbo.APTOPC set INVOICEDATE=20090716 where INVOICEDATE=20940716

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
	and   c.RECORDCODE = d.RECORDCODE


COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;


return @@error

GO
