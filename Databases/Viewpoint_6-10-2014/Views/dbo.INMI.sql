SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[INMI] as select a.* From bINMI a
GO
GRANT SELECT ON  [dbo].[INMI] TO [public]
GRANT INSERT ON  [dbo].[INMI] TO [public]
GRANT DELETE ON  [dbo].[INMI] TO [public]
GRANT UPDATE ON  [dbo].[INMI] TO [public]
GRANT SELECT ON  [dbo].[INMI] TO [Viewpoint]
GRANT INSERT ON  [dbo].[INMI] TO [Viewpoint]
GRANT DELETE ON  [dbo].[INMI] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[INMI] TO [Viewpoint]
GO
