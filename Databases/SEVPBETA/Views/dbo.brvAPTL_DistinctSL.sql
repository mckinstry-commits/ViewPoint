SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE    view [dbo].[brvAPTL_DistinctSL]
    
    /**************
     Created 1/25/05 Nadine F.
     Usage:  Used by the SL Drilldown report to display the AP Details for SL Items.  
             View returns one line per SL, SLItem
    
    **************/
    
    as
    
    select distinct APCo, SL, SLItem 
    from APTL 
    
   
   
   
  
 



GO
GRANT SELECT ON  [dbo].[brvAPTL_DistinctSL] TO [public]
GRANT INSERT ON  [dbo].[brvAPTL_DistinctSL] TO [public]
GRANT DELETE ON  [dbo].[brvAPTL_DistinctSL] TO [public]
GRANT UPDATE ON  [dbo].[brvAPTL_DistinctSL] TO [public]
GO
