SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[SLCO] as select a.* From bSLCO a
GO
GRANT SELECT ON  [dbo].[SLCO] TO [public]
GRANT INSERT ON  [dbo].[SLCO] TO [public]
GRANT DELETE ON  [dbo].[SLCO] TO [public]
GRANT UPDATE ON  [dbo].[SLCO] TO [public]
GRANT SELECT ON  [dbo].[SLCO] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SLCO] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SLCO] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SLCO] TO [Viewpoint]
GO
