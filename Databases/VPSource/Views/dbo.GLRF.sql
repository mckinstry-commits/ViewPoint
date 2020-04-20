SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[GLRF] as select a.* From bGLRF a

GO
GRANT SELECT ON  [dbo].[GLRF] TO [public]
GRANT INSERT ON  [dbo].[GLRF] TO [public]
GRANT DELETE ON  [dbo].[GLRF] TO [public]
GRANT UPDATE ON  [dbo].[GLRF] TO [public]
GO
