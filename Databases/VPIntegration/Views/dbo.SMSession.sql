SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE VIEW [dbo].[SMSession]
AS
SELECT a.* FROM dbo.vSMSession a






GO
GRANT SELECT ON  [dbo].[SMSession] TO [public]
GRANT INSERT ON  [dbo].[SMSession] TO [public]
GRANT DELETE ON  [dbo].[SMSession] TO [public]
GRANT UPDATE ON  [dbo].[SMSession] TO [public]
GO
