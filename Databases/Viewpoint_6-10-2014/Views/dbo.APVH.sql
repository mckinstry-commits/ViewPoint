SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APVH] as select a.* From bAPVH a
GO
GRANT SELECT ON  [dbo].[APVH] TO [public]
GRANT INSERT ON  [dbo].[APVH] TO [public]
GRANT DELETE ON  [dbo].[APVH] TO [public]
GRANT UPDATE ON  [dbo].[APVH] TO [public]
GRANT SELECT ON  [dbo].[APVH] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APVH] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APVH] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APVH] TO [Viewpoint]
GO
