SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSHR] as select a.* From bMSHR a
GO
GRANT SELECT ON  [dbo].[MSHR] TO [public]
GRANT INSERT ON  [dbo].[MSHR] TO [public]
GRANT DELETE ON  [dbo].[MSHR] TO [public]
GRANT UPDATE ON  [dbo].[MSHR] TO [public]
GRANT SELECT ON  [dbo].[MSHR] TO [Viewpoint]
GRANT INSERT ON  [dbo].[MSHR] TO [Viewpoint]
GRANT DELETE ON  [dbo].[MSHR] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[MSHR] TO [Viewpoint]
GO
