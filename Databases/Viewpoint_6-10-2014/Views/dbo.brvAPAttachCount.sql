SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   CREATE View [dbo].[brvAPAttachCount] as
   /*******************************
   AP Attachments Count
   Created 10/23/03 CR
   
   This view will count to see how many attachments are stored for each reference.
   
   Reports:  APVendorLookupMT.rpt
   *******************************/
   select distinct  APCo, APVendorGroup, APVendor, APReference 
   from HQAI
   
   
  
 



GO
GRANT SELECT ON  [dbo].[brvAPAttachCount] TO [public]
GRANT INSERT ON  [dbo].[brvAPAttachCount] TO [public]
GRANT DELETE ON  [dbo].[brvAPAttachCount] TO [public]
GRANT UPDATE ON  [dbo].[brvAPAttachCount] TO [public]
GRANT SELECT ON  [dbo].[brvAPAttachCount] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvAPAttachCount] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvAPAttachCount] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvAPAttachCount] TO [Viewpoint]
GO
