SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[viFact_EMMeterReadings] AS

/**************************************************
 * ALTERd: MB 2009-07-17 08:18:33.390
 * Modified:      
 * Usage:  Fact View for EM Meter Reading Data
 *		   for use in SSAS Cubes. 
 *
 **************************************************/

select  
bEMCO.KeyID as 'EMCoID',
bEMEM.KeyID as 'EquipmentID',
bEMCM.KeyID as 'CategoryKeyID',
bEMDM.KeyID as 'DepartmentKeyID',
datediff(dd, '1/1/1950',bEMMR.ReadingDate) as 'ReadingDateID',
isnull(Cast(cast(bEMCO.GLCo as varchar(3))
+cast(Datediff(dd,'1/1/1950',cast(cast(DATEPART(yy,bEMMR.ReadingDate) as varchar) 
+ '-'+ DATENAME(m, bEMMR.ReadingDate) +'-01' as datetime)) as varchar(10)) as int),0) as FiscalMthID,
bEMMR.Hours as 'Hours',
bEMMR.Miles as 'Miles'
from 
bEMMR
left join bEMEM
	on bEMEM.EMCo = bEMMR.EMCo
	and bEMEM.Equipment  = bEMMR.Equipment
left join bEMCM
      on bEMEM.EMCo=bEMCM.EMCo 
      AND bEMEM.Category=bEMCM.Category 
left join bEMDM 
      on bEMEM.EMCo=bEMDM.EMCo 
      AND bEMEM.Department=bEMDM.Department
left join bEMCO
	on bEMCO.EMCo = bEMEM.EMCo
Inner Join vDDBICompanies on vDDBICompanies.Co=bEMMR.EMCo

GO
GRANT SELECT ON  [dbo].[viFact_EMMeterReadings] TO [public]
GRANT INSERT ON  [dbo].[viFact_EMMeterReadings] TO [public]
GRANT DELETE ON  [dbo].[viFact_EMMeterReadings] TO [public]
GRANT UPDATE ON  [dbo].[viFact_EMMeterReadings] TO [public]
GO
