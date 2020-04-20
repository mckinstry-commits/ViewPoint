SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    view [dbo].[APULGridTotal]
   /*****************************************
   *	Created by:		??
   *	Modified by:	MV 01/21/05 #26761 comments, with (nolock)
   *					MV 02/23/05 #26761 top 100 percent, order by
   *	Used by:		Form AP Unapproved Invoice Review
   ******************************************/
    as 
    select top 100 percent APCo, UIMth, UISeq, Line,'LineTotal'=  GrossAmt+ MiscAmt + TaxAmt - Discount
   	from APUL with (nolock)
   	order by APCo, UIMth, UISeq,Line

GO
GRANT SELECT ON  [dbo].[APULGridTotal] TO [public]
GRANT INSERT ON  [dbo].[APULGridTotal] TO [public]
GRANT DELETE ON  [dbo].[APULGridTotal] TO [public]
GRANT UPDATE ON  [dbo].[APULGridTotal] TO [public]
GO
