SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.pvPMMeetingType
AS
select distinct MeetingType from PMMM





GO
GRANT SELECT ON  [dbo].[pvPMMeetingType] TO [public]
GRANT INSERT ON  [dbo].[pvPMMeetingType] TO [public]
GRANT DELETE ON  [dbo].[pvPMMeetingType] TO [public]
GRANT UPDATE ON  [dbo].[pvPMMeetingType] TO [public]
GRANT SELECT ON  [dbo].[pvPMMeetingType] TO [VCSPortal]
GO
