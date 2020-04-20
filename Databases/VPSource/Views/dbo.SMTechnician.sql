
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[SMTechnician] as select a.* From vSMTechnician a
GO

GRANT SELECT ON  [dbo].[SMTechnician] TO [public]
GRANT INSERT ON  [dbo].[SMTechnician] TO [public]
GRANT DELETE ON  [dbo].[SMTechnician] TO [public]
GRANT UPDATE ON  [dbo].[SMTechnician] TO [public]
GO
