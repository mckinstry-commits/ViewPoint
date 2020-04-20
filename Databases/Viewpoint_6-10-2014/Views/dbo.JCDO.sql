SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCDO] as select a.* From bJCDO a
GO
GRANT SELECT ON  [dbo].[JCDO] TO [public]
GRANT INSERT ON  [dbo].[JCDO] TO [public]
GRANT DELETE ON  [dbo].[JCDO] TO [public]
GRANT UPDATE ON  [dbo].[JCDO] TO [public]
GRANT SELECT ON  [dbo].[JCDO] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCDO] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCDO] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCDO] TO [Viewpoint]
GO
