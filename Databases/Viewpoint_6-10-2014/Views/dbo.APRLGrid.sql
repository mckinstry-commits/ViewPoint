SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      view [dbo].[APRLGrid]
   /*******************************************************
   *	Created:	??
   * 	Modified:	MV 01/21/05 - #26761 comments, with (nolock)
   *				MV 02/23/05 - #26761 top 100 percent, order by
   *	
   *  	Used by:	AP Recurring form grid 
   *	
   *********************************************************/
   as
   
   select top 100 percent APCo, VendorGroup, Vendor, InvId, Line,
   	LineType, Description, UM, GrossAmt, MiscAmt, TaxAmt, Retainage, Discount,
      'Total'= GrossAmt+MiscAmt+TaxAmt
   from APRL with (nolock)
   order by APCo, VendorGroup, Vendor, InvId, Line

GO
GRANT SELECT ON  [dbo].[APRLGrid] TO [public]
GRANT INSERT ON  [dbo].[APRLGrid] TO [public]
GRANT DELETE ON  [dbo].[APRLGrid] TO [public]
GRANT UPDATE ON  [dbo].[APRLGrid] TO [public]
GRANT SELECT ON  [dbo].[APRLGrid] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APRLGrid] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APRLGrid] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APRLGrid] TO [Viewpoint]
GO
