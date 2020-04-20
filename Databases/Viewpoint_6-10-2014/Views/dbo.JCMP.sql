SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCMP] as select a.* From bJCMP a
GO
GRANT SELECT ON  [dbo].[JCMP] TO [public]
GRANT INSERT ON  [dbo].[JCMP] TO [public]
GRANT DELETE ON  [dbo].[JCMP] TO [public]
GRANT UPDATE ON  [dbo].[JCMP] TO [public]
GRANT SELECT ON  [dbo].[JCMP] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCMP] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCMP] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCMP] TO [Viewpoint]
GO
