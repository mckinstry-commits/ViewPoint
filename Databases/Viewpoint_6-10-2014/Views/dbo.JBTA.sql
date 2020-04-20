SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JBTA] as select a.* From bJBTA a
GO
GRANT SELECT ON  [dbo].[JBTA] TO [public]
GRANT INSERT ON  [dbo].[JBTA] TO [public]
GRANT DELETE ON  [dbo].[JBTA] TO [public]
GRANT UPDATE ON  [dbo].[JBTA] TO [public]
GRANT SELECT ON  [dbo].[JBTA] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JBTA] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JBTA] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JBTA] TO [Viewpoint]
GO
