SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   view [dbo].[brvAPTotalAPTDAmt]
    
    /**************
     Created 3/13/03 Nadine F.
     Usage:  Used by the AP Open Payables reports to display the AP Invoice total amount from APTD.  
             View returns one line per Co, Mth, APTrans
    
    **************/
    
    as
    
    Select APCo, Mth, APTrans, APTDTotalAmt=sum(Amount)
    From APTD
    Group By APCo, Mth, APTrans

GO
GRANT SELECT ON  [dbo].[brvAPTotalAPTDAmt] TO [public]
GRANT INSERT ON  [dbo].[brvAPTotalAPTDAmt] TO [public]
GRANT DELETE ON  [dbo].[brvAPTotalAPTDAmt] TO [public]
GRANT UPDATE ON  [dbo].[brvAPTotalAPTDAmt] TO [public]
GO
