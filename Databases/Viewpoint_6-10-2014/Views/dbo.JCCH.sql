SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCCH] as select a.* From bJCCH a
GO
GRANT SELECT ON  [dbo].[JCCH] TO [public]
GRANT INSERT ON  [dbo].[JCCH] TO [public]
GRANT DELETE ON  [dbo].[JCCH] TO [public]
GRANT UPDATE ON  [dbo].[JCCH] TO [public]
GRANT SELECT ON  [dbo].[JCCH] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCCH] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCCH] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCCH] TO [Viewpoint]
GO
