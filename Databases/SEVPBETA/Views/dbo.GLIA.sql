SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[GLIA] as select a.* From bGLIA a

GO
GRANT SELECT ON  [dbo].[GLIA] TO [public]
GRANT INSERT ON  [dbo].[GLIA] TO [public]
GRANT DELETE ON  [dbo].[GLIA] TO [public]
GRANT UPDATE ON  [dbo].[GLIA] TO [public]
GO
