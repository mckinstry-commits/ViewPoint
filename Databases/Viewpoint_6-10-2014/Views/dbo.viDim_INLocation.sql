SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE View [dbo].[viDim_INLocation]        
        
/********************************************************        
Mike Brewer        
4/30/2007        
MS Cube         
Issue #127131          
********************************************************/        
        
AS        
        
select       
bINLM.KeyID as 'LocID',        
bINLM.Loc as 'Location',        
bINLM.Description as 'LocationDescrip', 
bINLG.KeyID as 'LocationGroupID',       
bINLG.LocGroup as 'LocationGroup',        
bINLG.Description as 'LocationGroupDescrp'        
from bINLM         
join bINLG         
 on bINLM.INCo = bINLG.INCo        
 and bINLM.LocGroup = bINLG.LocGroup        
join vDDBICompanies ON vDDBICompanies.Co = bINLM.INCo    
      
      
UNION ALL       
      
-- Unassigned record      
SELECT       
0,      
null,      
'Unassigned', 
null,     
null,      
'Unassigned'    
    
    
    
    
    

GO
GRANT SELECT ON  [dbo].[viDim_INLocation] TO [public]
GRANT INSERT ON  [dbo].[viDim_INLocation] TO [public]
GRANT DELETE ON  [dbo].[viDim_INLocation] TO [public]
GRANT UPDATE ON  [dbo].[viDim_INLocation] TO [public]
GRANT SELECT ON  [dbo].[viDim_INLocation] TO [Viewpoint]
GRANT INSERT ON  [dbo].[viDim_INLocation] TO [Viewpoint]
GRANT DELETE ON  [dbo].[viDim_INLocation] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[viDim_INLocation] TO [Viewpoint]
GO
