SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  view [dbo].[DDUL] as select * from vDDUL

GO
GRANT SELECT ON  [dbo].[DDUL] TO [public]
GRANT INSERT ON  [dbo].[DDUL] TO [public]
GRANT DELETE ON  [dbo].[DDUL] TO [public]
GRANT UPDATE ON  [dbo].[DDUL] TO [public]
GRANT SELECT ON  [dbo].[DDUL] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDUL] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDUL] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDUL] TO [Viewpoint]
GO
