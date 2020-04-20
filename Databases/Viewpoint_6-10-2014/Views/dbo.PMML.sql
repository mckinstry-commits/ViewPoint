SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMML] as select a.* From bPMML a
GO
GRANT SELECT ON  [dbo].[PMML] TO [public]
GRANT INSERT ON  [dbo].[PMML] TO [public]
GRANT DELETE ON  [dbo].[PMML] TO [public]
GRANT UPDATE ON  [dbo].[PMML] TO [public]
GRANT SELECT ON  [dbo].[PMML] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMML] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMML] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMML] TO [Viewpoint]
GO
