SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    view [dbo].[brvAPTL_DistinctPO]
    
    /**************
     Created 1/25/05 Nadine F.
     Usage:  Used by the PO Drilldown report to display the AP Details for PO Items.  
             View returns one line per PO, POItem
    
    **************/
    
    as
    
    select distinct APCo, PO, POItem 
    from APTL

GO
GRANT SELECT ON  [dbo].[brvAPTL_DistinctPO] TO [public]
GRANT INSERT ON  [dbo].[brvAPTL_DistinctPO] TO [public]
GRANT DELETE ON  [dbo].[brvAPTL_DistinctPO] TO [public]
GRANT UPDATE ON  [dbo].[brvAPTL_DistinctPO] TO [public]
GRANT SELECT ON  [dbo].[brvAPTL_DistinctPO] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvAPTL_DistinctPO] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvAPTL_DistinctPO] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvAPTL_DistinctPO] TO [Viewpoint]
GO
