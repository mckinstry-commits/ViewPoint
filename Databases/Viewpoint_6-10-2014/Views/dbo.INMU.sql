SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[INMU] as select a.* From bINMU a
GO
GRANT SELECT ON  [dbo].[INMU] TO [public]
GRANT INSERT ON  [dbo].[INMU] TO [public]
GRANT DELETE ON  [dbo].[INMU] TO [public]
GRANT UPDATE ON  [dbo].[INMU] TO [public]
GRANT SELECT ON  [dbo].[INMU] TO [Viewpoint]
GRANT INSERT ON  [dbo].[INMU] TO [Viewpoint]
GRANT DELETE ON  [dbo].[INMU] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[INMU] TO [Viewpoint]
GO
