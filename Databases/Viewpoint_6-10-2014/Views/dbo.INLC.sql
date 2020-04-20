SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[INLC] as select a.* From bINLC a
GO
GRANT SELECT ON  [dbo].[INLC] TO [public]
GRANT INSERT ON  [dbo].[INLC] TO [public]
GRANT DELETE ON  [dbo].[INLC] TO [public]
GRANT UPDATE ON  [dbo].[INLC] TO [public]
GRANT SELECT ON  [dbo].[INLC] TO [Viewpoint]
GRANT INSERT ON  [dbo].[INLC] TO [Viewpoint]
GRANT DELETE ON  [dbo].[INLC] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[INLC] TO [Viewpoint]
GO
