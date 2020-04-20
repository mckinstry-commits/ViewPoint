SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO









CREATE VIEW [dbo].[SMDivision]
AS
SELECT a.* FROM dbo.vSMDivision a









GO
GRANT SELECT ON  [dbo].[SMDivision] TO [public]
GRANT INSERT ON  [dbo].[SMDivision] TO [public]
GRANT DELETE ON  [dbo].[SMDivision] TO [public]
GRANT UPDATE ON  [dbo].[SMDivision] TO [public]
GO
