SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[INMO] as select a.* From bINMO a
GO
GRANT SELECT ON  [dbo].[INMO] TO [public]
GRANT INSERT ON  [dbo].[INMO] TO [public]
GRANT DELETE ON  [dbo].[INMO] TO [public]
GRANT UPDATE ON  [dbo].[INMO] TO [public]
GRANT SELECT ON  [dbo].[INMO] TO [Viewpoint]
GRANT INSERT ON  [dbo].[INMO] TO [Viewpoint]
GRANT DELETE ON  [dbo].[INMO] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[INMO] TO [Viewpoint]
GO
