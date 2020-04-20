SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udProjMWBE] as select a.* From budProjMWBE a
GO
GRANT SELECT ON  [dbo].[udProjMWBE] TO [public]
GRANT INSERT ON  [dbo].[udProjMWBE] TO [public]
GRANT DELETE ON  [dbo].[udProjMWBE] TO [public]
GRANT UPDATE ON  [dbo].[udProjMWBE] TO [public]
GRANT SELECT ON  [dbo].[udProjMWBE] TO [Viewpoint]
GRANT INSERT ON  [dbo].[udProjMWBE] TO [Viewpoint]
GRANT DELETE ON  [dbo].[udProjMWBE] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[udProjMWBE] TO [Viewpoint]
GO
