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
GRANT SELECT ON  [dbo].[SMCO] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMCO] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMCO] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMCO] TO [Viewpoint]
GO
