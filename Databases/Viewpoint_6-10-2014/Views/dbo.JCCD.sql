SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCCD] as select a.* From bJCCD a
GO
GRANT SELECT ON  [dbo].[JCCD] TO [public]
GRANT INSERT ON  [dbo].[JCCD] TO [public]
GRANT DELETE ON  [dbo].[JCCD] TO [public]
GRANT UPDATE ON  [dbo].[JCCD] TO [public]
GRANT SELECT ON  [dbo].[JCCD] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCCD] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCCD] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCCD] TO [Viewpoint]
GO
