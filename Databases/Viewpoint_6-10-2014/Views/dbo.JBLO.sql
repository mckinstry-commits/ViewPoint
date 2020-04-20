SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JBLO] as select a.* From bJBLO a
GO
GRANT SELECT ON  [dbo].[JBLO] TO [public]
GRANT INSERT ON  [dbo].[JBLO] TO [public]
GRANT DELETE ON  [dbo].[JBLO] TO [public]
GRANT UPDATE ON  [dbo].[JBLO] TO [public]
GRANT SELECT ON  [dbo].[JBLO] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JBLO] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JBLO] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JBLO] TO [Viewpoint]
GO
