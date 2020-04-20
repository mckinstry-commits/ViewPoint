SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/**
=========================================================================================
Copyright © 2014 Viewpoint Construction Software (VCS) 
The TSQL code in this procedure may not be reproduced, modified,
transmitted or executed without written consent from VCS.
=========================================================================================
	Title:		PM Firm Master (bPMFM)
	Created:	2/14/2014
	Created by:	VCS Technical Services - Bryan Clark
	Revisions:	
		1. 
					
**/

CREATE PROCEDURE [dbo].[cvsp_CMS_MASTER_PMFM_Vend] 
	(@fromco smallint, @toco smallint, @errmsg varchar(1000) output, @rowcount bigint output) 

as

set @errmsg=''
set @rowcount=0


--Add udConv field if not already there
if not exists (select * from syscolumns c
				join sysobjects o
					on o.id = c.id
				where o.name = 'bPMFM' and c.name = 'udConv')
begin
	alter table bPMFM add udConv char(1)
end;


declare @vendorgroup smallint, @custgroup smallint
select @vendorgroup = VendorGroup from bHQCO where HQCo = @toco


alter table bPMFM disable trigger all

delete bPMFM where udConv = 'Y' and VendorGroup = @vendorgroup and Vendor is not null;



BEGIN TRAN
BEGIN TRY


	--Vendors:
	insert bPMFM 
		( VendorGroup
		, FirmNumber
		, FirmName
		, FirmType
		, Vendor
		, SortName
		, ContactName
		, MailAddress
		, MailCity
		, MailState
		, MailZip
		, MailAddress2
		, ShipAddress
		, ShipCity
		, ShipState
		, ShipZip
		, ShipAddress2
		, Phone
		, Fax
		, EMail
		, URL
		, MailCountry
		, ShipCountry
		)
	select v.VendorGroup
		 , Vendor
		 , Name
		 , null
		 , Vendor
		 , v.SortName
		 , Contact
		 , Address
		 , City
		 , State
		 , Zip
		 , Address2
		 , POAddress
		 , POCity
		 , POState
		 , POZip
		 , POAddress2
		 , Phone
		 , Fax
		 , EMail
		 , URL
		 , Country
		 , POCountry
  --select *
	  from bAPVM v with (nolock)
	  left join (select VendorGroup
					  , FirmNumber
					  , SortName 
				   from bPMFM) p
		on p.VendorGroup = v.VendorGroup 
	   and (p.FirmNumber = v.Vendor 
	    or p.SortName = v.SortName)
	 where v.VendorGroup = @vendorgroup 
	   and v.udConv = 'Y' 
	   and p.FirmNumber is null
	   and v.udEmployeeYN = 'N';

	select @rowcount = @@ROWCOUNT;


COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

ALTER Table bPMFM enable trigger all;

return @@error
GO
