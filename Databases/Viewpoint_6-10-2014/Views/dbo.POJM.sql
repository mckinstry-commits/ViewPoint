SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[POJM] as select a.* From bPOJM a
GO
GRANT SELECT ON  [dbo].[POJM] TO [public]
GRANT INSERT ON  [dbo].[POJM] TO [public]
GRANT DELETE ON  [dbo].[POJM] TO [public]
GRANT UPDATE ON  [dbo].[POJM] TO [public]
GRANT SELECT ON  [dbo].[POJM] TO [Viewpoint]
GRANT INSERT ON  [dbo].[POJM] TO [Viewpoint]
GRANT DELETE ON  [dbo].[POJM] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[POJM] TO [Viewpoint]
GO
