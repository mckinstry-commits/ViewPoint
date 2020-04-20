SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMCO] as select a.* From bEMCO a
GO
GRANT SELECT ON  [dbo].[EMCO] TO [public]
GRANT INSERT ON  [dbo].[EMCO] TO [public]
GRANT DELETE ON  [dbo].[EMCO] TO [public]
GRANT UPDATE ON  [dbo].[EMCO] TO [public]
GO
