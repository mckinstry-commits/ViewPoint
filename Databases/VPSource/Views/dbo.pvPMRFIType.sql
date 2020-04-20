SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.pvPMRFIType
AS
select Distinct r.RFIType, d.Description
from PMRI r with (nolock)
Left Join PMDT d with (nolock) on r.RFIType = d.DocType



GO
GRANT SELECT ON  [dbo].[pvPMRFIType] TO [public]
GRANT INSERT ON  [dbo].[pvPMRFIType] TO [public]
GRANT DELETE ON  [dbo].[pvPMRFIType] TO [public]
GRANT UPDATE ON  [dbo].[pvPMRFIType] TO [public]
GRANT SELECT ON  [dbo].[pvPMRFIType] TO [VCSPortal]
GO
