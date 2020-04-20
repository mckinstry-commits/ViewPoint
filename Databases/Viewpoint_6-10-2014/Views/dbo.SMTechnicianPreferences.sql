SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[SMTechnicianPreferences] as select a.* From vSMTechnicianPreferences a
GO
GRANT SELECT ON  [dbo].[SMTechnicianPreferences] TO [public]
GRANT INSERT ON  [dbo].[SMTechnicianPreferences] TO [public]
GRANT DELETE ON  [dbo].[SMTechnicianPreferences] TO [public]
GRANT UPDATE ON  [dbo].[SMTechnicianPreferences] TO [public]
GRANT SELECT ON  [dbo].[SMTechnicianPreferences] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMTechnicianPreferences] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMTechnicianPreferences] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMTechnicianPreferences] TO [Viewpoint]
GO
