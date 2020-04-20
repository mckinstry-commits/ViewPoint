SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCAD] as select a.* From bJCAD a
GO
GRANT SELECT ON  [dbo].[JCAD] TO [public]
GRANT INSERT ON  [dbo].[JCAD] TO [public]
GRANT DELETE ON  [dbo].[JCAD] TO [public]
GRANT UPDATE ON  [dbo].[JCAD] TO [public]
GRANT SELECT ON  [dbo].[JCAD] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCAD] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCAD] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCAD] TO [Viewpoint]
GO
