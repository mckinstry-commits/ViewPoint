SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JBIJ] as select a.* From bJBIJ a
GO
GRANT SELECT ON  [dbo].[JBIJ] TO [public]
GRANT INSERT ON  [dbo].[JBIJ] TO [public]
GRANT DELETE ON  [dbo].[JBIJ] TO [public]
GRANT UPDATE ON  [dbo].[JBIJ] TO [public]
GRANT SELECT ON  [dbo].[JBIJ] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JBIJ] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JBIJ] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JBIJ] TO [Viewpoint]
GO
