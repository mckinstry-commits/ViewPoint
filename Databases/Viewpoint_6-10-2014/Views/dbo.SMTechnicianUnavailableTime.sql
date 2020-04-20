SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMTechnicianUnavailableTime]
AS
SELECT a.* FROM dbo.vSMTechnicianUnavailableTime a



GO
GRANT SELECT ON  [dbo].[SMTechnicianUnavailableTime] TO [public]
GRANT INSERT ON  [dbo].[SMTechnicianUnavailableTime] TO [public]
GRANT DELETE ON  [dbo].[SMTechnicianUnavailableTime] TO [public]
GRANT UPDATE ON  [dbo].[SMTechnicianUnavailableTime] TO [public]
GRANT SELECT ON  [dbo].[SMTechnicianUnavailableTime] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMTechnicianUnavailableTime] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMTechnicianUnavailableTime] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMTechnicianUnavailableTime] TO [Viewpoint]
GO
