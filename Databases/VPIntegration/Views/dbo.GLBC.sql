SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[GLBC] as select a.* From bGLBC a

GO
GRANT SELECT ON  [dbo].[GLBC] TO [public]
GRANT INSERT ON  [dbo].[GLBC] TO [public]
GRANT DELETE ON  [dbo].[GLBC] TO [public]
GRANT UPDATE ON  [dbo].[GLBC] TO [public]
GO
