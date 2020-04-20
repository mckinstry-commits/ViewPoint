SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.pvPMEMCoSelector
AS
select EMCO.EMCo, HQCO.Name 
from EMCO with (nolock) 
	Left Join HQCO with (nolock) on EMCO.EMCo=HQCO.HQCo 

union select -9 as 'EMCo', 'Not Applicable' as 'Name'


GO
GRANT SELECT ON  [dbo].[pvPMEMCoSelector] TO [public]
GRANT INSERT ON  [dbo].[pvPMEMCoSelector] TO [public]
GRANT DELETE ON  [dbo].[pvPMEMCoSelector] TO [public]
GRANT UPDATE ON  [dbo].[pvPMEMCoSelector] TO [public]
GRANT SELECT ON  [dbo].[pvPMEMCoSelector] TO [VCSPortal]
GRANT SELECT ON  [dbo].[pvPMEMCoSelector] TO [Viewpoint]
GRANT INSERT ON  [dbo].[pvPMEMCoSelector] TO [Viewpoint]
GRANT DELETE ON  [dbo].[pvPMEMCoSelector] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[pvPMEMCoSelector] TO [Viewpoint]
GO
