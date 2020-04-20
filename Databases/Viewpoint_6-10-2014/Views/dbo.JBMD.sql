SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JBMD] as select a.* From bJBMD a
GO
GRANT SELECT ON  [dbo].[JBMD] TO [public]
GRANT INSERT ON  [dbo].[JBMD] TO [public]
GRANT DELETE ON  [dbo].[JBMD] TO [public]
GRANT UPDATE ON  [dbo].[JBMD] TO [public]
GRANT SELECT ON  [dbo].[JBMD] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JBMD] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JBMD] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JBMD] TO [Viewpoint]
GO
