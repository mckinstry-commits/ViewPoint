SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCSI] as select a.* From bJCSI a

GO
GRANT SELECT ON  [dbo].[JCSI] TO [public]
GRANT INSERT ON  [dbo].[JCSI] TO [public]
GRANT DELETE ON  [dbo].[JCSI] TO [public]
GRANT UPDATE ON  [dbo].[JCSI] TO [public]
GRANT SELECT ON  [dbo].[JCSI] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCSI] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCSI] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCSI] TO [Viewpoint]
GO
