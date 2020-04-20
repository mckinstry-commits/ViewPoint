SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   CREATE  View [dbo].[APPBChkPrnt]
   /*******************************************************
   *	Created:	12/3/02 MV
   * 	Modified:	01/21/05 MV with (nolock)
   *				01/26/09 - #130832 - restrict voided checks	
   *
   *  	Used in lookups APPB, APPBVendor and APPBVendorSeq.
   *	The lookups must be sorted by sortname and batchseq.
   * 
   *********************************************************/
   as
   select top 100 percent b.BatchSeq, V.SortName,b.Name,b.Amount,b.Co, b.Mth, b.BatchId, b.ChkType
   from bAPPB b with (nolock)
   join bAPVM V with (nolock) on V.VendorGroup = b.VendorGroup and V.Vendor = b.Vendor
   where b.VoidYN = 'N'
   order by V.SortName, b.BatchSeq
    


    
    
   
   
   
  
 



GO
GRANT SELECT ON  [dbo].[APPBChkPrnt] TO [public]
GRANT INSERT ON  [dbo].[APPBChkPrnt] TO [public]
GRANT DELETE ON  [dbo].[APPBChkPrnt] TO [public]
GRANT UPDATE ON  [dbo].[APPBChkPrnt] TO [public]
GRANT SELECT ON  [dbo].[APPBChkPrnt] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APPBChkPrnt] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APPBChkPrnt] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APPBChkPrnt] TO [Viewpoint]
GO
