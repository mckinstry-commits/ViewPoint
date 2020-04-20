SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCPC] as select a.* From bJCPC a
GO
GRANT SELECT ON  [dbo].[JCPC] TO [public]
GRANT INSERT ON  [dbo].[JCPC] TO [public]
GRANT DELETE ON  [dbo].[JCPC] TO [public]
GRANT UPDATE ON  [dbo].[JCPC] TO [public]
GRANT SELECT ON  [dbo].[JCPC] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCPC] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCPC] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCPC] TO [Viewpoint]
GO
