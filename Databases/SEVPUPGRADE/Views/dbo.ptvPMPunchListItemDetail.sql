SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[ptvPMPunchListItemDetail]
AS

-- Punch List Item Detail
-- Filter in PT on PM CO, Project, and Punch List, and Punch List Item
Select  ItemLine, Description, DueDate, Item, PunchList,Project, PMCo
from   PMPD with (nolock)

GO
GRANT SELECT ON  [dbo].[ptvPMPunchListItemDetail] TO [public]
GRANT INSERT ON  [dbo].[ptvPMPunchListItemDetail] TO [public]
GRANT DELETE ON  [dbo].[ptvPMPunchListItemDetail] TO [public]
GRANT UPDATE ON  [dbo].[ptvPMPunchListItemDetail] TO [public]
GO
