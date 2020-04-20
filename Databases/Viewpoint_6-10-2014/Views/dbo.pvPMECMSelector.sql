SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.pvPMECMSelector
AS
SELECT     'E' AS KeyField, 'Each' AS 'ECMDescription'
UNION
SELECT     'C' AS KeyField, 'Hundred' AS 'ECMDescription'
UNION
SELECT     'M' AS KeyField, 'Thousand' AS 'ECMDescription'

GO
GRANT SELECT ON  [dbo].[pvPMECMSelector] TO [public]
GRANT INSERT ON  [dbo].[pvPMECMSelector] TO [public]
GRANT DELETE ON  [dbo].[pvPMECMSelector] TO [public]
GRANT UPDATE ON  [dbo].[pvPMECMSelector] TO [public]
GRANT SELECT ON  [dbo].[pvPMECMSelector] TO [VCSPortal]
GRANT SELECT ON  [dbo].[pvPMECMSelector] TO [Viewpoint]
GRANT INSERT ON  [dbo].[pvPMECMSelector] TO [Viewpoint]
GRANT DELETE ON  [dbo].[pvPMECMSelector] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[pvPMECMSelector] TO [Viewpoint]
GO
