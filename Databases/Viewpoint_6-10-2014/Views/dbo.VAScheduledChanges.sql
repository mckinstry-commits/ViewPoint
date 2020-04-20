SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.VAScheduledChanges
AS
SELECT     dbo.vVAScheduledChanges.*
FROM         dbo.vVAScheduledChanges

GO
GRANT SELECT ON  [dbo].[VAScheduledChanges] TO [public]
GRANT INSERT ON  [dbo].[VAScheduledChanges] TO [public]
GRANT DELETE ON  [dbo].[VAScheduledChanges] TO [public]
GRANT UPDATE ON  [dbo].[VAScheduledChanges] TO [public]
GRANT SELECT ON  [dbo].[VAScheduledChanges] TO [Viewpoint]
GRANT INSERT ON  [dbo].[VAScheduledChanges] TO [Viewpoint]
GRANT DELETE ON  [dbo].[VAScheduledChanges] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[VAScheduledChanges] TO [Viewpoint]
GO
