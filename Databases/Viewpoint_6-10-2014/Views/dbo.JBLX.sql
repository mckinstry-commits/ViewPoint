SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JBLX] as select a.* From bJBLX a
GO
GRANT SELECT ON  [dbo].[JBLX] TO [public]
GRANT INSERT ON  [dbo].[JBLX] TO [public]
GRANT DELETE ON  [dbo].[JBLX] TO [public]
GRANT UPDATE ON  [dbo].[JBLX] TO [public]
GRANT SELECT ON  [dbo].[JBLX] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JBLX] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JBLX] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JBLX] TO [Viewpoint]
GO
