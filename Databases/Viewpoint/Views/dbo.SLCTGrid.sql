SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   view [dbo].[SLCTGrid]
   /***************************************
   *	Created by:	??
   *	Modified by:	MV 01/21/05 - #26761 comments,with nolock
   *					MV 02/23/05 - #26761 top 100 percent, order by
   *	Used by:		SL Compliance Form
   ****************************************/
    as 
   select top 100 percent SLCo, SL, SLCT.VendorGroup, 'Action'='A',CompCode,
    Seq, APVM.SortName, SLCT.Vendor, Description, Verify, ExpDate, Complied, SLCT.Notes
    from SLCT with (nolock) left join APVM  with (nolock) on SLCT.VendorGroup = APVM.VendorGroup and
    SLCT.Vendor = APVM.Vendor order by SLCo, SL, CompCode, Seq

GO
GRANT SELECT ON  [dbo].[SLCTGrid] TO [public]
GRANT INSERT ON  [dbo].[SLCTGrid] TO [public]
GRANT DELETE ON  [dbo].[SLCTGrid] TO [public]
GRANT UPDATE ON  [dbo].[SLCTGrid] TO [public]
GO
