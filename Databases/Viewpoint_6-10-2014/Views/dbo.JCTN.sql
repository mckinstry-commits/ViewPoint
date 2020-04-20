SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCTN] as select a.* From bJCTN a
GO
GRANT SELECT ON  [dbo].[JCTN] TO [public]
GRANT INSERT ON  [dbo].[JCTN] TO [public]
GRANT DELETE ON  [dbo].[JCTN] TO [public]
GRANT UPDATE ON  [dbo].[JCTN] TO [public]
GRANT SELECT ON  [dbo].[JCTN] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCTN] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCTN] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCTN] TO [Viewpoint]
GO
