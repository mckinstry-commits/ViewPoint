SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCHC] as select a.* From bJCHC a
GO
GRANT SELECT ON  [dbo].[JCHC] TO [public]
GRANT INSERT ON  [dbo].[JCHC] TO [public]
GRANT DELETE ON  [dbo].[JCHC] TO [public]
GRANT UPDATE ON  [dbo].[JCHC] TO [public]
GRANT SELECT ON  [dbo].[JCHC] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCHC] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCHC] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCHC] TO [Viewpoint]
GO
