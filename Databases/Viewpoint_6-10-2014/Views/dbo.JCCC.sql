SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCCC] as select a.* From bJCCC a
GO
GRANT SELECT ON  [dbo].[JCCC] TO [public]
GRANT INSERT ON  [dbo].[JCCC] TO [public]
GRANT DELETE ON  [dbo].[JCCC] TO [public]
GRANT UPDATE ON  [dbo].[JCCC] TO [public]
GRANT SELECT ON  [dbo].[JCCC] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCCC] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCCC] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCCC] TO [Viewpoint]
GO
