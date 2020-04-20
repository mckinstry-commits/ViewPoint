SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[ptvPMPunchList]
AS

-- Punch List Header
-- Filter in PT on PM CO and Project

Select PunchList, Description, PunchListDate, Project, PMCo
 from PMPU with (nolock)

GO
GRANT SELECT ON  [dbo].[ptvPMPunchList] TO [public]
GRANT INSERT ON  [dbo].[ptvPMPunchList] TO [public]
GRANT DELETE ON  [dbo].[ptvPMPunchList] TO [public]
GRANT UPDATE ON  [dbo].[ptvPMPunchList] TO [public]
GO
