SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   CREATE view [dbo].[brvMSHaul_APTH_DistinctAPRef] as
   select APCo, Mth, VendorGroup, Vendor, APRef, InvDate=max(InvDate),DueDate=max(DueDate), CountAPTrans=count(APTrans)
   from APTH
   Group by APCo, Mth, VendorGroup, Vendor, APRef
   
  
 



GO
GRANT SELECT ON  [dbo].[brvMSHaul_APTH_DistinctAPRef] TO [public]
GRANT INSERT ON  [dbo].[brvMSHaul_APTH_DistinctAPRef] TO [public]
GRANT DELETE ON  [dbo].[brvMSHaul_APTH_DistinctAPRef] TO [public]
GRANT UPDATE ON  [dbo].[brvMSHaul_APTH_DistinctAPRef] TO [public]
GO
