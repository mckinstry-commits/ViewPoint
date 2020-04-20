SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JBTS] as select a.* From bJBTS a
GO
GRANT SELECT ON  [dbo].[JBTS] TO [public]
GRANT INSERT ON  [dbo].[JBTS] TO [public]
GRANT DELETE ON  [dbo].[JBTS] TO [public]
GRANT UPDATE ON  [dbo].[JBTS] TO [public]
GRANT SELECT ON  [dbo].[JBTS] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JBTS] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JBTS] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JBTS] TO [Viewpoint]
GO
