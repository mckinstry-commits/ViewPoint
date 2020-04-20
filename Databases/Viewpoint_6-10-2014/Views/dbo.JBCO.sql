SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JBCO] as select a.* From bJBCO a
GO
GRANT SELECT ON  [dbo].[JBCO] TO [public]
GRANT INSERT ON  [dbo].[JBCO] TO [public]
GRANT DELETE ON  [dbo].[JBCO] TO [public]
GRANT UPDATE ON  [dbo].[JBCO] TO [public]
GRANT SELECT ON  [dbo].[JBCO] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JBCO] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JBCO] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JBCO] TO [Viewpoint]
GO
