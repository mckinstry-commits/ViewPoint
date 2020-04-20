SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JBLC] as select a.* From bJBLC a
GO
GRANT SELECT ON  [dbo].[JBLC] TO [public]
GRANT INSERT ON  [dbo].[JBLC] TO [public]
GRANT DELETE ON  [dbo].[JBLC] TO [public]
GRANT UPDATE ON  [dbo].[JBLC] TO [public]
GRANT SELECT ON  [dbo].[JBLC] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JBLC] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JBLC] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JBLC] TO [Viewpoint]
GO
