SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








CREATE VIEW [dbo].[SMTechnicianPreferences]
AS
SELECT a.* FROM dbo.vSMTechnicianPreferences a








GO
GRANT SELECT ON  [dbo].[SMTechnicianPreferences] TO [public]
GRANT INSERT ON  [dbo].[SMTechnicianPreferences] TO [public]
GRANT DELETE ON  [dbo].[SMTechnicianPreferences] TO [public]
GRANT UPDATE ON  [dbo].[SMTechnicianPreferences] TO [public]
GO
