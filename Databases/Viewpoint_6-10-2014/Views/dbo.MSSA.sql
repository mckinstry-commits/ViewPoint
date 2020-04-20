SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSSA] as select a.* From bMSSA a
GO
GRANT SELECT ON  [dbo].[MSSA] TO [public]
GRANT INSERT ON  [dbo].[MSSA] TO [public]
GRANT DELETE ON  [dbo].[MSSA] TO [public]
GRANT UPDATE ON  [dbo].[MSSA] TO [public]
GRANT SELECT ON  [dbo].[MSSA] TO [Viewpoint]
GRANT INSERT ON  [dbo].[MSSA] TO [Viewpoint]
GRANT DELETE ON  [dbo].[MSSA] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[MSSA] TO [Viewpoint]
GO
