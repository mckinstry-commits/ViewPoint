SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQCP] as select a.* From bHQCP a
GO
GRANT SELECT ON  [dbo].[HQCP] TO [public]
GRANT INSERT ON  [dbo].[HQCP] TO [public]
GRANT DELETE ON  [dbo].[HQCP] TO [public]
GRANT UPDATE ON  [dbo].[HQCP] TO [public]
GRANT SELECT ON  [dbo].[HQCP] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HQCP] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HQCP] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HQCP] TO [Viewpoint]
GO
