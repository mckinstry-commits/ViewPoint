SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[GLFP] as select a.* From bGLFP a
GO
GRANT SELECT ON  [dbo].[GLFP] TO [public]
GRANT INSERT ON  [dbo].[GLFP] TO [public]
GRANT DELETE ON  [dbo].[GLFP] TO [public]
GRANT UPDATE ON  [dbo].[GLFP] TO [public]
GRANT SELECT ON  [dbo].[GLFP] TO [Viewpoint]
GRANT INSERT ON  [dbo].[GLFP] TO [Viewpoint]
GRANT DELETE ON  [dbo].[GLFP] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[GLFP] TO [Viewpoint]
GO
