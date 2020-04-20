SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    view [dbo].[APULGrid] 
   /**************************************************
   *	Created:	??
   *	Modified:	MV 01/21/05 - #26761 comments,with (nolock)
   *				MV 02/23/05 - #26761 top 100 percent, order by
   *				MV 08/12/08 - #128288 - VAT TaxType
   *	Used by:	AP Unapproved Form grid
   ***************************************************/
   as
    select top 100 percent APCo, UIMth, UISeq, Discount, Retainage,
    	TaxAmt, MiscAmt, GrossAmt, UM, Description, LineType, Line, TaxType, MiscYN,
    	'Total'=  GrossAmt+(Case MiscYN When 'Y' then MiscAmt else 0 End)
                  + Case TaxType When 2 then 0 else TaxAmt End
        from APUL with (nolock)
   	 order by APCo, UIMth, UISeq

GO
GRANT SELECT ON  [dbo].[APULGrid] TO [public]
GRANT INSERT ON  [dbo].[APULGrid] TO [public]
GRANT DELETE ON  [dbo].[APULGrid] TO [public]
GRANT UPDATE ON  [dbo].[APULGrid] TO [public]
GO
