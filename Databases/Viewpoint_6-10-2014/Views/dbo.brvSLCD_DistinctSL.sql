SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE   view [dbo].[brvSLCD_DistinctSL]
    
    /**************
     Created 1/25/05 Nadine F.
     Usage:  Used by the SL Drilldown report to display the Change Order Details for SL's.  
             View returns one line per SL, SL Item
    
    **************/
    
    as
    
    select distinct SLCo, SL, SLItem
    from SLCD
    
   
   
  
 



GO
GRANT SELECT ON  [dbo].[brvSLCD_DistinctSL] TO [public]
GRANT INSERT ON  [dbo].[brvSLCD_DistinctSL] TO [public]
GRANT DELETE ON  [dbo].[brvSLCD_DistinctSL] TO [public]
GRANT UPDATE ON  [dbo].[brvSLCD_DistinctSL] TO [public]
GRANT SELECT ON  [dbo].[brvSLCD_DistinctSL] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvSLCD_DistinctSL] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvSLCD_DistinctSL] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvSLCD_DistinctSL] TO [Viewpoint]
GO
