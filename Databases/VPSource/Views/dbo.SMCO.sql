
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[SMCO] as select a.* From vSMCO a
GO

GRANT SELECT ON  [dbo].[SMCO] TO [public]
GRANT INSERT ON  [dbo].[SMCO] TO [public]
GRANT DELETE ON  [dbo].[SMCO] TO [public]
GRANT UPDATE ON  [dbo].[SMCO] TO [public]
GO
