SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE View [dbo].[vrvAPPmtHistoryDDAttachments]    
    
--/*** View for attachments for APVendorPaymentHistoryDrilldown Report *    
--     Can view APPH and HQAT attachments.     
                 
--  Created 04/17/11 by DML             
  
--****/    
    
AS    
  
Select source = 'APPH'  
, Null as HQCo  
, Null as FormName  
, Null as AttachmentID  
, Null as OrigFileName  
, APPH.UniqueAttchID as UniqueAttchID  
, APPH.APCo  
, APPH.CMCo  
, APPH.CMAcct  
, APPH.PayMethod  
, APPH.CMRef  
, APPH.CMRefSeq  
, APPH.EFTSeq  
, APPH.VendorGroup  
, APPH.Vendor  
, APPH.ChkType  
, APPH.PaidMth  
, APPH.PaidDate  
, APPH.Amount  
, APPH.Supplier  
, APPH.BatchId  
from APPH with (nolock)  
  
where APPH.UniqueAttchID is not null  
  
UNION ALL  
  
Select distinct 'HQAT'  
, HQAT.HQCo  
, HQAT.FormName  
, HQAT.AttachmentID  
, HQAT.OrigFileName  
, HQAT.UniqueAttchID as UniqueAttchID  
, Null as APCo  
, Null as CMCo  
, Null as CMAcct  
, Null as PayMethod  
, Null as CMRef  
, Null as CMRefSeq  
, Null as EFTSeq  
, Null as VendorGroup  
, Null as Vendor  
, Null as ChkType  
, Null as PaidMth  
, Null as PaidDate  
, Null as Amount  
, Null as Supplier  
, Null as BatchId  
from HQAT   
  
left outer JOIN APPH with (nolock)   
 ON HQAT.UniqueAttchID=APPH.UniqueAttchID  
  
where HQAT.UniqueAttchID is not null
GO
GRANT SELECT ON  [dbo].[vrvAPPmtHistoryDDAttachments] TO [public]
GRANT INSERT ON  [dbo].[vrvAPPmtHistoryDDAttachments] TO [public]
GRANT DELETE ON  [dbo].[vrvAPPmtHistoryDDAttachments] TO [public]
GRANT UPDATE ON  [dbo].[vrvAPPmtHistoryDDAttachments] TO [public]
GO
