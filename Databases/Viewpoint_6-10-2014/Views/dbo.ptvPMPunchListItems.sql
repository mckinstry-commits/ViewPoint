SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[ptvPMPunchListItems]
AS

-- Punch List Items
-- Filter in PT on PM CO, Project, and Punch List

Select  Item, Description, DueDate, PunchList,Project, PMCo
from PMPI with (nolock)

GO
GRANT SELECT ON  [dbo].[ptvPMPunchListItems] TO [public]
GRANT INSERT ON  [dbo].[ptvPMPunchListItems] TO [public]
GRANT DELETE ON  [dbo].[ptvPMPunchListItems] TO [public]
GRANT UPDATE ON  [dbo].[ptvPMPunchListItems] TO [public]
GRANT SELECT ON  [dbo].[ptvPMPunchListItems] TO [Viewpoint]
GRANT INSERT ON  [dbo].[ptvPMPunchListItems] TO [Viewpoint]
GRANT DELETE ON  [dbo].[ptvPMPunchListItems] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[ptvPMPunchListItems] TO [Viewpoint]
GO
