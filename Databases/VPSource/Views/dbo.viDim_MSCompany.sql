SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE View [dbo].[viDim_MSCompany]  
  
/********************************************************  
Mike Brewer  
4/30/2007  
MS Cube   
Issue #127131    
********************************************************/  
  
AS  
  
  
select   
bMSCO.KeyID as 'MSCoID',  
MSCo,  
bHQCO.Name  as 'CompanyName',  
Cast(bMSCO.MSCo AS varchar) + '  ' + bHQCO.Name As CompanyAndName  
from bMSCO  
Join bHQCO  ON bMSCO.MSCo=bHQCO.HQCo  
Join vDDBICompanies on vDDBICompanies.Co=bMSCO.MSCo  
  
Union All  
  
Select   
0,  
Null,  
'Unassigned',  
'Unassigned'  
  
GO
GRANT SELECT ON  [dbo].[viDim_MSCompany] TO [public]
GRANT INSERT ON  [dbo].[viDim_MSCompany] TO [public]
GRANT DELETE ON  [dbo].[viDim_MSCompany] TO [public]
GRANT UPDATE ON  [dbo].[viDim_MSCompany] TO [public]
GO
