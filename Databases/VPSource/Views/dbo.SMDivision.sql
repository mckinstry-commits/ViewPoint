
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[SMDivision] as select a.* From vSMDivision a
GO

GRANT SELECT ON  [dbo].[SMDivision] TO [public]
GRANT INSERT ON  [dbo].[SMDivision] TO [public]
GRANT DELETE ON  [dbo].[SMDivision] TO [public]
GRANT UPDATE ON  [dbo].[SMDivision] TO [public]
GO
