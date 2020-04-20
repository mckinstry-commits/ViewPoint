SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[CMCO] as select a.* From bCMCO a

GO
GRANT SELECT ON  [dbo].[CMCO] TO [public]
GRANT INSERT ON  [dbo].[CMCO] TO [public]
GRANT DELETE ON  [dbo].[CMCO] TO [public]
GRANT UPDATE ON  [dbo].[CMCO] TO [public]
GO
