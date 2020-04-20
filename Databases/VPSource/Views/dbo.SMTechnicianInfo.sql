SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE VIEW [dbo].[SMTechnicianInfo]
AS
SELECT     SMTechnicianID, SMTechnician.SMCo, SMTechnician.Technician, SMTechnician.PRCo, 
SMTechnician.Employee, SMTechnician.Rate, SMTechnician.INCo, SMTechnician.INLocation,
SMTechnician.UniqueAttchID, SMTechnician.Notes, 
PREHFullName.FullName, SMTechnicianID AS KeyID
FROM dbo.SMTechnician
LEFT JOIN dbo.PREHFullName ON SMTechnician.PRCo = PREHFullName.PRCo AND 
SMTechnician.Employee = PREHFullName.Employee





GO
GRANT SELECT ON  [dbo].[SMTechnicianInfo] TO [public]
GRANT INSERT ON  [dbo].[SMTechnicianInfo] TO [public]
GRANT DELETE ON  [dbo].[SMTechnicianInfo] TO [public]
GRANT UPDATE ON  [dbo].[SMTechnicianInfo] TO [public]
GO
