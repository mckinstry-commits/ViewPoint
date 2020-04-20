SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCTI] as select a.* From bJCTI a
GO
GRANT SELECT ON  [dbo].[JCTI] TO [public]
GRANT INSERT ON  [dbo].[JCTI] TO [public]
GRANT DELETE ON  [dbo].[JCTI] TO [public]
GRANT UPDATE ON  [dbo].[JCTI] TO [public]
GRANT SELECT ON  [dbo].[JCTI] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCTI] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCTI] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCTI] TO [Viewpoint]
GO
