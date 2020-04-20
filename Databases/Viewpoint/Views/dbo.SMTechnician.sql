SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO










CREATE VIEW [dbo].[SMTechnician]
AS
SELECT a.* FROM dbo.vSMTechnician a












GO
GRANT SELECT ON  [dbo].[SMTechnician] TO [public]
GRANT INSERT ON  [dbo].[SMTechnician] TO [public]
GRANT DELETE ON  [dbo].[SMTechnician] TO [public]
GRANT UPDATE ON  [dbo].[SMTechnician] TO [public]
GO
