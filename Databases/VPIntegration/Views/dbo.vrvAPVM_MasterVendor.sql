SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[vrvAPVM_MasterVendor]
	/****** This view returns APVM fields for the Master Vendors as designated on the APVM Records
   	Created to be used with the AP Master Vendor Drilldown Issue 30320 3/30/06 NF  *****/
as
select APMV.MasterVend, APVM.* 
from APVM
join (select distinct APVM_MV.VendorGroup, APVM_MV.MasterVendor as "MasterVend" 
      from APVM APVM_MV) as APMV
   on APVM.VendorGroup = APMV.VendorGroup and APVM.Vendor = APMV.MasterVend


GO
GRANT SELECT ON  [dbo].[vrvAPVM_MasterVendor] TO [public]
GRANT INSERT ON  [dbo].[vrvAPVM_MasterVendor] TO [public]
GRANT DELETE ON  [dbo].[vrvAPVM_MasterVendor] TO [public]
GRANT UPDATE ON  [dbo].[vrvAPVM_MasterVendor] TO [public]
GO
