SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[ARMT] as select a.* From bARMT a
GO
GRANT SELECT ON  [dbo].[ARMT] TO [public]
GRANT INSERT ON  [dbo].[ARMT] TO [public]
GRANT DELETE ON  [dbo].[ARMT] TO [public]
GRANT UPDATE ON  [dbo].[ARMT] TO [public]
GRANT SELECT ON  [dbo].[ARMT] TO [Viewpoint]
GRANT INSERT ON  [dbo].[ARMT] TO [Viewpoint]
GRANT DELETE ON  [dbo].[ARMT] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[ARMT] TO [Viewpoint]
GO
