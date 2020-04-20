SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JBBE] as select a.* From bJBBE a
GO
GRANT SELECT ON  [dbo].[JBBE] TO [public]
GRANT INSERT ON  [dbo].[JBBE] TO [public]
GRANT DELETE ON  [dbo].[JBBE] TO [public]
GRANT UPDATE ON  [dbo].[JBBE] TO [public]
GRANT SELECT ON  [dbo].[JBBE] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JBBE] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JBBE] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JBBE] TO [Viewpoint]
GO
