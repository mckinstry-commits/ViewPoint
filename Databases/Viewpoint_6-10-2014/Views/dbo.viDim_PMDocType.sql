SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE view [dbo].[viDim_PMDocType]

as 


with PMDocType
(DocType,
 Description
)
as
(
select DocType
	,Description
	
from bPMDT

union all

select Top 1 
'Transmital'/*Don't change spelling referenced in viFact_PMBallinCourt*/
,'Transmittal'

from bPMDT
)
Select DocType, Description,
Row_Number() Over (Order by PMDocType.DocType) as DocTypeID
from PMDocType

GO
GRANT SELECT ON  [dbo].[viDim_PMDocType] TO [public]
GRANT INSERT ON  [dbo].[viDim_PMDocType] TO [public]
GRANT DELETE ON  [dbo].[viDim_PMDocType] TO [public]
GRANT UPDATE ON  [dbo].[viDim_PMDocType] TO [public]
GRANT SELECT ON  [dbo].[viDim_PMDocType] TO [Viewpoint]
GRANT INSERT ON  [dbo].[viDim_PMDocType] TO [Viewpoint]
GRANT DELETE ON  [dbo].[viDim_PMDocType] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[viDim_PMDocType] TO [Viewpoint]
GO
