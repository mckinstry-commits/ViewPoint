SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.pvPMMinutesType
AS
SELECT     0 AS KeyField, 'Agenda' AS MinutesType
UNION
SELECT     1 AS KeyField, 'Minutes' AS MinutesType


GO
GRANT SELECT ON  [dbo].[pvPMMinutesType] TO [public]
GRANT INSERT ON  [dbo].[pvPMMinutesType] TO [public]
GRANT DELETE ON  [dbo].[pvPMMinutesType] TO [public]
GRANT UPDATE ON  [dbo].[pvPMMinutesType] TO [public]
GRANT SELECT ON  [dbo].[pvPMMinutesType] TO [VCSPortal]
GO
