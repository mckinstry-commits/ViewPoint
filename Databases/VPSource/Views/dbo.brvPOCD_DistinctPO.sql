SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    view [dbo].[brvPOCD_DistinctPO]
    
    /**************
     Created 1/25/05 Nadine F.
     Usage:  Used by the PO Drilldown report to display the AP Details for PO Items.  
             View returns one line per PO, POItem
    
    **************/
    
    as
    
    select distinct POCo, PO, POItem 
    from POCD

GO
GRANT SELECT ON  [dbo].[brvPOCD_DistinctPO] TO [public]
GRANT INSERT ON  [dbo].[brvPOCD_DistinctPO] TO [public]
GRANT DELETE ON  [dbo].[brvPOCD_DistinctPO] TO [public]
GRANT UPDATE ON  [dbo].[brvPOCD_DistinctPO] TO [public]
GO
