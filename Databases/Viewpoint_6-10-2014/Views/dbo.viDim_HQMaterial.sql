SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE View [dbo].[viDim_HQMaterial]    
  
/********************************************************    
Mike Brewer    
4/30/2007    
MS Cube     
Issue #127131      
********************************************************/    
    
AS    
    

select 
bHQMT.KeyID as 'MaterialID',
bHQMT.Material as 'Material',
bHQMT.Description as 'MaterialDescrip',
isnull(bHQMC.KeyID,0) as 'MaterialCategoryID',
case when bHQMC.KeyID is not null then bHQMC.Description else 'Unassigned' end as 'MaterialCategoryDescrip'
from bHQMT --Material
left join bHQMC --MaterialGroup
     on  bHQMT.MatlGroup = bHQMC.MatlGroup
     and bHQMT.Category = bHQMC.Category
Where bHQMT.Type='S'

union all

select
0 as 'MaterialID',
null as 'Material',
'Unassigned' as 'MaterialDescrip',
0 as 'MaterialCategoryID',
'Unassigned' as 'MaterialCategoryDescrip'






GO
GRANT SELECT ON  [dbo].[viDim_HQMaterial] TO [public]
GRANT INSERT ON  [dbo].[viDim_HQMaterial] TO [public]
GRANT DELETE ON  [dbo].[viDim_HQMaterial] TO [public]
GRANT UPDATE ON  [dbo].[viDim_HQMaterial] TO [public]
GRANT SELECT ON  [dbo].[viDim_HQMaterial] TO [Viewpoint]
GRANT INSERT ON  [dbo].[viDim_HQMaterial] TO [Viewpoint]
GRANT DELETE ON  [dbo].[viDim_HQMaterial] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[viDim_HQMaterial] TO [Viewpoint]
GO
