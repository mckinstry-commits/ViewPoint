SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[INLO] as select a.* From bINLO a
GO
GRANT SELECT ON  [dbo].[INLO] TO [public]
GRANT INSERT ON  [dbo].[INLO] TO [public]
GRANT DELETE ON  [dbo].[INLO] TO [public]
GRANT UPDATE ON  [dbo].[INLO] TO [public]
GRANT SELECT ON  [dbo].[INLO] TO [Viewpoint]
GRANT INSERT ON  [dbo].[INLO] TO [Viewpoint]
GRANT DELETE ON  [dbo].[INLO] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[INLO] TO [Viewpoint]
GO
