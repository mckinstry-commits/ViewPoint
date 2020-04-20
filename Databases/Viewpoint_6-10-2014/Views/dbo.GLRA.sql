SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[GLRA] as select a.* From bGLRA a
GO
GRANT SELECT ON  [dbo].[GLRA] TO [public]
GRANT INSERT ON  [dbo].[GLRA] TO [public]
GRANT DELETE ON  [dbo].[GLRA] TO [public]
GRANT UPDATE ON  [dbo].[GLRA] TO [public]
GRANT SELECT ON  [dbo].[GLRA] TO [Viewpoint]
GRANT INSERT ON  [dbo].[GLRA] TO [Viewpoint]
GRANT DELETE ON  [dbo].[GLRA] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[GLRA] TO [Viewpoint]
GO
