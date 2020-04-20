SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE proc [dbo].[cvsp_CMS_MASTER_APAA] (@fromco smallint, @toco smallint, @errmsg varchar(1000) output, @rowcount bigint output) 
as




/**

=========================================================================
Copyright © 2012 Viewpoint Construction Software (VCS) 
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		AP Vendor Additional Addresses (APAA)
	Created:	2/7/2012
	Created by:	Bryan Clark
	Revisions:	None
				
**/


set @errmsg=''
set @rowcount=0


-- get defaults from HQCO
declare @VendorGroup smallint
select @VendorGroup=VendorGroup from bHQCO where HQCo=@toco


alter table bAPAA disable trigger all


-- delete existing trans
BEGIN tran
delete from bAPAA where VendorGroup=@VendorGroup
COMMIT TRAN;


-- add new trans
BEGIN TRAN
BEGIN TRY

insert bAPAA
	(VendorGroup, Vendor, AddressSeq, Type, Description, Address, City, State, Zip, Address2, Notes, Country)
select 
	 VendorGroup = @VendorGroup
	,Vendor = rm.RMVNNO
	,AddressSeq = rm.RMVLNO
	,Type = 0
	,Description = rm.RMNM25
	,Address = rm.RMA25A
	,City = rm.RMCITY
	,State = rm.RMST
	,Zip = rm.RMZIP
	,Address2 = rm.RMA25B
	,Notes = null
	,Country = ISNULL(st.Country, ISNULL(ft.Country, 'US'))
--select cn.*
from CV_CMS_SOURCE.dbo.APPVRM rm
left join bHQST st
	on st.State=rm.RMST and st.Country='US'
left join bHQST ft
	on ft.State=rm.RMST and ft.Country<>'US'
left join CV_CMS_SOURCE.dbo.APTVCN cn
	on cn.COMPANYNUMBER=rm.RMCONO and cn.VENDORNUMBER=rm.RMVNNO and cn.VENDORLOCNO=rm.RMVLNO
left join bAPAA aa
	on aa.VendorGroup=@VendorGroup and aa.Vendor=rm.RMVNNO and aa.AddressSeq=rm.RMVLNO
where rm.RMCONO=@fromco and rm.RMSTAT='A' and aa.AddressSeq is null


select @rowcount=@@rowcount

COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

alter table bAPAA enable trigger all;

return @@error
GO
